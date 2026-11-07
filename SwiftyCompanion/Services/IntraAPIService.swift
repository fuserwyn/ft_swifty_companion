import Foundation
import os

struct AppError: LocalizedError, Equatable {
    let message: String
    var errorDescription: String? { message }
}

protocol StudentFetching: Sendable {
    func fetchStudent(login: String) async throws -> Student
}

/// Client for the 42 Intra API using the OAuth2 client-credentials flow.
/// The token is cached in memory, refreshed when expired, and the request
/// is retried once with a fresh token on HTTP 401.
actor IntraAPIService: StudentFetching {
    private static let apiBase = URL(string: "https://api.intra.42.fr")!
    private static let tokenSafetyMargin: TimeInterval = 30
    #if DEBUG
    /// Short TTL in debug builds so token refresh is easy to demonstrate.
    private static let debugTokenTTL: TimeInterval = 60
    #endif

    private let config: AppConfig
    private let session: URLSession
    private let log = Logger(subsystem: "fr.fortytwo.swiftycompanion", category: "IntraAPI")

    private var accessToken: String?
    private var tokenExpiresAt: Date?

    init(config: AppConfig = .shared, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func fetchStudent(login: String) async throws -> Student {
        guard config.isConfigured else {
            throw AppError(message: "Missing INTRA_UID or INTRA_SECRET in .env file.")
        }

        let normalized = login.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { throw AppError(message: "Please enter a login.") }
        guard normalized.range(of: "^[a-z0-9_-]+$", options: .regularExpression) != nil else {
            throw AppError(message: "Login can only contain letters, digits, '-' and '_'.")
        }

        let token = try await validToken()
        let (data, response) = try await getUser(normalized, token: token)

        if response.statusCode == 401 {
            // Token can be revoked before its expiration: force refresh once and retry.
            log.debug("401 received, refreshing token and retrying")
            invalidateToken()
            let fresh = try await validToken()
            let (retryData, retryResponse) = try await getUser(normalized, token: fresh)
            return try decodeStudent(retryData, response: retryResponse, login: normalized)
        }

        return try decodeStudent(data, response: response, login: normalized)
    }

    // MARK: - Users

    private func getUser(_ login: String, token: String) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: Self.apiBase.appendingPathComponent("v2/users/\(login)"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20
        log.debug("GET /v2/users/\(login, privacy: .public)")
        let result = try await perform(request, action: "requesting user data")
        log.debug("GET /v2/users/\(login, privacy: .public) -> \(result.1.statusCode)")
        return result
    }

    private func decodeStudent(_ data: Data, response: HTTPURLResponse, login: String) throws -> Student {
        switch response.statusCode {
        case 200..<300:
            do {
                return try JSONDecoder().decode(Student.self, from: data)
            } catch {
                throw AppError(message: "Could not read the 42 API response.")
            }
        case 404:
            throw AppError(message: "Login \"\(login)\" not found.")
        case 429:
            throw AppError(message: "Too many requests to the 42 API. Please wait a moment.")
        default:
            throw AppError(message: Self.httpErrorMessage(prefix: "42 API error", response: response))
        }
    }

    // MARK: - OAuth token

    private func validToken() async throws -> String {
        if let accessToken, let tokenExpiresAt, Date() < tokenExpiresAt {
            log.debug("Using cached OAuth token (expires at \(tokenExpiresAt, privacy: .public))")
            return accessToken
        }
        log.debug("Requesting new OAuth token")
        return try await requestNewToken()
    }

    private func invalidateToken() {
        accessToken = nil
        tokenExpiresAt = nil
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let expiresIn: Int
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
        }
    }

    private func requestNewToken() async throws -> String {
        var request = URLRequest(url: Self.apiBase.appendingPathComponent("oauth/token"))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var form = URLComponents()
        form.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: config.uid),
            URLQueryItem(name: "client_secret", value: config.secret),
        ]
        request.httpBody = form.percentEncodedQuery?.data(using: .utf8)
        request.timeoutInterval = 20

        let (data, response) = try await perform(request, action: "requesting access token")
        log.debug("POST /oauth/token -> \(response.statusCode)")

        guard (200..<300).contains(response.statusCode) else {
            if response.statusCode == 401 {
                throw AppError(message: "OAuth error: invalid INTRA_UID or INTRA_SECRET.")
            }
            throw AppError(message: Self.httpErrorMessage(prefix: "OAuth error", response: response))
        }
        guard let token = try? JSONDecoder().decode(TokenResponse.self, from: data),
              !token.accessToken.isEmpty, token.expiresIn > 0 else {
            throw AppError(message: "Received invalid OAuth token response.")
        }

        let serverTTL = TimeInterval(token.expiresIn)
        #if DEBUG
        let ttl = min(Self.debugTokenTTL, serverTTL)
        #else
        let ttl = max(1, serverTTL - Self.tokenSafetyMargin)
        #endif
        log.debug("OAuth expires_in=\(token.expiresIn)s, cached ttl=\(Int(ttl))s")

        accessToken = token.accessToken
        tokenExpiresAt = Date().addingTimeInterval(ttl)
        return token.accessToken
    }

    // MARK: - Helpers

    private func perform(_ request: URLRequest, action: String) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw AppError(message: "Unexpected response while \(action).")
            }
            return (data, http)
        } catch let error as AppError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw AppError(message: "No internet connection.")
        } catch {
            throw AppError(message: "Network error while \(action).")
        }
    }

    private static func httpErrorMessage(prefix: String, response: HTTPURLResponse) -> String {
        let reason = HTTPURLResponse.localizedString(forStatusCode: response.statusCode).capitalized
        return "\(prefix): \(response.statusCode) \(reason)"
    }
}

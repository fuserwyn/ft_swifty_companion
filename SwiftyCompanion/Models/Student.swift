import Foundation

struct Skill: Identifiable, Hashable {
    let id: Int
    let name: String
    let level: Double

    /// Skill levels are shown relative to the max level 20.
    var percent: Double { min(max(level / 20, 0), 1) * 100 }
}

struct Project: Identifiable, Hashable {
    enum Outcome { case passed, failed, inProgress(String) }

    let id: Int
    let name: String
    let status: String
    let finalMark: Int?
    let validated: Bool?

    var outcome: Outcome {
        switch validated {
        case true?: return .passed
        case false?: return .failed
        case nil: return .inProgress(status.replacingOccurrences(of: "_", with: " "))
        }
    }
}

struct Student: Hashable {
    let login: String
    let displayName: String
    let email: String
    let phone: String
    let imageURL: URL?
    let level: Double
    let location: String
    let wallet: Int
    let evaluationPoints: Int
    let skills: [Skill]
    let projects: [Project]
}

// MARK: - Decoding from 42 API JSON

extension Student: Decodable {
    private enum CodingKeys: String, CodingKey {
        case login, email, phone, image, location, wallet
        case displayName = "displayname"
        case correctionPoint = "correction_point"
        case cursusUsers = "cursus_users"
        case projectsUsers = "projects_users"
    }

    private struct ImageDTO: Decodable { let link: String? }

    private struct CursusUserDTO: Decodable {
        struct Cursus: Decodable { let kind: String? }
        struct SkillDTO: Decodable { let id: Int?; let name: String?; let level: Double? }
        let level: Double?
        let cursus: Cursus?
        let skills: [SkillDTO]?
    }

    private struct ProjectUserDTO: Decodable {
        struct ProjectInfo: Decodable { let name: String? }
        let id: Int?
        let status: String?
        let finalMark: Int?
        let validated: Bool?
        let project: ProjectInfo?

        enum CodingKeys: String, CodingKey {
            case id, status, project
            case finalMark = "final_mark"
            case validated = "validated?"
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        let cursusUsers = (try? c.decodeIfPresent([CursusUserDTO].self, forKey: .cursusUsers)) ?? []
        let mainCursus = cursusUsers.first { $0.cursus?.kind == "main" } ?? cursusUsers.first

        let skills = (mainCursus?.skills ?? []).enumerated().map { index, dto in
            Skill(id: dto.id ?? index, name: dto.name ?? "Unknown skill", level: dto.level ?? 0)
        }

        let projectsRaw = (try? c.decodeIfPresent([ProjectUserDTO].self, forKey: .projectsUsers)) ?? []
        let projects = projectsRaw.enumerated().map { index, dto in
            Project(
                id: dto.id ?? index,
                name: dto.project?.name ?? "Unknown project",
                status: dto.status ?? "unknown",
                finalMark: dto.finalMark,
                validated: dto.validated
            )
        }

        let login = (try? c.decodeIfPresent(String.self, forKey: .login)) ?? "unknown"
        let imageLink = (try? c.decodeIfPresent(ImageDTO.self, forKey: .image))??.link

        self.init(
            login: login,
            displayName: (try? c.decodeIfPresent(String.self, forKey: .displayName)) ?? login,
            email: (try? c.decodeIfPresent(String.self, forKey: .email)) ?? "-",
            phone: Self.nonEmpty((try? c.decodeIfPresent(String.self, forKey: .phone)) ?? nil) ?? "-",
            imageURL: imageLink.flatMap(URL.init(string:)),
            level: mainCursus?.level ?? 0,
            location: Self.nonEmpty((try? c.decodeIfPresent(String.self, forKey: .location)) ?? nil) ?? "Unavailable",
            wallet: (try? c.decodeIfPresent(Int.self, forKey: .wallet)) ?? 0,
            evaluationPoints: (try? c.decodeIfPresent(Int.self, forKey: .correctionPoint)) ?? 0,
            skills: skills,
            projects: projects
        )
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return value
    }
}

import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var login = ""
    @Published private(set) var isLoading = false
    @Published var errorText: String?
    @Published var path: [Student] = []

    private let api: StudentFetching
    private var searchTask: Task<Void, Never>?

    init(api: StudentFetching) {
        self.api = api
    }

    func search() {
        guard !isLoading else { return }
        isLoading = true
        errorText = nil

        let query = login
        searchTask = Task {
            defer { isLoading = false }
            do {
                let student = try await api.fetchStudent(login: query)
                path.append(student)
            } catch is CancellationError {
                // ignored
            } catch let error as AppError {
                errorText = error.message
            } catch {
                errorText = "Unexpected error. Please try again."
            }
        }
    }
}

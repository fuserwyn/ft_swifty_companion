import XCTest
@testable import SwiftyCompanion

final class StudentDecodingTests: XCTestCase {
    func testDecodesMainCursusSkillsAndProjects() throws {
        let json = """
        {
          "login": "jdoe",
          "displayname": "John Doe",
          "email": "jdoe@student.42.fr",
          "phone": "hidden",
          "image": { "link": "https://cdn.intra.42.fr/users/jdoe.jpg" },
          "location": null,
          "wallet": 42,
          "correction_point": 3,
          "cursus_users": [
            { "level": 1.5, "cursus": { "kind": "piscine" }, "skills": [] },
            { "level": 7.25, "cursus": { "kind": "main" },
              "skills": [ { "id": 1, "name": "Unix", "level": 10.0 } ] }
          ],
          "projects_users": [
            { "id": 10, "status": "finished", "final_mark": 100, "validated?": true,
              "project": { "name": "Libft" } },
            { "id": 11, "status": "finished", "final_mark": 0, "validated?": false,
              "project": { "name": "ft_printf" } },
            { "id": 12, "status": "in_progress", "final_mark": null, "validated?": null,
              "project": { "name": "minishell" } }
          ]
        }
        """.data(using: .utf8)!

        let student = try JSONDecoder().decode(Student.self, from: json)

        XCTAssertEqual(student.login, "jdoe")
        XCTAssertEqual(student.displayName, "John Doe")
        XCTAssertEqual(student.location, "Unavailable")
        XCTAssertEqual(student.wallet, 42)
        XCTAssertEqual(student.evaluationPoints, 3)
        XCTAssertEqual(student.level, 7.25)
        XCTAssertEqual(student.imageURL?.absoluteString, "https://cdn.intra.42.fr/users/jdoe.jpg")
        XCTAssertEqual(student.skills.count, 1)
        XCTAssertEqual(student.skills.first?.percent, 50)
        XCTAssertEqual(student.projects.map(\.validated), [true, false, nil])
        guard case .inProgress(let status) = student.projects[2].outcome else {
            return XCTFail("expected in-progress project")
        }
        XCTAssertEqual(status, "in progress")
    }

    func testMissingFieldsFallBackToDefaults() throws {
        let student = try JSONDecoder().decode(Student.self, from: Data("{}".utf8))
        XCTAssertEqual(student.login, "unknown")
        XCTAssertEqual(student.email, "-")
        XCTAssertEqual(student.phone, "-")
        XCTAssertNil(student.imageURL)
        XCTAssertTrue(student.skills.isEmpty)
        XCTAssertTrue(student.projects.isEmpty)
    }

    func testSkillPercentIsClamped() {
        XCTAssertEqual(Skill(id: 0, name: "x", level: 30).percent, 100)
        XCTAssertEqual(Skill(id: 0, name: "x", level: -1).percent, 0)
    }

    func testMissingConfigProducesError() async {
        let api = IntraAPIService(config: AppConfig(uid: "", secret: ""))
        do {
            _ = try await api.fetchStudent(login: "jdoe")
            XCTFail("expected error")
        } catch let error as AppError {
            XCTAssertTrue(error.message.contains("INTRA_UID"))
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testEmptyLoginProducesError() async {
        let api = IntraAPIService(config: AppConfig(uid: "a", secret: "b"))
        do {
            _ = try await api.fetchStudent(login: "   ")
            XCTFail("expected error")
        } catch let error as AppError {
            XCTAssertEqual(error.message, "Please enter a login.")
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }
}

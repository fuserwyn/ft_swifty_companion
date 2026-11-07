import SwiftUI

struct ProfileView: View {
    let student: Student

    @State private var projectFilter: ProjectFilter = .all

    enum ProjectFilter: String, CaseIterable, Identifiable {
        case all = "All", passed = "Passed", failed = "Failed", inProgress = "In progress"
        var id: String { rawValue }
    }

    private var filteredProjects: [Project] {
        student.projects.filter { project in
            switch (projectFilter, project.outcome) {
            case (.all, _), (.passed, .passed), (.failed, .failed), (.inProgress, .inProgress): return true
            default: return false
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CardView { ProfileHeader(student: student) }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    InfoCard(label: "Level", value: String(format: "%.2f", student.level), icon: "graduationcap.fill")
                    InfoCard(label: "Location", value: student.location, icon: "mappin.and.ellipse")
                    InfoCard(label: "Wallet", value: "\(student.wallet) ₳", icon: "creditcard.fill")
                    InfoCard(label: "Evaluation points", value: "\(student.evaluationPoints)", icon: "star.fill")
                }

                SectionTitle("Skills")
                CardView {
                    if student.skills.isEmpty {
                        Text("No skills found.").foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(spacing: 14) {
                            ForEach(student.skills) { SkillRow(skill: $0) }
                        }
                    }
                }

                SectionTitle("Projects")
                Picker("Filter", selection: $projectFilter) {
                    ForEach(ProjectFilter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                if filteredProjects.isEmpty {
                    Text("No projects found.").foregroundStyle(.secondary)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredProjects) { ProjectRow(project: $0) }
                    }
                }
            }
            .frame(maxWidth: 760)
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(student.login)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.title2.bold())
    }
}

#Preview {
    NavigationStack {
        ProfileView(student: .preview)
    }
}

extension Student {
    static let preview = Student(
        login: "jdoe",
        displayName: "John Doe",
        email: "jdoe@student.42.fr",
        phone: "hidden",
        imageURL: nil,
        level: 7.42,
        location: "e1r2p3",
        wallet: 120,
        evaluationPoints: 5,
        skills: [
            Skill(id: 1, name: "Algorithms & AI", level: 8.3),
            Skill(id: 2, name: "Unix", level: 5.1),
        ],
        projects: [
            Project(id: 1, name: "Libft", status: "finished", finalMark: 125, validated: true),
            Project(id: 2, name: "ft_printf", status: "finished", finalMark: 0, validated: false),
            Project(id: 3, name: "minishell", status: "in_progress", finalMark: nil, validated: nil),
        ]
    )
}

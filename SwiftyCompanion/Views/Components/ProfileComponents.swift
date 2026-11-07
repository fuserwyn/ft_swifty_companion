import SwiftUI

struct CardView<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            )
    }
}

struct ProfileHeader: View {
    let student: Student

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 16) { avatar; details }
            VStack(alignment: .leading, spacing: 12) { avatar; details }
        }
    }

    private var avatar: some View {
        AsyncImage(url: student.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .empty where student.imageURL != nil:
                ProgressView()
            default:
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 84, height: 84)
        .background(Color(.tertiarySystemFill))
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.accentColor.opacity(0.3), lineWidth: 2))
        .accessibilityLabel("Avatar of \(student.login)")
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(student.displayName).font(.title2.bold())
            Text(student.email).foregroundStyle(.secondary)
            Text("Mobile: \(student.phone)").foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Chip(icon: "person.text.rectangle", text: student.login)
                Chip(icon: "graduationcap", text: "Level \(String(format: "%.2f", student.level))")
            }
            .padding(.top, 6)
        }
        .font(.subheadline)
        .textSelection(.enabled)
    }
}

struct Chip: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.accentColor.opacity(0.12)))
            .foregroundStyle(Color.accentColor)
    }
}

struct InfoCard: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        CardView(padding: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Label(label, systemImage: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct SkillRow: View {
    let skill: Skill

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(skill.name)
                Spacer(minLength: 8)
                Text(String(format: "%.2f (%.1f%%)", skill.level, skill.percent))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.accentColor.opacity(0.15))
                    Capsule().fill(Color.accentColor)
                        .frame(width: geo.size.width * skill.percent / 100)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ProjectRow: View {
    let project: Project

    private var color: Color {
        switch project.outcome {
        case .passed: return .green
        case .failed: return .red
        case .inProgress: return .orange
        }
    }

    private var label: String {
        switch project.outcome {
        case .passed: return "passed"
        case .failed: return "failed"
        case .inProgress(let status): return status
        }
    }

    var body: some View {
        CardView(padding: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name).font(.body.weight(.semibold))
                    Text("Mark: \(project.finalMark.map(String.init) ?? "-")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(color.opacity(0.15)))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

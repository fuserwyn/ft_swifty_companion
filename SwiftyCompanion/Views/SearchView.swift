import SwiftUI

struct SearchView: View {
    @ObservedObject var model: SearchViewModel
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack(path: $model.path) {
            ScrollView {
                VStack(spacing: 20) {
                    Image("Logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                        .padding(.top, 20)
                        .accessibilityHidden(true)

                    CardView {
                        VStack(spacing: 16) {
                            Text("Search a 42 student by login")
                                .font(.headline)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                TextField("Login", text: $model.login)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .submitLabel(.search)
                                    .focused($fieldFocused)
                                    .onSubmit(search)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )

                            Button(action: search) {
                                HStack(spacing: 8) {
                                    if model.isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                    }
                                    Text(model.isLoading ? "Searching..." : "Search")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity, minHeight: 48)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.roundedRectangle(radius: 14))
                            .disabled(model.isLoading)

                            if let error = model.errorText {
                                Label(error, systemImage: "exclamationmark.triangle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                                    .transition(.opacity)
                            }
                        }
                    }
                }
                .frame(maxWidth: 560)
                .padding(16)
                .frame(maxWidth: .infinity)
                .animation(.default, value: model.errorText)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Student Profiler")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Student.self) { student in
                ProfileView(student: student)
            }
        }
    }

    private func search() {
        fieldFocused = false
        model.search()
    }
}

#Preview {
    SearchView(model: SearchViewModel(api: IntraAPIService()))
}

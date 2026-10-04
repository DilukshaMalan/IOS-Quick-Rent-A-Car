import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var passwordsMatch: Bool { password == confirmPassword }

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingL) {
                // MARK: - Header
                VStack(spacing: .spacingS) {
                    Text("Create Account")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.fallbackNavy)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Join QuickRentCar today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, .spacingL)

                // MARK: - Fields
                VStack(spacing: .spacingM) {
                    inputField("Full Name", text: $fullName, contentType: .name)
                    inputField("Email", text: $email, contentType: .emailAddress, keyboardType: .emailAddress)
                    inputField("Phone Number", text: $phoneNumber, contentType: .telephoneNumber, keyboardType: .phonePad)
                    secureField("Password", text: $password, contentType: .newPassword)
                    secureField("Confirm Password", text: $confirmPassword, contentType: .newPassword)

                    if !confirmPassword.isEmpty && !passwordsMatch {
                        Text("Passwords do not match")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Error
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // MARK: - Register Button
                Button {
                    Task {
                        await authViewModel.register(
                            email: email,
                            password: password,
                            fullName: fullName,
                            phoneNumber: phoneNumber
                        )
                    }
                } label: {
                    Group {
                        if authViewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                        }
                    }
                    .primaryButtonStyle()
                }
                .disabled(authViewModel.isLoading || !passwordsMatch)

                // MARK: - Back to Login
                Button("Already have an account? Sign In") { dismiss() }
                    .font(.subheadline)
                    .foregroundStyle(Color.fallbackBlue)

                Spacer()
            }
            .padding(.horizontal, .spacingL)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers
    @ViewBuilder
    private func inputField(
        _ placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        TextField(placeholder, text: text)
            .textContentType(contentType)
            .keyboardType(keyboardType)
            .autocapitalization(keyboardType == .emailAddress ? .none : .words)
            .padding()
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusS))
    }

    @ViewBuilder
    private func secureField(_ placeholder: String, text: Binding<String>, contentType: UITextContentType) -> some View {
        SecureField(placeholder, text: text)
            .textContentType(contentType)
            .padding()
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusS))
    }
}

#Preview {
    NavigationStack { RegisterView() }
        .environmentObject(AuthViewModel())
}

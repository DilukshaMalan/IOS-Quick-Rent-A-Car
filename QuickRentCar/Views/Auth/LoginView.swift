import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showForgotPassword = false

    /// Face ID quick-login is only shown when the user has previously enabled it.
    private var faceIDEnabled: Bool { BiometricAuthService.shared.isFaceIDEnabled }
    private var biometricName: String { BiometricAuthService.shared.biometricTypeName }

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                // MARK: - Header
                VStack(spacing: .spacingM) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.fallbackBlue)
                        .padding(.top, 60)

                    Text("QuickRentCar")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.fallbackNavy)

                    Text("Your journey starts here")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Fields
                VStack(spacing: .spacingM) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusS))

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusS))

                    Button("Forgot Password?") {
                        showForgotPassword = true
                    }
                    .font(.footnote)
                    .foregroundStyle(Color.fallbackBlue)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // MARK: - Error
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // MARK: - Sign In Button
                Button {
                    Task { await authViewModel.signIn(email: email, password: password) }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.fallbackBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        Text("Sign In")
                            .primaryButtonStyle()
                    }
                }
                .disabled(authViewModel.isLoading)

                // MARK: - Face ID Quick Login
                // Shown only when the user has previously enabled Face ID in Settings.
                // This skips the email/password fields entirely — it re-authenticates via
                // biometrics and then restores the existing Firebase session.
                if faceIDEnabled {
                    VStack(spacing: .spacingS) {
                        HStack {
                            Rectangle().frame(height: 1).foregroundStyle(Color.gray.opacity(0.3))
                            Text("or").font(.footnote).foregroundStyle(.secondary)
                            Rectangle().frame(height: 1).foregroundStyle(Color.gray.opacity(0.3))
                        }

                        Button {
                            Task { await authViewModel.signInWithBiometrics() }
                        } label: {
                            HStack(spacing: .spacingS) {
                                Image(systemName: biometricName == "Face ID" ? "faceid" : "touchid")
                                    .font(.title2)
                                Text("Sign in with \(biometricName)")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.fallbackBlue.opacity(0.1))
                            .foregroundStyle(Color.fallbackBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.fallbackBlue.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .disabled(authViewModel.isLoading)

                        Text("\(biometricName) replaces entering your password. Your account credentials stay on your device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // MARK: - Register
                HStack {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign Up") { showRegister = true }
                        .foregroundStyle(Color.fallbackBlue)
                        .fontWeight(.semibold)
                }
                .font(.subheadline)

                Spacer()
            }
            .padding(.horizontal, .spacingL)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showRegister) { RegisterView() }
        .sheet(isPresented: $showForgotPassword) { ForgotPasswordView() }
    }
}

#Preview {
    NavigationStack { LoginView() }
        .environmentObject(AuthViewModel())
}

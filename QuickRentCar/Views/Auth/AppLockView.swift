import SwiftUI

struct AppLockView: View {
    let onUnlock: () -> Void

    @State private var isAuthenticating = false
    @State private var errorMessage: String? = nil

    private let service = BiometricAuthService.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(spacing: .spacingXL) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.fallbackBlue.opacity(0.15))
                        .frame(width: 110, height: 110)
                    Image(systemName: "car.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.fallbackBlue)
                }

                VStack(spacing: .spacingS) {
                    Text("QuickRentCar")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Locked")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                VStack(spacing: .spacingM) {
                    Button {
                        Task { await authenticate() }
                    } label: {
                        HStack(spacing: .spacingM) {
                            if isAuthenticating {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: service.biometricType == .faceID ? "faceid" : "touchid")
                                    .font(.title2)
                            }
                            Text(isAuthenticating ? "Verifying…" : "Unlock with \(service.biometricTypeName)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.fallbackBlue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isAuthenticating)
                    .padding(.horizontal, .spacingL)

                    if let error = errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, .spacingL)
                    }
                }
                .padding(.bottom, .spacingXXL)
            }
        }
        .onAppear {
            Task { await authenticate() }
        }
    }

    private func authenticate() async {
        isAuthenticating = true
        errorMessage = nil

        let ok = await service.authenticate(reason: "Unlock QuickRentCar")

        isAuthenticating = false

        if ok {
            onUnlock()
        } else {
            errorMessage = "\(service.biometricTypeName) failed. Tap to try again."
        }
    }
}

#Preview {
    AppLockView(onUnlock: {})
}

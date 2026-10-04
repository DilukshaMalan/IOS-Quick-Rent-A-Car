import SwiftUI
import RealityKit
import ARKit

struct ARPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isPlaced = false
    @State private var selectedVehicle: Vehicle? = Vehicle.sampleVehicles.first

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - AR Scene
            ARViewContainer(modelName: selectedVehicle?.arModelURL ?? Constants.AR.defaultModelName)
                .ignoresSafeArea()

            // MARK: - Overlay UI
            VStack(spacing: .spacingM) {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }

                    Spacer()

                    Text("AR Preview")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .shadow(radius: 4)

                    Spacer()

                    Button {
                        // Reset AR scene
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                }
                .padding()

                Spacer()

                // Instructions
                if !isPlaced {
                    Text("Point camera at a flat surface to place your vehicle")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, .spacingL)
                        .padding(.vertical, .spacingS)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }

                // Bottom actions
                VStack(spacing: .spacingS) {
                    HStack(spacing: .spacingM) {
                        ARControlButton(icon: "arrow.left.arrow.right", label: "Rotate")
                        ARControlButton(icon: "arrow.up.left.and.arrow.down.right", label: "Resize")
                        ARControlButton(icon: "move.3d", label: "Move")
                    }

                    if let vehicle = selectedVehicle {
                        NavigationLink(destination: BookingView(vehicle: vehicle)) {
                            Text("Book This Vehicle")
                                .primaryButtonStyle()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusL))
                .padding()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - AR View Container
struct ARViewContainer: UIViewRepresentable {
    let modelName: String

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        arView.session.run(config)

        // Load USDZ model
        let modelURL = Bundle.main.url(forResource: modelName, withExtension: Constants.AR.modelExtension)
        if let url = modelURL,
           let modelEntity = try? ModelEntity.loadModel(named: modelName) {
            let anchor = AnchorEntity(plane: .horizontal)
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

// MARK: - Control Button
struct ARControlButton: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.fallbackBlue)
                .frame(width: 44, height: 44)
                .background(Color.fallbackBlue.opacity(0.1))
                .clipShape(Circle())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ARPreviewView()
}

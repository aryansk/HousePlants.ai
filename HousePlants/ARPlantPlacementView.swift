import SwiftUI
import RealityKit
import ARKit

// TODO: Full AR plant placement — Phase 2
//
// Plan:
//   1. Use ARView with ARWorldTrackingConfiguration (horizontal plane detection).
//   2. On tap, raycast against detected planes and place a ModelEntity at the hit point.
//   3. Replace the green-sphere placeholder with per-species USDZ models stored in Assets.xcassets
//      (or downloaded on demand) matched by plant.id.
//   4. Add coaching overlay (ARCoachingOverlayView) so the user knows to scan the floor first.
//   5. Minimum iOS 16; fall back gracefully on devices without LiDAR.
//
// Files to create: ARPlantSceneView.swift (UIViewRepresentable wrapping ARView)
//                  PlantARModels/ (USDZ assets folder)
//
// Related flag: AppConfig.features.arPlacement — keep false until real plant models ship.

/// Gate: only reachable when ProManager.shared.isPro == true (enforced in PlantDetailView).
struct ARPlantPlacementView: View {
    let plant: Plant

    @State private var isARSupported: Bool = ARWorldTrackingConfiguration.isSupported
    @State private var placementCount = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isARSupported {
                arView
            } else {
                unsupportedView
            }
        }
        .navigationTitle("AR Placement — \(plant.commonName)")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - AR view (placeholder sphere)

    private var arView: some View {
        VStack(spacing: 0) {
            // Live AR view
            ARPlaceholderSceneView(plant: plant, placementCount: $placementCount)
                .ignoresSafeArea(edges: .bottom)

            // HUD
            VStack(spacing: 14) {
                if placementCount == 0 {
                    Label("Point at a flat surface and tap to place", systemImage: "hand.tap.fill")
                        .font(.claudeSans(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                } else {
                    HStack(spacing: 16) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.green)
                        Text("\(plant.commonName) placed")
                            .font(.claudeSans(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Button(action: { placementCount = 0 }) {
                            Text("Reset")
                                .font(.claudeSans(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.75), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
            .background(.black.opacity(0.5))
        }
    }

    private var unsupportedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "arkit")
                .font(.system(size: 52))
                .foregroundStyle(.teal.opacity(0.7))
            Text("AR Not Supported")
                .font(.claudeSerif(size: 22, weight: .bold))
                .foregroundStyle(.white)
            Text("This device doesn't support AR world tracking. AR placement requires an A9 chip or later with a rear camera.")
                .font(.claudeSans(size: 14))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - AR scene (green sphere placeholder)

/// UIViewRepresentable wrapping ARView with a green sphere as a stand-in for the real 3D model.
/// Replace the sphere with a per-species USDZ `ModelEntity` in Phase 2.
private struct ARPlaceholderSceneView: UIViewRepresentable {
    let plant: Plant
    @Binding var placementCount: Int

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        // Tap to place
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)
        context.coordinator.arView = arView
        context.coordinator.parent = self
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        weak var arView: ARView?
        var parent: ARPlaceholderSceneView?

        @objc func handleTap(_ tap: UITapGestureRecognizer) {
            guard let arView, let parent else { return }
            let location = tap.location(in: arView)
            let results = arView.raycast(from: location,
                                         allowing: .estimatedPlane,
                                         alignment: .horizontal)
            guard let first = results.first else { return }

            // TODO: Replace sphere with USDZ model loaded from plant.id asset.
            let sphere = MeshResource.generateSphere(radius: 0.12)
            let material = SimpleMaterial(color: .systemGreen, roughness: 0.5, isMetallic: false)
            let model = ModelEntity(mesh: sphere, materials: [material])

            let anchor = AnchorEntity(world: first.worldTransform)
            anchor.addChild(model)
            arView.scene.addAnchor(anchor)

            parent.placementCount += 1
        }
    }
}

#Preview {
    ARPlantPlacementView(plant: Plant(
        id: "preview", commonName: "Monstera", botanicalName: "Monstera deliciosa",
        categoryId: "cat_aroid",
        origin: Origin(region: "Mexico", countries: nil, coordinates: Coordinates(lat: 0, lng: 0)),
        images: PlantImages(main: ""), description: "",
        careGuide: CareGuide(difficulty: "easy", light: "bright indirect", water: "weekly",
                             humidity: "high, 60-80%", soil: "well-draining",
                             temperatureRange: "65-85°F"),
        toxicity: Toxicity(isPetSafe: false, warning: "Toxic"),
        mlRecognitionConfidence: 0.9,
        skincarePotential: nil, propagation: nil, botanistQuote: nil
    ))
}

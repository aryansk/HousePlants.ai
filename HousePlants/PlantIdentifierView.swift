import SwiftUI
import PhotosUI

struct PlantIdentifierView: View {
    @EnvironmentObject var dataLoader: DataLoader

    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedOrgan: PlantOrgan = .auto
    @State private var isIdentifying = false
    @State private var results: [PlantNetResult] = []
    @State private var errorMessage: String?
    @State private var showCamera = false
    @State private var showKeySheet = false
    @ObservedObject private var proManager = ProManager.shared
    @State private var hasAPIKey = PlantNetService.shared.apiKey != nil

    /// True when the user has a key OR Pro supplies one automatically.
    private var effectiveHasAPIKey: Bool { hasAPIKey || proManager.isPro }

    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Plant Identifier",
                    subtitle: "Snap a photo to name any plant",
                    trailingActions: AnyView(
                        Button(action: { showKeySheet = true }) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                        }
                    )
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if !effectiveHasAPIKey {
                            apiKeyPromptCard
                        }

                        photoCard

                        if selectedImage != nil {
                            organPicker
                            identifyButton
                        }

                        if let errorMessage {
                            errorCard(errorMessage)
                        }

                        if !results.isEmpty {
                            resultsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                selectedImage = image
                results = []
                errorMessage = nil
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showKeySheet, onDismiss: {
            hasAPIKey = PlantNetService.shared.apiKey != nil
            // Re-evaluate after key sheet dismissal (covers the Pro inject path too).
        }) {
            PlantNetKeySheet()
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    results = []
                    errorMessage = nil
                }
                pickerItem = nil
            }
        }
    }

    // MARK: - Sections

    private var apiKeyPromptCard: some View {
        Button(action: { showKeySheet = true }) {
            HStack(spacing: 14) {
                Image(systemName: "key.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.claudeAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key Needed")
                        .font(.claudeSerif(size: 16, weight: .bold))
                        .foregroundColor(.claudePrimaryText)
                    Text("Get a free key at my.plantnet.org — 500 identifications a day, no charge.")
                        .font(.claudeSans(size: 13))
                        .foregroundColor(.claudeSecondaryText)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.claudeBorder)
            }
            .padding(16)
            .background(Color.claudeAccent.opacity(0.08))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.claudeAccent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var photoCard: some View {
        VStack(spacing: 16) {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .clipped()
                    .cornerRadius(20)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 44))
                        .foregroundColor(.claudeAccent)
                    Text("Photograph a leaf or flower up close, in good light, for the best match.")
                        .font(.claudeSans(size: 14))
                        .foregroundColor(.claudeSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.claudeSecondaryBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.claudeBorder, style: StrokeStyle(lineWidth: 1, dash: [6]))
                )
            }

            HStack(spacing: 12) {
                Button(action: { showCamera = true }) {
                    sourceButtonLabel(icon: "camera.fill", title: "Camera")
                }
                .buttonStyle(.plain)
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    sourceButtonLabel(icon: "photo.on.rectangle", title: "Library")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sourceButtonLabel(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.claudeSans(size: 15, weight: .semibold))
        }
        .foregroundColor(.claudePrimaryText)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.claudeSecondaryBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.claudeBorder, lineWidth: 1)
        )
    }

    private var organPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT'S IN THE PHOTO?")
                .font(.claudeSans(size: 11, weight: .bold))
                .foregroundColor(.claudeSecondaryText)
                .tracking(1.5)

            HStack(spacing: 8) {
                ForEach(PlantOrgan.allCases) { organ in
                    Button(action: { selectedOrgan = organ }) {
                        VStack(spacing: 4) {
                            Image(systemName: organ.icon)
                                .font(.system(size: 16))
                            Text(organ.label)
                                .font(.claudeSans(size: 11, weight: .semibold))
                        }
                        .foregroundColor(selectedOrgan == organ ? .white : .claudeSecondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedOrgan == organ ? Color.claudeAccent : Color.claudeSecondaryBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var identifyButton: some View {
        Button(action: identify) {
            HStack(spacing: 10) {
                if isIdentifying {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(isIdentifying ? "Identifying…" : "Identify Plant")
                    .font(.claudeSans(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.claudeAccent)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .disabled(isIdentifying)
    }

    private func errorCard(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.claudeSans(size: 14))
                .foregroundColor(.claudePrimaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BEST MATCHES")
                .font(.claudeSans(size: 11, weight: .bold))
                .foregroundColor(.claudeSecondaryText)
                .tracking(1.5)

            ForEach(results) { result in
                IdentificationResultRow(
                    result: result,
                    catalogMatch: PlantCatalogMatcher.match(
                        scientificName: result.species.scientificNameWithoutAuthor,
                        in: dataLoader.plants
                    )
                )
            }
        }
    }

    // MARK: - Actions

    private func identify() {
        guard let selectedImage,
              let jpeg = resizedJPEG(from: selectedImage) else { return }

        // Pro users get a bundled API key; inject it if they haven't set their own.
        if proManager.isPro && PlantNetService.shared.apiKey == nil {
            PlantNetService.shared.apiKey = ProConfig.plantNetAPIKey
        }

        errorMessage = nil
        results = []
        isIdentifying = true
        HapticManager.shared.playImpact(style: .medium)

        Task {
            do {
                let identified = try await PlantNetService.shared.identify(imageData: jpeg, organ: selectedOrgan)
                results = identified
                if identified.isEmpty {
                    errorMessage = PlantNetError.noMatch.errorDescription
                }
            } catch let error as PlantNetError {
                errorMessage = error.errorDescription
                if case .missingAPIKey = error { showKeySheet = true }
            } catch {
                errorMessage = "Identification failed. Check your connection and try again."
            }
            isIdentifying = false
        }
    }

    /// Downscales to keep uploads small — Pl@ntNet doesn't need more than ~1280px.
    private func resizedJPEG(from image: UIImage, maxDimension: CGFloat = 1280) -> Data? {
        let largest = max(image.size.width, image.size.height)
        guard largest > maxDimension else { return image.jpegData(compressionQuality: 0.8) }

        let scale = maxDimension / largest
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Result Row

private struct IdentificationResultRow: View {
    let result: PlantNetResult
    let catalogMatch: Plant?

    private var confidence: Int { Int((result.score * 100).rounded()) }

    private var displayName: String {
        result.species.commonNames?.first ?? result.species.scientificNameWithoutAuthor
    }

    var body: some View {
        if let catalogMatch {
            NavigationLink(destination: PlantDetailView(plant: catalogMatch)) {
                rowContent(inCatalog: true)
            }
            .buttonStyle(InteractiveCardButtonStyle())
        } else {
            rowContent(inCatalog: false)
        }
    }

    private func rowContent(inCatalog: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.claudeBorder, lineWidth: 3)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: result.score)
                    .stroke(confidenceColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                Text("\(confidence)%")
                    .font(.claudeSans(size: 11, weight: .bold))
                    .foregroundColor(.claudePrimaryText)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(.claudeSerif(size: 17, weight: .bold))
                    .foregroundColor(.claudePrimaryText)
                    .multilineTextAlignment(.leading)

                Text(result.species.scientificNameWithoutAuthor)
                    .font(.claudeSans(size: 13).italic())
                    .foregroundColor(.claudeSecondaryText)

                if inCatalog {
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 10))
                        Text("In your catalog — view care guide")
                            .font(.claudeSans(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.claudeAccent)
                }
            }

            Spacer()

            if inCatalog {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.claudeBorder)
            }
        }
        .padding(16)
        .background(Color.claudeSecondaryBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(inCatalog ? Color.claudeAccent.opacity(0.4) : Color.claudeBorder, lineWidth: 1)
        )
    }

    private var confidenceColor: Color {
        switch result.score {
        case 0.6...: return .green
        case 0.3..<0.6: return .orange
        default: return .red
        }
    }
}

// MARK: - API Key Sheet

private struct PlantNetKeySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var keyInput = PlantNetService.shared.apiKey ?? ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Plant identification is powered by Pl@ntNet, a free citizen-science project. Create an account at my.plantnet.org, copy your API key from the dashboard, and paste it below.")
                        .font(.claudeSans(size: 14))
                        .foregroundColor(.claudeSecondaryText)

                    Link(destination: URL(string: "https://my.plantnet.org")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Open my.plantnet.org")
                                .font(.claudeSans(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.claudeAccent)
                    }

                    TextField("Paste your API key", text: $keyInput)
                        .font(.claudeSans(size: 15))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(Color.claudeSecondaryBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.claudeBorder, lineWidth: 1)
                        )

                    Button(action: {
                        PlantNetService.shared.apiKey = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }) {
                        Text("Save Key")
                            .font(.claudeSans(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.claudeAccent)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Pl@ntNet API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Camera Picker

private struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        PlantIdentifierView()
            .environmentObject(DataLoader.shared)
    }
}

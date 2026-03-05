// HungerView.swift
import SwiftUI
import Photos
import Combine

// MARK: - ViewModel
@MainActor
final class PhotosSwipeViewModel: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var co2Saved: Double = 0
    @Published var deletedCount: Int = 0
    @Published var keptCount: Int = 0

    var currentAsset: PHAsset? {
        guard currentIndex < assets.count else { return nil }
        return assets[currentIndex]
    }

    var nextAsset: PHAsset? {
        guard currentIndex + 1 < assets.count else { return nil }
        return assets[currentIndex + 1]
    }

    var isFinished: Bool { currentIndex >= assets.count && !assets.isEmpty }

    // Chiamato in onAppear — automatico, nessun bottone
    func loadIfNeeded() {
        Task {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch status {
            case .authorized, .limited:
                await fetchAssets()
            case .notDetermined:
                let result = await withCheckedContinuation { cont in
                    PHPhotoLibrary.requestAuthorization(for: .readWrite) { cont.resume(returning: $0) }
                }
                if result == .authorized || result == .limited {
                    await fetchAssets()
                } else {
                    error = "Permesso negato. Vai in Impostazioni > Privacy > Foto."
                }
            default:
                error = "Accesso negato. Vai in Impostazioni > Privacy > Foto."
            }
        }
    }

    private func fetchAssets() async {
        isLoading = true
        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "mediaType == %d OR mediaType == %d",
            PHAssetMediaType.image.rawValue,
            PHAssetMediaType.video.rawValue
        )
        let result = PHAsset.fetchAssets(with: options)
        var list: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in list.append(asset) }
        assets = list.shuffled()
        currentIndex = 0
        isLoading = false
    }

    func sizeInMB(_ asset: PHAsset) -> Double {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first else { return 0 }
        if let size = resource.value(forKey: "fileSize") as? Int64 { return Double(size) / (1024 * 1024) }
        if let size = resource.value(forKey: "fileSize") as? CLong  { return Double(size) / (1024 * 1024) }
        return 0
    }

    // 0.2g CO2 per MB — stima realistica per storage cloud
    func co2ForMB(_ mb: Double) -> Double { mb * 0.2 }

    func confirmDelete() {
        guard let asset = currentAsset else { return }
        let mb = sizeInMB(asset)
        co2Saved += co2ForMB(mb)
        deletedCount += 1
        currentIndex += 1
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }, completionHandler: nil)
    }

    func confirmKeep() {
        keptCount += 1
        currentIndex += 1
    }

    func restart() {
        currentIndex = 0
        co2Saved = 0
        deletedCount = 0
        keptCount = 0
        assets.shuffle()
    }
}

// MARK: - AssetImageView
struct AssetImageView: View {
    let asset: PHAsset
    @State private var image: UIImage? = nil

    var body: some View {
        ZStack {
            Color(red: 0.14, green: 0.14, blue: 0.13)
            if let img = image {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                ProgressView().tint(.orange)
            }
        }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        let opts = PHImageRequestOptions()
        opts.deliveryMode = .highQualityFormat
        opts.isNetworkAccessAllowed = true
        opts.isSynchronous = false
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 600, height: 800),
            contentMode: .aspectFill,
            options: opts
        ) { img, _ in
            if let img { DispatchQueue.main.async { self.image = img } }
        }
    }
}

// MARK: - HungerView
struct HungerView: View {
    @EnvironmentObject var game: GameManager
    @StateObject private var vm = PhotosSwipeViewModel()
    @State private var dragOffset: CGSize = .zero
    @State private var isAnimatingOut = false

    private var swipeRight: Bool { dragOffset.width >  60 }
    private var swipeLeft:  Bool { dragOffset.width < -60 }

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                Rob8View(mood: .hungry, size: 48, animate: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clean Your Library")
                        .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                    Text("Swipe right to delete · left to keep")
                        .font(.system(size: 12, design: .monospaced)).foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.top, 16)

            // Stats
            HStack(spacing: 12) {
                StatChip(icon: "photo.stack.fill",
                         value: "\(max(0, vm.assets.count - vm.currentIndex))",
                         label: "remaining")
                StatChip(icon: "trash.fill",   value: "\(vm.deletedCount)",                   label: "deleted")
                StatChip(icon: "leaf.fill",    value: String(format: "%.1fg", vm.co2Saved),   label: "CO2 saved")
            }
            .padding(.horizontal, 20).padding(.top, 12)

            // States
            if vm.isLoading {
                Spacer()
                VStack(spacing: 16) {
                    Rob8View(mood: .curious, size: 90)
                    ProgressView("Loading your library...").tint(.orange).foregroundColor(.gray)
                }
                Spacer()

            } else if let error = vm.error {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill").font(.system(size: 44)).foregroundColor(.orange)
                    Text(error).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 32)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }.buttonStyle(.borderedProminent).tint(.orange)
                }
                Spacer()

            } else if vm.isFinished {
                Spacer()
                VStack(spacing: 16) {
                    Rob8View(mood: .happy, size: 100)
                    Text("All done! 🎉").font(.system(size: 22, weight: .bold)).foregroundColor(.green)
                    VStack(spacing: 6) {
                        Text("Deleted: \(vm.deletedCount)").font(.system(size: 13, design: .monospaced)).foregroundColor(.gray)
                        Text("Kept: \(vm.keptCount)").font(.system(size: 13, design: .monospaced)).foregroundColor(.gray)
                        Text(String(format: "CO2 saved: %.1f g", vm.co2Saved))
                            .font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.orange)
                    }
                    Button("Start Over") { vm.restart() }.buttonStyle(.borderedProminent).tint(.orange)
                }
                Spacer()

            } else if vm.currentAsset != nil {
                Spacer()

                ZStack {
                    // Foto successiva — sotto, statica, nessun gesture
                    if let next = vm.nextAsset {
                        AssetImageView(asset: next)
                            .id("next-\(next.localIdentifier)")
                            .frame(width: 280, height: 370)
                            .clipped()
                            .cornerRadius(24)
                            .scaleEffect(0.93)
                            .opacity(0.5)
                    }

                    // Foto corrente — sopra, interattiva
                    if let current = vm.currentAsset {
                        currentCard(current)
                            .id("current-\(current.localIdentifier)")
                            .gesture(
                                DragGesture()
                                    .onChanged { v in
                                        guard !isAnimatingOut else { return }
                                        dragOffset = v.translation
                                    }
                                    .onEnded { _ in
                                        guard !isAnimatingOut else { return }
                                        handleSwipeEnd(asset: current)
                                    }
                            )
                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
                    }
                }
                .frame(height: 390)

                // Solo hint, nessun bottone
                HStack {
                    Text("← Keep")
                    Spacer()
                    Text("Delete →")
                }
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.horizontal, 52)
                .padding(.top, 16)

                Spacer()
            }
        }
        .onAppear {
            guard vm.assets.isEmpty && !vm.isLoading else { return }
            vm.loadIfNeeded()
        }
    }

    @ViewBuilder
    private func currentCard(_ current: PHAsset) -> some View {
        let mb = vm.sizeInMB(current)
        ZStack(alignment: .bottom) {
            AssetImageView(asset: current)
                .frame(width: 280, height: 370)
                .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.85)],
                           startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: current.mediaType == .video ? "video.fill" : "photo.fill")
                        .font(.system(size: 11)).foregroundColor(.orange)
                    Text(current.mediaType == .video ? "VIDEO" : "FOTO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(.orange)
                    Spacer()
                    if let date = current.creationDate {
                        Text(date, format: .dateTime.day().month().year())
                            .font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.5))
                    }
                }
                HStack {
                    Text(String(format: "%.1f MB", mb))
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Text(String(format: "CO2 %.1f g", vm.co2ForMB(mb)))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(.orange)
                }
            }
            .padding(16)

            if swipeRight {
                VStack {
                    HStack {
                        Spacer()
                        Text("DELETE")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundColor(.white).padding(10)
                            .background(Color.red).cornerRadius(10).padding(16)
                    }
                    Spacer()
                }
            }
            if swipeLeft {
                VStack {
                    HStack {
                        Text("KEEP")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundColor(.white).padding(10)
                            .background(Color.green).cornerRadius(10).padding(16)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .frame(width: 280, height: 370)
        .cornerRadius(24)
        .shadow(color: swipeRight ? .red.opacity(0.6) : swipeLeft ? .green.opacity(0.6) : .black.opacity(0.4), radius: 24)
        .rotationEffect(.degrees(Double(dragOffset.width) * 0.05))
        .offset(x: dragOffset.width, y: dragOffset.height * 0.1)
    }

    private func handleSwipeEnd(asset: PHAsset) {
        if dragOffset.width > 60       { animateOut(asset: asset, delete: true) }
        else if dragOffset.width < -60 { animateOut(asset: asset, delete: false) }
        else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { dragOffset = .zero }
        }
    }

    private func animateOut(asset: PHAsset, delete: Bool) {
        guard !isAnimatingOut else { return }
        isAnimatingOut = true
        withAnimation(.easeIn(duration: 0.2)) {
            dragOffset = CGSize(width: delete ? 700 : -700, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dragOffset = .zero
            if delete { vm.confirmDelete(); game.increaseHunger() }
            else      { vm.confirmKeep() }
            isAnimatingOut = false
        }
    }
}

// MARK: - StatChip
struct StatChip: View {
    let icon: String; let value: String; let label: String
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(.orange)
            Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 9, design: .monospaced)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(Color(red: 0.14, green: 0.14, blue: 0.13)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07)))
    }
}

#Preview {
    HungerView().environmentObject(GameManager())
        .background(Color(red: 0.10, green: 0.10, blue: 0.09))
}

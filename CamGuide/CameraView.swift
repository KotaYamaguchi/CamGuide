import SwiftUI
import AVFoundation
struct CameraView: View {
    @StateObject var viewModel = CameraViewModel()
    @State var showGallery = false
    @State private var showAspectRatioSelcter: Bool = false
    @State private var showExporseSlider: Bool = false
    @State private var deviceSize: CGSize = CGSize(width: 400, height: 300)
    @State private var tappedLocation: CGPoint = .zero
    @State private var isTapped: Bool = false
    @State private var showSettingPopover: Bool = false
    @State var showGrid:Bool = false
    @State var showResult:Bool = false
    @State private var showExplanation = true
    // ポップオーバー内でも使い回すために説明文を定数化
    private let explanationText = "Please move the iPad in the direction of the animation. \nIt indicates the optimal moment for capturing the best photo."
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreviewView(session: viewModel.session, tappedLocation: $tappedLocation)
                    .edgesIgnoringSafeArea(.all)
                AspectMaskView(showGrid: $showGrid, viewModel: viewModel, ratio: viewModel.selectedAspectRatio.numericValue, maskOpacity: 1.0, regionResults: viewModel.regionResults, showResults: $showResult)
                    .edgesIgnoringSafeArea(.all)
                MoveAnimationView(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    if showExplanation {
                        Text(explanationText)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.5))
                            )
                            .padding(.top, 50)
                    }
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    if showExporseSlider {
                        SliderView(value: $viewModel.exposureBias, range: -2.0...2.0)
                            .rotationEffect(.degrees(180))
                            .padding()
                    }
                    if showAspectRatioSelcter {
                        aspectRatioSelecter()
                    }
                    VStack {
                        Button {
                            showSettingPopover.toggle()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding()
                                .background {
                                    Circle().foregroundStyle(.black.opacity(0.3))
                                }
                        }
                        .popover(isPresented:$showSettingPopover){
                            VStack(alignment: .leading) {
                                // ポップオーバー内に説明文欄を追加
                                Text("Explanation")
                                    .font(.headline)
                                Text(explanationText)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 10)
                                
                                Divider().padding(.vertical, 4)
                                
                                toggleCard(
                                    isOn: $showGrid,
                                    title: "Show Grid",
                                    description: "Displays 3×3 grid lines",
                                    icon: "grid"
                                )
                                
                                toggleCard(
                                    isOn: $showResult,
                                    title: "Show Results",
                                    description: "Displays the aesthetic rating of each of the 3×3 grids",
                                    icon: "chart.bar"
                                )
                            }
                            .padding()
                        }
                        Spacer()
                        if viewModel.isAvailableFlash {
                            Button {
                                viewModel.toggleFlashMode()
                            } label: {
                                Image(systemName: flashIcon(for: viewModel.flashMode))
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .padding()
                                    .background {
                                        Circle().foregroundStyle(.black.opacity(0.3))
                                    }
                            }
                        }
                        Button {
                            withAnimation {
                                showExporseSlider.toggle()
                                showAspectRatioSelcter = false
                            }
                        } label: {
                            Image(systemName: "plusminus.circle")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding()
                                .background {
                                    Circle().foregroundStyle(.black.opacity(0.3))
                                }
                        }
                        Button {
                            withAnimation {
                                showAspectRatioSelcter.toggle()
                                showExporseSlider = false
                            }
                        } label: {
                            Text(currentAspectRatio())
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding()
                                .background {
                                    Circle().foregroundStyle(.black.opacity(0.3))
                                }
                        }
                        Button {
                            viewModel.capturePhoto()
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(lineWidth: 6)
                                    .foregroundStyle(.white)
                                    .frame(width: 54, height: 54)
                                Circle()
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .padding(.vertical)
                        Button {
                            showGallery = true
                        } label: {
                            if !viewModel.capturedImages.isEmpty {
                                Image(uiImage: viewModel.capturedImages[0]!)
                                    .resizable()
                                    .frame(width: 44, height: 44)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 5)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        Spacer()
                    }
                    .padding(.trailing)
                }
                
                // tap effect
                if isTapped {
                    tappedEffect()
                        .position(convertToScreenCoordinates(tappedLocation, in: geometry.size))
                        .transition(.opacity)
                }
            }
            .fullScreenCover(isPresented: $showGallery) {
                GalleryView(
                    images: viewModel.capturedImages,
                    showGallery: $showGallery
                )
            }
            .onChange(of: tappedLocation) { _, newValue in
                withAnimation(.easeOut(duration: 0.2)) {
                    isTapped = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isTapped = false
                    }
                }
                viewModel.setFocus(newValue)
            }
            .onAppear {
                viewModel.startSession()
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    withAnimation {
                        showExplanation = false
                    }
                }
            }
            .onDisappear {
                viewModel.stopSession()
            }
        }
    }
    private func flashIcon(for mode: AVCaptureDevice.FlashMode) -> String {
        switch mode {
        case .auto:
            return "bolt.badge.a"
        case .on:
            return "bolt"
        case .off:
            return "bolt.slash"
        @unknown default:
            return "bolt.slash"
        }
    }
    func tappedEffect() -> some View {
        Rectangle()
            .stroke(Color.yellow, lineWidth: 2)
            .frame(width: 50, height: 50)
            .scaleEffect(isTapped ? 1.2 : 1.0)
            .opacity(isTapped ? 1 : 0)
    }
    func convertToScreenCoordinates(_ normalizedPoint: CGPoint, in size: CGSize) -> CGPoint {
        return CGPoint(
            x: normalizedPoint.x * size.width,
            y: normalizedPoint.y * size.height
        )
    }
    private func toggleCard(isOn: Binding<Bool>,title: String,description: String,icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding()
        .background{
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1),radius: 5,x: 0,y: 2)
        }
    }
    func currentAspectRatio() -> String {
        switch viewModel.selectedAspectRatio {
        case .ratio16_9:
            return "16:9"
        case .square:
            return "1:1"
        case .ratio4_3:
            return "4:3"
        }
    }
    func aspectRatioSelecter() -> some View {
        VStack {
            Spacer()
           
            Text("16:9")
                .foregroundStyle(.white)
                .font(.caption)
                .onTapGesture {
                    withAnimation {
                        viewModel.selectedAspectRatio = .ratio16_9
                        showAspectRatioSelcter = false
                    }
                }
            Spacer()
            Text("1:1")
                .foregroundStyle(.white)
                .font(.caption)
                .onTapGesture {
                    withAnimation {
                        viewModel.selectedAspectRatio = .square
                        showAspectRatioSelcter = false
                    }
                }
            Spacer()
            Text("4:3")
                .foregroundStyle(.white)
                .font(.caption)
                .onTapGesture {
                    withAnimation {
                        viewModel.selectedAspectRatio = .ratio4_3
                        showAspectRatioSelcter = false
                    }
                }
            Spacer()
        }
        .frame(width: 44, height: 200)
        .background {
            RoundedRectangle(cornerRadius: 30)
                .foregroundStyle(.black.opacity(0.3))
        }
    }
}


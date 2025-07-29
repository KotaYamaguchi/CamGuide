import SwiftUI

struct MoveAnimationView: View {
    @ObservedObject var viewModel: CameraViewModel
    @State private var offset: CGSize = .zero
    @State private var goalOffset: CGSize = .zero
    @State private var isAnimating = false
    @State private var isVisible = false 
    @State private var isPhotoCaptureReady = false 
    @State private var lastHighestRegion: RegionResult? = nil
    
    var body: some View {
        ZStack {
            if isPhotoCaptureReady {
                Text("Take a photo!!")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background{
                        RoundedRectangle(cornerRadius:15)
                            .foregroundColor(.yellow.opacity(0.7))
                    }
                Rectangle()
                    .stroke(lineWidth: 15)
                    .foregroundColor(.yellow.opacity(0.5))
                    .edgesIgnoringSafeArea(.all)
                
            } else if isVisible {
                ZStack {
                    // Target position image (without animation)
                    Image("movingInstructions")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400)
                        .offset(goalOffset)
                        .opacity(0.6)
                        .animation(nil, value: goalOffset)
                    
                    // Animated image
                    Image("movingInstructions")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400)
                        .colorMultiply(.black)
                        .offset(offset)
                    
                    
                    Text("Slide your iPad in the indicated direction")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .offset(y: 150)
                }
            }
        }
        .onChange(of: viewModel.regionResults) { newResults in
            guard let highest = newResults.max(by: { $0.confidence < $1.confidence }) else { return }
            
            if lastHighestRegion?.id != highest.id || lastHighestRegion?.confidence != highest.confidence {
                lastHighestRegion = highest
                
                // If the detected region is the central area (e.g., region.id % 8 == 4)
                if highest.id % 8 == 4 {
                    isAnimating = false
                    isVisible = false
                    if !isPhotoCaptureReady {
                        isPhotoCaptureReady = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            isPhotoCaptureReady = false
                        }
                    }
                } else {
                    if !isAnimating && !isPhotoCaptureReady {
                        startAnimationSequence(for: highest)
                    }
                }
            }
        }
        .onChange(of: viewModel.didCapturePhoto) { newValue in
            if newValue {
                isPhotoCaptureReady = false
            }
        }
    }
    
    private func startAnimationSequence(for region: RegionResult) {
        isAnimating = true
        isVisible = true
        offset = .zero
        
        let newGoalOffset = calculateGoalOffset(for: region.id)
        goalOffset = newGoalOffset
        
        withAnimation(.easeInOut(duration: 1.5)) {
            offset = goalOffset
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            isAnimating = false
            isVisible = false
        }
    }
    private func calculateGoalOffset(for direction: Int) -> CGSize {
        switch direction % 8 {
        case 0: return CGSize(width: -300, height: -250) // Top left
        case 1: return CGSize(width: 0, height: -250)    // Top
        case 2: return CGSize(width: 300, height: -250)  // Top right
        case 3: return CGSize(width: -300, height: 0)    // Left
        case 4: return .zero                             // Center
        case 5: return CGSize(width: 300, height: 0)     // Right
        case 6: return CGSize(width: -300, height: 250)  // Bottom left
        case 7: return CGSize(width: 0, height: 250)     // Bottom
        default: return .zero
        }
    }
}

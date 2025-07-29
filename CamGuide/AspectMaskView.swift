import SwiftUI
struct AspectMaskView: View {
    @Binding var showGrid: Bool
    @ObservedObject var viewModel: CameraViewModel
    let ratio: CGFloat?
    let maskOpacity: Double
    let regionResults: [RegionResult]
    let regionBorderColor: Color = .white
    @Binding var showResults: Bool
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let fullRect = CGRect(origin: .zero, size: size)
            let maskRect = calculateAspectRect(in: size, ratio: ratio)
            
            ZStack {
                Path { path in
                    path.addRect(fullRect)
                    path.addRect(maskRect)
                }
                .fill(Color.black.opacity(maskOpacity), style: FillStyle(eoFill: true))
                .allowsHitTesting(false)
                //3*3 Grid
                if showGrid {
                    Path { path in
                        let col1 = maskRect.minX + maskRect.width / 3
                        let col2 = maskRect.minX + 2 * maskRect.width / 3
                        path.move(to: CGPoint(x: col1, y: maskRect.minY))
                        path.addLine(to: CGPoint(x: col1, y: maskRect.maxY))
                        path.move(to: CGPoint(x: col2, y: maskRect.minY))
                        path.addLine(to: CGPoint(x: col2, y: maskRect.maxY))
                        
                        let row1 = maskRect.minY + maskRect.height / 3
                        let row2 = maskRect.minY + 2 * maskRect.height / 3
                        path.move(to: CGPoint(x: maskRect.minX, y: row1))
                        path.addLine(to: CGPoint(x: maskRect.maxX, y: row1))
                        path.move(to: CGPoint(x: maskRect.minX, y: row2))
                        path.addLine(to: CGPoint(x: maskRect.maxX, y: row2))
                    }
                    .stroke(regionBorderColor, lineWidth: 1)
                }
                //analysis results
                if showResults {
                    Grid {
                        GridRow {
                            ForEach(0..<3, id: \.self) { index in
                                if index < regionResults.count {
                                    let result = regionResults[index]
                                    Text(String(format: "%.2f", result.confidence))
                                    .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    Text("-")
                                    .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                        }
                        GridRow {
                            ForEach(3..<6, id: \.self) { index in
                                if index < regionResults.count {
                                    let result = regionResults[index]
                                    Text(String(format: "%.2f", result.confidence))
                                    .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    Text("-")
                                    .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                        }
                        GridRow {
                            ForEach(6..<9, id: \.self) { index in
                                if index < regionResults.count {
                                    let result = regionResults[index]
                                    Text(String(format: "%.2f", result.confidence))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    Text("-")
                                    .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                        }
                    }
                    .frame(width: maskRect.width, height: maskRect.height)
                    .position(x: maskRect.midX, y: maskRect.midY)
                }
            }
        }
    }
    private func calculateAspectRect(in containerSize: CGSize, ratio: CGFloat?) -> CGRect {
        guard let ratio = ratio, ratio > 0 else {
            return .zero
        }
        let containerW = containerSize.width
        let containerH = containerSize.height
        let containerRatio = containerW / containerH
        
        if containerRatio > ratio {
            let newWidth = containerH * ratio
            let originX = (containerW - newWidth) / 2
            return CGRect(x: originX, y: 0, width: newWidth, height: containerH)
        } else {
            let newHeight = containerW / ratio
            let originY = (containerH - newHeight) / 2
            return CGRect(x: 0, y: originY, width: containerW, height: newHeight)
        }
    }
}

import SwiftUI

struct PhotoDetailView: View {
    @ObservedObject var imageAnalyze = ImageAnalyze()
    @State private var imageScore: Float = 0.0
    @Binding var showDetail: Bool
    let images: [UIImage]
    @Binding var currentIndex: Int
    @State private var showPopover: Bool = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            TabView(selection: $currentIndex) {
                ForEach(0..<images.count, id: \.self) { index in
                    Image(uiImage: images[index])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIScreen.main.bounds.width)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .onAppear {
                // Change indicator color
                UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.clear
                UIPageControl.appearance().pageIndicatorTintColor = UIColor.clear
            }
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button {
                        // Perform image analysis (retrieve aesthetic score)
                        Task {
                            do {
                                let rawScore = try await imageAnalyze.analyzeUIImage(image: images[currentIndex])
                                imageScore = (rawScore + 1) * 50
                                print("Aesthetic score of the image (out of 100): \(imageScore)")
                            } catch {
                                print("An error occurred during image analysis: \(error)")
                            }
                        }
                        showPopover.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                            .font(.title2)
                            .padding(4)
                            .background {
                                Circle().foregroundStyle(.gray.opacity(0.5))
                            }
                    }
                    .popover(isPresented: $showPopover) {
                        VStack(spacing: 16) {
                            Text("Image Score")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            ZStack {
                                Circle()
                                    .stroke(
                                        Color.gray.opacity(0.3),
                                        lineWidth: 8
                                    )
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(imageScore) / 100)
                                    .stroke(
                                        .blue,
                                        style: StrokeStyle(
                                            lineWidth: 8,
                                            lineCap: .round
                                        )
                                    )
                                    .rotationEffect(.degrees(-90))
                                
                                VStack(spacing: 4) {
                                    Text("\(Int(round(imageScore)))")
                                        .font(.system(size: 44, weight: .bold))
                                    Text("/ 100")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(width: 150, height: 150)
                            .padding(.vertical)
                        }
                        .padding()
                        .frame(width: 200, height: 280)
                    }                    
                    Button {
                        showDetail = false
                    } label: {
                        Image(systemName: "xmark.circle")
                        .foregroundStyle(.blue)
                            .font(.title2)
                            .padding(4)
                            .background {
                                Circle().foregroundStyle(.gray.opacity(0.5))
                            }
                    }
                }
                Spacer()
            }
            .padding(.trailing, 30)
            .padding(.vertical)
        }
    }
}

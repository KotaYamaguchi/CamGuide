import SwiftUI

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

import SwiftUI

struct SliderView: View {
    @Binding var value: Float
    private var range: ClosedRange<Double>
    private var stepCount: Float
    private var step: Double
    
    @State private var scrollPosition: Int?
    
    init(value: Binding<Float>, range: ClosedRange<Double>, stepCount: Float = 10) {
        self._value = value
        self.range = range
        self.stepCount = stepCount
        self.step = (range.upperBound - range.lowerBound) / Double(stepCount)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 16, height: geometry.size.height * 0.45)
                        
                        VStack(spacing: 0) {
                            ForEach(0..<Int(stepCount)+1, id: \ .self) { index in
                                let isFifth = index % 5 == 0
                                
                                Rectangle()
                                    .fill(.primary.opacity(isFifth ? 1 : 0.5))
                                    .frame(width: isFifth ? 16 : 12, height: 1)
                                    .frame(height: geometry.size.height / 18.66)
                                    .id(index)
                            }
                        }
                        .scrollTargetLayout()
                        
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 16, height: geometry.size.height * 0.44)
                    }
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                }
                .scrollIndicators(.never)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrollPosition, anchor: .center)
                .onChange(of: scrollPosition) { _, newPosition in
                    guard let newPosition else { return }
                    let snapValue = Double(newPosition) * step + range.lowerBound
                    value = Float(snapValue)
                }
                .onAppear {
                    let valueStep = Int((Double(value) - range.lowerBound) / step)
                    proxy.scrollTo(valueStep, anchor: .center)
                }
                .sensoryFeedback(.selection, trigger: scrollPosition)
            }
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(.yellow)
                .frame(width: 22, height: 2.5)
                .offset(y: 2)
        }
        .frame(width: 26)
    }
}

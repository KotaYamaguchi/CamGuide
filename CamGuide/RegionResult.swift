import SwiftUI

/// Structure to store image analysis results, including region ID, label, and confidence score
struct RegionResult: Identifiable, Equatable {
    let id: Int
    let label: String
    let confidence: Double
    
    static func == (lhs: RegionResult, rhs: RegionResult) -> Bool {
        return lhs.id == rhs.id && lhs.label == rhs.label && lhs.confidence == rhs.confidence
    }
}

import SwiftUI

/// Enum defining the aspect ratios that users can select
enum PhotoAspectRatio: String, CaseIterable {
    case square = "1:1"
    case ratio4_3 = "4:3"
    case ratio16_9 = "16:9"
    
    /// Returns the numeric width-to-height ratio (returns nil if cropping is not needed)
    var numericValue: CGFloat? {
        switch self {
        case .square:
            return 1.0
        case .ratio4_3:
            return 4.0 / 3.0
        case .ratio16_9:
            return 16.0 / 9.0
        }
    }
}

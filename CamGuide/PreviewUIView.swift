import AVFoundation
import SwiftUI

class PreviewUIView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer
    /// Closure to notify SwiftUI of the tap location
    var tappedLocationHandler: ((CGPoint) -> Void)?
    
    init(session: AVCaptureSession) {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPreview(_:)))
        self.addGestureRecognizer(tapGesture)
        
        // Observe device orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        updatePreviewOrientation(UIDevice.current.orientation)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        updatePreviewOrientation(UIDevice.current.orientation)
    }
    
    /// Get tap location and notify SwiftUI
    @objc private func didTapPreview(_ gesture: UITapGestureRecognizer) {
        let tapPoint = gesture.location(in: self)
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: tapPoint)
        tappedLocationHandler?(devicePoint)
    }
    
    /// Update preview orientation when device orientation changes
    @objc private func deviceOrientationDidChange() {
        updatePreviewOrientation(UIDevice.current.orientation)
    }
    
    /// Handles updating the preview orientation
    private func updatePreviewOrientation(_ orientation: UIDeviceOrientation) {
        guard let connection = previewLayer.connection else { return }
        
        if #available(iOS 17.0, *) {
            switch orientation {
            case .portrait:
                connection.videoRotationAngle = 90
            case .landscapeLeft:
                connection.videoRotationAngle = 0
            case .landscapeRight:
                connection.videoRotationAngle = 180
            case .portraitUpsideDown:
                connection.videoRotationAngle = 270
            default:
                break
            }
        } else {
            switch orientation {
            case .portrait:
                connection.videoOrientation = .portrait
            case .landscapeLeft:
                connection.videoOrientation = .landscapeRight
            case .landscapeRight:
                connection.videoOrientation = .landscapeLeft
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            default:
                break
            }
        }
    }
}

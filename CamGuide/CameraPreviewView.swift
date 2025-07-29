import SwiftUI
import AVFoundation
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    @Binding var tappedLocation: CGPoint 

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView(session: session)
        view.tappedLocationHandler = { newLocation in
            tappedLocation = newLocation
        }
        return view
    }
    
    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

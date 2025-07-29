import AVFoundation
import SwiftUI
import UniformTypeIdentifiers
class CameraViewModel: NSObject, ObservableObject {
    
    @Published var didCapturePhoto: Bool = false
    private var captureDevice: AVCaptureDevice?
    @Published var session = AVCaptureSession()
    @Published var flashMode: AVCaptureDevice.FlashMode = .auto 
    @Published var isAvailableFlash: Bool = false
    @Published var exposureBias: Float = 0.0 {
        didSet {
            updateExposure()
        }
    }
    
    private let imageAnalyze: ImageAnalyze = ImageAnalyze()
    @Published var regionResults: [RegionResult] = []
    @Published var capturedImages: [UIImage?] = [
        UIImage(named: "photo1"),
        UIImage(named: "photo2"),
        UIImage(named: "photo3"),
        UIImage(named: "photo4"),
        UIImage(named: "photo5"),
        UIImage(named: "photo6"),
        UIImage(named: "photo7"),
        UIImage(named: "photo8"),
        UIImage(named: "photo9"),
        UIImage(named: "photo10")
    ]
    @Published var selectedAspectRatio: PhotoAspectRatio = .ratio4_3
    private let regionCoords: [String: [(CGFloat, CGFloat)]] = [
        "Base": [(0.000, 0.000), (0.665, 0.000), (0.000, 0.667), (0.665, 0.667)],
        "A": [(0.166, 0.000), (0.831, 0.000), (0.166, 0.667), (0.831, 0.667)],
        "B": [(0.333, 0.000), (1.000, 0.000), (0.333, 0.667), (1.000, 0.667)],
        "C": [(0.000, 0.167), (0.665, 0.167), (0.000, 0.833), (0.665, 0.833)],
        "D": [(0.166, 0.167), (0.831, 0.167), (0.166, 0.833), (0.831, 0.833)],
        "E": [(0.333, 0.167), (1.000, 0.167), (0.333, 0.833), (1.000, 0.833)],
        "F": [(0.000, 0.333), (0.665, 0.333), (0.000, 1.000), (0.665, 1.000)],
        "G": [(0.166, 0.333), (0.831, 0.333), (0.166, 1.000), (0.831, 1.000)],
        "H": [(0.333, 0.333), (1.000, 0.333), (0.333, 1.000), (1.000, 1.000)]
    ]
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "CameraQueue")
    private let photoOutput = AVCapturePhotoOutput()
    private var lastAnalysisTime: CFTimeInterval = 0
    private let analysisInterval: CFTimeInterval = 1.0
    private var lastCapturedPixelBuffer: CVPixelBuffer?
    
    override init() {
        super.init()
        setupSession()
    }
    private func setupSession() {
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Unable to access camera")
            session.commitConfiguration()
            return
        }
        self.captureDevice = device
        toggleFlashMode()
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            output.setSampleBufferDelegate(self, queue: queue)
        }
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()
    }
    func startSession() {
        session.startRunning()
    }
    func stopSession() {
        session.stopRunning()
    }
    private func boundingRectForRegion(region: String, imageWidth: Int, imageHeight: Int) -> CGRect {
        guard let regionCoords = regionCoords[region] else { return .zero }
        let x = CGFloat(imageWidth) * regionCoords[0].0
        let y = CGFloat(imageHeight) * regionCoords[0].1
        let width = CGFloat(imageWidth) * (regionCoords[1].0 - regionCoords[0].0)
        let height = CGFloat(imageHeight) * (regionCoords[2].1 - regionCoords[0].1)
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    func toggleFlashMode() {
        if !captureDevice!.hasFlash {
            flashMode = .off
            isAvailableFlash = false
        } else {
            switch flashMode {
            case .auto:
                flashMode = .on
            case .on:
                flashMode = .off
            case .off:
                flashMode = .auto
            @unknown default:
                flashMode = .off
            }
            isAvailableFlash = true
        }
    }
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    func setFocus(_ point: CGPoint) {
        guard let device = captureDevice else { return }
        do {
            try device.lockForConfiguration()
            device.focusPointOfInterest = point
            device.focusMode = .autoFocus
            device.unlockForConfiguration()
        } catch {
            print("focus error: \(error)")
        }
    }
    
    /// 露出補正を更新する処理
    private func updateExposure() {
        guard let device = captureDevice else { return }
        do {
            try device.lockForConfiguration()
            if exposureBias == 0.0 {
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
            } else {
                let minBias = device.minExposureTargetBias
                let maxBias = device.maxExposureTargetBias
                let clampedBias = max(min(exposureBias, maxBias), minBias)
                device.setExposureTargetBias(clampedBias) { _ in
                    print("Exposure compensation applied: \(clampedBias)")
                }
            }
            device.unlockForConfiguration()
        } catch {
            print("Failure to change exposure settings: \(error.localizedDescription)")
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            print("Photo capture error:", error)
            return
        }
        guard let cgImageRef = photo.cgImageRepresentation() else {
            print("Failed to get cgImageRepresentation")
            return
        }
        var uiImage = UIImage(cgImage: cgImageRef)
        if let ratio = selectedAspectRatio.numericValue, ratio > 0 {
            if let cropped = cropToAspectRatio(uiImage, ratio: ratio) {
                uiImage = cropped
            }
        }
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        DispatchQueue.main.async {
            self.capturedImages.insert(uiImage, at: 0)
            self.didCapturePhoto = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.didCapturePhoto = false
            }
        }
    }
    private func cropToAspectRatio(_ image: UIImage, ratio: CGFloat?) -> UIImage? {
        guard let ratio = ratio, ratio > 0 else { return image } 
        
        guard let cgImage = image.cgImage else { return nil }
        let w = CGFloat(cgImage.width)
        let h = CGFloat(cgImage.height)
        let currentRatio = w / h
        
        if abs(currentRatio - ratio) < 0.0001 { return image }
        
        let newWidth: CGFloat
        let newHeight: CGFloat
        
        if currentRatio > ratio {
            newWidth = h * ratio
            newHeight = h
        } else {
            newWidth = w
            newHeight = w / ratio
        }
        
        let x = (w - newWidth) / 2
        let y = (h - newHeight) / 2
        
        let cropRect = CGRect(x: x, y: y, width: newWidth, height: newHeight)
        guard let croppedCG = cgImage.cropping(to: cropRect) else { return image }
        
        return UIImage(cgImage: croppedCG)
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let currentTime = CACurrentMediaTime()
        if currentTime - lastAnalysisTime >= analysisInterval {
            lastAnalysisTime = currentTime
            analyzeSampleBuffer(sampleBuffer)
        }
        
        if let pb = CMSampleBufferGetImageBuffer(sampleBuffer) {
            lastCapturedPixelBuffer = pb
        }
    }
    private func analyzeSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let cgImage = pixelBuffer.toCGImage() else {
            return
        }
        Task {
            var newResults: [RegionResult] = []
            for i in 0..<9 {
                let regionKeys = Array(regionCoords.keys) 
                if i < regionKeys.count { 
                    let regionName = regionKeys[i] 
                    if let regionCG = cropRegionCGImage(region: regionName, from: cgImage) {
                        do {
                            let result = try await imageAnalyze.analyzeCGImage(image: regionCG)
                            let label = "Region: \(regionName)"
                            newResults.append(RegionResult(id: i, label: label, confidence: Double(result)))
                        } catch {
                            print("error: \(error.localizedDescription)")
                            newResults.append(RegionResult(id: i, label: "Error", confidence: 0.0))
                        }
                    }
                }
                
            }
            DispatchQueue.main.async {
                self.regionResults = newResults
            }
        }
    }
    private func cropRegionCGImage(region: String, from source: CGImage) -> CGImage? {
        let w = source.width
        let h = source.height
        let regionRect = boundingRectForRegion(region: region, imageWidth: w, imageHeight: h)
        return source.cropping(to: regionRect)
    }
}

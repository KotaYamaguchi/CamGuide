
import CoreImage
import AVFoundation

extension CVPixelBuffer {
    //  Convert CVPixelBuffer to CGImage
    func toCGImage() -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: self)
        let context = CIContext(options: nil)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}

extension CGImage {
    // Convert CGImage to CVPixelBuffer of specified size
    func toCVPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let pxBuffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pxBuffer, [])
        if let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pxBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pxBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) {
            context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        CVPixelBufferUnlockBaseAddress(pxBuffer, [])
        
        return pxBuffer
    }
}


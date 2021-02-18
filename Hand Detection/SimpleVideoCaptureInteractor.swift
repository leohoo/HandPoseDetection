//
//  SimpleVideoCaptureInteractor.swift
//  Hand Detection
//
//  Created by Wei Liu on 2021/02/09.
//

import Foundation

import AVKit

import Vision

final class SimpleVideoCaptureInteractor: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    private var captureDevice: AVCaptureDevice?
    @Published var showPhoto: Bool = false
    @Published var photoImage: UIImage?

    var pathLayer:CALayer? = nil

    /// - Tag: CreateCaptureSession
     func setupAVCaptureSession() {
         print(#function)
        captureSession.sessionPreset = .vga640x480
        
         if let availableDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first {
             captureDevice = availableDevice
         }

         do {
             let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice!)
             captureSession.addInput(captureDeviceInput)
         } catch let error {
             print(error.localizedDescription)
         }

         let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.name = "CameraPreview"
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.videoGravity = .resizeAspect
        previewLayer.backgroundColor = UIColor.black.cgColor
         self.previewLayer = previewLayer

         let dataOutput = AVCaptureVideoDataOutput()
         dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]

        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)

         if captureSession.canAddOutput(dataOutput) {
             captureSession.addOutput(dataOutput)
         }
         captureSession.commitConfiguration()
     }

    func startSettion() {
        if captureSession.isRunning { return }
        captureSession.startRunning()
    }

    func stopSettion() {
        if !captureSession.isRunning { return }
        captureSession.stopRunning()
    }

    func takePhoto() {
        showPhoto = true
    }

    private func exifOrientationForDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> UIImage.Orientation {

        switch deviceOrientation {
        case .portraitUpsideDown:
            return .rightMirrored

        case .landscapeLeft:
            return .downMirrored

        case .landscapeRight:
            return .upMirrored

        default:
            return .leftMirrored
        }
    }

    private func exifOrientationForCurrentDeviceOrientation() -> UIImage.Orientation {
        return exifOrientationForDeviceOrientation(UIDevice.current.orientation)
    }

    func pointLayer(_ p: CGPoint, in rect: CGRect) -> CALayer {
        let SIZE = CGFloat(5.0)
        let w = rect.width
        let h = rect.height

        let ox = p.y * w + rect.origin.x
        let oy = p.x * h + rect.origin.y
        let box = CGRect(x: ox - SIZE/2.0, y: oy - SIZE/2.0, width: SIZE, height: SIZE)

        let layer = CAShapeLayer()

        // Configure layer's appearance.
        layer.fillColor = nil // No fill to show boxed object
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.borderWidth = 2

        // Vary the line color according to input.
        layer.borderColor = UIColor.red.cgColor

        // Locate the layer.
        layer.anchorPoint = .zero
        layer.frame = box
        layer.masksToBounds = true

        // Transform the layer to have same coordinate system as the imageView underneath it.
//        layer.transform = CATransform3DMakeScale(1, -1, 1)

        return layer
    }

    func onResult(features:[[CGPoint]]) {
        self.requested = false

        self.pathLayer?.removeFromSuperlayer()

        if features.isEmpty {
            return
        }

        let fullImageWidth = CGFloat(480)
        let fullImageHeight = CGFloat(640)

        let imageFrame = (previewLayer?.frame)!
        let widthRatio = fullImageWidth / imageFrame.width
        let heightRatio = fullImageHeight / imageFrame.height

        // ScaleAspectFit: The image will be scaled down according to the stricter dimension.
        let scaleDownRatio = max(widthRatio, heightRatio)

        // Cache image dimensions to reference when drawing CALayer paths.
        let imageWidth = fullImageWidth / scaleDownRatio
        let imageHeight = fullImageHeight / scaleDownRatio

        // Prepare pathLayer to hold Vision results.
        let xLayer = (imageFrame.width - imageWidth) / 2
        let yLayer = imageFrame.minY + (imageFrame.height - imageHeight) / 2


        let drawingLayer = CALayer()
        drawingLayer.bounds = CGRect(x: xLayer, y: yLayer, width: imageWidth, height: imageHeight)
        drawingLayer.anchorPoint = CGPoint.zero
        drawingLayer.position = CGPoint(x: xLayer, y: yLayer)
        drawingLayer.opacity = 0.5
        pathLayer = drawingLayer

        previewLayer?.addSublayer(pathLayer!)
        pathLayer?.backgroundColor = UIColor.green.cgColor

        CATransaction.begin()
        for f in features {
            for p in f {
                let rect = pointLayer(p, in: drawingLayer.frame)

                pathLayer?.addSublayer(rect)
            }
        }
        CATransaction.commit()

    }

    var fr = FramerateCounter()
    lazy var detector = HandDetector(self.onResult)
    var requested = false
}


extension SimpleVideoCaptureInteractor: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print("framerate: \(fr.addFrame())")

        if requested {
            return
        }

        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()

            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))

            if let image = context.createCGImage(ciImage, from: imageRect) {
                detector.performVisionRequest(image: image)
                requested = true
            }
        }
    }
}

class HandDetector {

    var callback: ([[CGPoint]]) ->Void
    init(_ completion: @escaping ([[CGPoint]]) -> Void) {
        callback = completion
    }

    lazy var handPoseRequest = VNDetectHumanHandPoseRequest(completionHandler: self.handleHandPoses)

    private func handleHandPoses(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
//            self.presentAlert("Hand Pose Detection Error", error: nsError)
            print("error")
            self.callback([])

            return
        }
        // Since handlers are executing on a background thread, explicitly send draw calls to the main thread.
        DispatchQueue.main.async {

            guard let results = request?.results as? [VNHumanHandPoseObservation] else {
                self.callback([])
                return
            }

            var detectedFeatures = [[CGPoint]]()
            for r in results {
                let group = r.availableJointsGroupNames
                for g in group {
                    if g != VNHumanHandPoseObservation.JointsGroupName.all {
                        continue
                    }

                    var array = [CGPoint]()
                    if let points = try? r.recognizedPoints(g) {
                        var values = [VNRecognizedPoint]()
                        for p in points {
                            values.append(p.value)
                            print(p.value)
                            array.append(p.value.location)
                        }
                        detectedFeatures.append(array)
                        print("\(g.rawValue): \(values.count) points.")
                    }
                }

            }

            self.callback(detectedFeatures)
        }
    }

    fileprivate func performVisionRequest(image: CGImage) {

        var requests: [VNRequest] = [handPoseRequest]

        // Create a request handler.
        let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                        orientation: .up,
                                                        options: [:])

        // Send the requests to the request handler.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform(requests)
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")

                return
            }
        }
    }
}

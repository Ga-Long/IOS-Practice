//
//  CameraViewController.swift
//  ch14-ghlee-ImageClassifier
//
//  Created by 이가현 on 2023/06/05.
//

import UIKit

import AVKit
import Vision

class CameraViewController: UIViewController {

    var captureSession: AVCaptureSession!
    var vnCoreMLRequest: VNCoreMLRequest!
    var videoBufferSize = CGSize()
    var detectionOverlay: CALayer!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        vnCoreMLRequest = createCoreML(modelName: "SqueezeNet", modelExt: "mlmodelc", completionHandler: handleImageClassifier)
        //vnCoreMLRequest = createCoreML(modelName: "YOLOv3", modelExt: "mlmodelc", completionHandler: handleObjectDetection)
        //prepareObjectDetection()

        captureSession = AVCaptureSession()

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .medium

        // (1) VideoInput 디바이스 부착
        //선택된 device에 대한 AVCaptureDeviceInput 객체를 생성
        func createVideoInput() -> AVCaptureDeviceInput? {
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else{
                print("Not found input Device")
                return nil
            }
            
            return try? AVCaptureDeviceInput(device: device)
        }
        // (2) Previewer 설정
        // AVCaptureSession으로 부터 PreviewLayer 가져오고, 가져온 PreviewLayer을 적절한 UIView에 subLayer로 부착
        func attachPreviewer(captureSession: AVCaptureSession){
            
            let avCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            avCaptureVideoPreviewLayer.frame = previewImageView.layer.bounds
            avCaptureVideoPreviewLayer.videoGravity = .resize
            previewImageView.layer.addSublayer(avCaptureVideoPreviewLayer)
        }
        
        // (3) VideoOutput 디바이스 부착
        func createVideoOutput() -> AVCaptureVideoDataOutput? {
            
            let videoOutput = AVCaptureVideoDataOutput()
            let settings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)]
            
            videoOutput.videoSettings = settings
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
            videoOutput.connection(with: .video)?.videoOrientation = .portrait
            return videoOutput
        }


        captureSession.commitConfiguration()

        // 캡쳐링을 시작한다
        captureSession.startRunning()

        view.addGestureRecognizer(tapGestureRecognizer)



    }
    



}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate{

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

    // 여기서 이미지가 담겨져 온 sampleBuffer에 대한 처리를 하면된다.


    }
}



extension CameraViewController{
    
    func createCoreML(modelName: String, modelExt: String, completionHandler: @escaping (VNRequest, Error?) -> Void) -> VNCoreMLRequest?{
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: modelExt) else {
            return nil
        }
        guard let vnCoreMLModel = try? VNCoreMLModel(for: MLModel(contentsOf: modelURL)) else{
            return nil
        }
        return VNCoreMLRequest(model: vnCoreMLModel, completionHandler: completionHandler)
    }
}

extension CameraViewController{
    func handleImageClassifier(request: VNRequest, error: Error?){
        guard let results = request.results as? [VNClassificationObservation] else{ return }
        if let topResult = results.first{
            DispatchQueue.main.async {
                self.messageLabel.text = "\(topResult.identifier)입니다."
            }
        }
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        // 여기서 이미지가 담겨져 온 sampleBuffer에 대한 처리를 하면된다.
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let handler = VNImageRequestHandler(ciImage: ciImage)
        try! handler.perform([vnCoreMLRequest])

    }
}

extension CameraViewController{
    func prepareObjectDetection(){
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else{ return}

        do {
            try  device.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((device.activeFormat.formatDescription))
            videoBufferSize.width = CGFloat(dimensions.width)
            videoBufferSize.height = CGFloat(dimensions.height)
            device.unlockForConfiguration()
        } catch {
            return
        }

        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0, y: 0, width: videoBufferSize.width, height: videoBufferSize.height)
         detectionOverlay.position = CGPoint(x: detectionOverlay.bounds.midX, y: detectionOverlay.bounds.midY)
        view.layer.addSublayer(detectionOverlay)
    }
}

extension CameraViewController{
    func handleObjectDetection(request: VNRequest, error: Error?){

        guard let results = request.results else{ return }
        DispatchQueue.main.async {
            self.drawVisionRequestResults(results)
        }
    }
}

extension CameraViewController{
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()

        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        
        for observation in results{

            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }

            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(videoBufferSize.width), Int(videoBufferSize.height))

            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            let text = String(format: "\(topLabelObservation.identifier)\nconfidence:  %.2f", topLabelObservation.confidence)

            let textLayer = self.createTextSubLayerInBounds(objectBounds, text: text)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
        updateLayerGeometry()

        CATransaction.commit()
    }
}

extension CameraViewController{

    func createTextSubLayerInBounds(_ bounds: CGRect, text: String) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.foregroundColor = UIColor.blue.cgColor
        
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
}

extension CameraViewController{

    func createTextSubLayerInBounds(_ bounds: CGRect, text: String) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.foregroundColor = UIColor.blue.cgColor
        
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
}

import Vision

extension CameraViewController{
    
    func createCoreML(modelName: String, modelExt: String, completionHandler: @escaping (VNRequest, Error?) -> Void) -> VNCoreMLRequest?{
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: modelExt) else {
            return nil
        }
        guard let vnCoreMLModel = try? VNCoreMLModel(for: MLModel(contentsOf: modelURL)) else{
            return nil
        }
        return VNCoreMLRequest(model: vnCoreMLModel, completionHandler: completionHandler)
    }
}

extension CameraViewController{
    func handleImageClassifier(request: VNRequest, error: Error?){
        guard let results = request.results as? [VNClassificationObservation] else{ return }
        if let topResult = results.first{
            DispatchQueue.main.async {
                self.messageLabel.text = "\(topResult.identifier)입니다."
            }
        }
    }
}




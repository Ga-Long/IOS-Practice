//
//  ViewController.swift
//  ch14-ghlee-ImageClassifier
//
//  Created by 이가현 on 2023/06/05.
//

import UIKit
import AVKit
import Vision
import CoreML

class CameraAlbumViewController: UIViewController {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    var vnCoreMLRequest: VNCoreMLRequest!
    var captureSession: AVCaptureSession?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        vnCoreMLRequest = createCoreML(modelName: "SqueezeNet", modelExt: "mlmodelc", completionHandler: handleImageClassifier) // handler 완성되면 handleImageClassifier 함수 호출

    }

    @IBAction func takePicture(_ sender: UIButton) {
        // 컨트로러를 생성한다
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self // 이 딜리게이터를 설정하면 사진을 찍은후 호출된다
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) { //앨범 가져오기
            imagePickerController.sourceType = .photoLibrary
        }else{
            imagePickerController.sourceType = .camera
        }
        
        // UIImagePickerController이 활성화 된다, 11장을 보라
        present(imagePickerController, animated: true, completion: nil)
    }
    
}

// coreML 객체 생성
extension CameraAlbumViewController{
    func createCoreML(modelName: String, modelExt: String, completionHandler: @escaping (VNRequest, Error?) -> Void) -> VNCoreMLRequest?{
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: modelExt) else {
            print("modelURL: nill")
            return nil
        }
        guard let vnCoreMLModel = try? VNCoreMLModel(for: MLModel(contentsOf: modelURL)) else{
            print("vnCoreMLModel: nill")

            return nil
        }
        // VNCoreMLRequest를 생성하면서 completionHandler를 매개변수로 전달
        return VNCoreMLRequest(model: vnCoreMLModel, completionHandler: completionHandler)
    }
    
    // 모델 가지고 온 후 
    func handleImageClassifier(request: VNRequest, error: Error?){
        guard let results = request.results as? [VNClassificationObservation] else{ return }
        if let topResult = results.first{
            DispatchQueue.main.async {
                self.messageLabel.text = "\(topResult.confidence) 확률로 \(topResult.identifier)입니다."
                print("\(topResult.confidence) 확률로 \(topResult.identifier)입니다.")
            }
        }
    }

}


extension CameraAlbumViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // 여기서 이미지가 담겨져 온 sampleBuffer에 대한 처리를 하면된다.
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let handler = VNImageRequestHandler(ciImage: ciImage)
        try! handler.perform([vnCoreMLRequest])
        
    }
    // (2) Previewer 설정
    // AVCaptureSession으로 부터 PreviewLayer 가져오고, 가져온 PreviewLayer을 적절한 UIView에 subLayer로 부착
    func attachPreviewer(captureSession: AVCaptureSession){
        
        let avCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        avCaptureVideoPreviewLayer.frame = imageView.layer.bounds
        avCaptureVideoPreviewLayer.videoGravity = .resize
        imageView.layer.addSublayer(avCaptureVideoPreviewLayer)
    }
    
}


extension CameraAlbumViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    
    // 사진을 찍은 경우 호출되는 함수
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
 
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
            
            let handler = VNImageRequestHandler(ciImage: CIImage(image:image)!)
            // Core ML 모델에 이미지를 전달 후 결과 처리
            try! handler.perform([vnCoreMLRequest])
            
        }
        picker.dismiss(animated: true, completion: nil)
    }

    // 사진 캡쳐를 취소하는 경우 호출 함수
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // imagePickerController을 죽인다
        picker.dismiss(animated: true, completion: nil)
    }
}



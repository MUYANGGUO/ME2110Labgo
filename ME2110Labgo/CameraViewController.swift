//
//  CameraViewController.swift
//  ME2110Labgo
//
//  Created by Muyang on 6/27/18.
//  Copyright © 2018 Muyang. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import Vision
import FirebaseMLVision

struct ImageDisplay {
    let file: String
    let name: String
}

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UIPickerViewDelegate, UINavigationControllerDelegate {

    //possibly go wrong here with var setting

    var textDetector: VisionTextDetector!

    @IBOutlet weak var IDnumber: UITextField!
    
    
    var frameSublayer = CALayer()
    @IBAction func dimissbutton(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBOutlet weak var imageView: UIImageView!


    
    var model: VNCoreMLModel!
    
    var textMetadata = [Int: [Int: String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textDetector = Vision().textDetector()
        imageView.layer.addSublayer(frameSublayer)
        
        // Add the background gradient
        view.addVerticalGradientLayer(topColor: primaryColor, bottomColor: secondaryColor)
        loadModel()

    }
    private func loadModel() {
        model = try? VNCoreMLModel(for: Alphanum_28x28().model)
    }
    
    
    
    @IBAction func findTextDidTouch(_ sender: UIButton) {
        runTextRecognition(with: imageView.image!)
    }
    
    func runTextRecognition(with image: UIImage) {
        let visionImage = VisionImage(image: image)
        textDetector.detect(in: visionImage) { features, error in
            self.processResult(from: features, error: error)
            
        }
    }
    
    func processResult(from text: [VisionText]?, error: Error?) {
        removeFrames()
        guard let features = text, let image = imageView.image else {
            return
        }
        for text in features {
            if let block = text as? VisionTextBlock {
                for line in block.lines {
                    for element in line.elements {
                        self.addFrameView(
                            featureFrame: element.frame,
                            imageSize: image.size,
                            viewFrame: self.imageView.frame,
                            text: element.text
                            
                        )
                    }
                }
            }
        }
    }
    var idnumberdigits: String = ""
    private func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect, text: String? = nil) {
        print("Frame: \(featureFrame).")
        print("ImageSize \(imageSize).")
        print("ViewFrame \(viewFrame).")
        guard let idnumber = text else{return}
        
        let idnumbertext = idnumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
        idnumberdigits += idnumbertext
        print(idnumbertext)
        IDnumber.text = idnumberdigits
        
        let viewSize = viewFrame.size
        
        // Find resolution for the view and image
        let rView = viewSize.width / viewSize.height
        let rImage = imageSize.width / imageSize.height
        
        // Define scale based on comparing resolutions
        var scale: CGFloat
        if rView > rImage {
            scale = viewSize.height / imageSize.height
        } else {
            scale = viewSize.width / imageSize.width
        }
        
        // Calculate scaled feature frame size
        let featureWidthScaled = featureFrame.size.width * scale
        let featureHeightScaled = featureFrame.size.height * scale
        
        // Calculate scaled feature frame top-left point
        let imageWidthScaled = imageSize.width * scale
        let imageHeightScaled = imageSize.height * scale
        
        let imagePointXScaled = (viewSize.width - imageWidthScaled) / 2
        let imagePointYScaled = (viewSize.height - imageHeightScaled) / 2
        
        let featurePointXScaled = imagePointXScaled + featureFrame.origin.x * scale
        let featurePointYScaled = imagePointYScaled + featureFrame.origin.y * scale
        
        // Define a rect for scaled feature frame
        let featureRectScaled = CGRect(x: featurePointXScaled,
                                       y: featurePointYScaled,
                                       width: featureWidthScaled,
                                       height: featureHeightScaled)
      /////////////////////////////////////////////////////
      /////////////////////////////////////////////////////
        //drawFrame(featureRectScaled, text: text)
    }
    
    /// Creates and draws a frame for the calculated rect as a sublayer.
    ///
    /// - Parameter rect: The rect to draw.
    private func drawFrame(_ rect: CGRect, text: String? = nil) {
        let bpath: UIBezierPath = UIBezierPath(rect: rect)
        let rectLayer: CAShapeLayer = CAShapeLayer()
        rectLayer.path = bpath.cgPath
        rectLayer.strokeColor = Constants.lineColor
        rectLayer.fillColor = Constants.fillColor
        rectLayer.lineWidth = Constants.lineWidth
        if let text = text {
            let textLayer = CATextLayer()
            textLayer.string = text
            textLayer.fontSize = 12.0
            textLayer.foregroundColor = Constants.lineColor
            let center = CGPoint(x: rect.midX, y: rect.midY)
            textLayer.position = center
            textLayer.frame = rect
            textLayer.alignmentMode = kCAAlignmentCenter
            textLayer.contentsScale = UIScreen.main.scale
            frameSublayer.addSublayer(textLayer)
        }
        frameSublayer.addSublayer(rectLayer)
    }
    
    private func removeFrames() {
        guard let sublayers = frameSublayer.sublayers else { return }
        for sublayer in sublayers {
            guard let frameLayer = sublayer as CALayer? else {
                print("Failed to remove frame layer.")
                continue
            }
            frameLayer.removeFromSuperlayer()
        }
    }
    
    func detectorOrientation(in image: UIImage) -> VisionDetectorImageOrientation {
        switch image.imageOrientation {
        case .up:
            return .topLeft
        case .down:
            return .bottomRight
        case .left:
            return .leftBottom
        case .right:
            return .rightTop
        case .upMirrored:
            return .topRight
        case .downMirrored:
            return .bottomLeft
        case .leftMirrored:
            return .leftTop
        case .rightMirrored:
            return .rightBottom
        }
    }
    
  

    
    
    @IBAction func scan(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        IDnumber.text = ""
        idnumberdigits = ""
        //action sheet set up
        let actionSheet = UIAlertController(title: "Scan your ID", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {(action:UIAlertAction)in
            if UIImagePickerController.isSourceTypeAvailable(.camera){
                imagePickerController.sourceType = .camera
                
                self.present(imagePickerController, animated: true,completion: nil)}
            else{
                print("camera not available")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Album", style: .default, handler: {(action:UIAlertAction)in imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true,completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        self.present(actionSheet,animated: true,completion: nil)
        
        
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Couldn't load image")
        }
        
        self.imageView.image = image
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.runTextRecognition(with: image)
                    }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
  
    // MARK: private
   
    
    fileprivate enum Constants {
        static let lineWidth: CGFloat = 3.0
        static let lineColor = UIColor.green.cgColor
        static let fillColor = UIColor.clear.cgColor
    
}
}

//
//  ViewController.swift
//  coreMLDemo
//
//  Created by mac on 11/29/18.
//  Copyright © 2018 mac. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UINavigationControllerDelegate {

    @IBOutlet weak var imageRecognizeLabel: UILabel!
    @IBOutlet weak var capturedImageView: UIImageView!
    
    // creating model object to acces the model of inceptionV3
    var model: Inceptionv3!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        model = Inceptionv3()
    }
    
    //MARK:- UIButton Actions
    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        present(cameraPicker,animated: true)
    }
    @IBAction func fetchGallery(_ sender: UIBarButtonItem) {
        let galleryPicker = UIImagePickerController()
        galleryPicker.delegate = self
        galleryPicker.allowsEditing = false
        galleryPicker.sourceType = .photoLibrary
        present(galleryPicker, animated: true)
    }
}

extension ViewController: UIImagePickerControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        
        // Retrieve the selected image from the info dictionary.
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        
        // We convert the image into a square 299*299 because Inceptionv3 model support image of this resolution.
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Convert newImage into CVPixelBuffer
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        // Convert all data in CGContext and make translating and saving the image.
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        // Render the image from context.
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        capturedImageView.image = newImage
        
        // for making prediction of what object is use 'model.prediction' here
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {return}
        imageRecognizeLabel.text = "I think this can be \(prediction.classLabel) "
    }
    
}

//
//  CameraViewModel.swift
//  eva_camera
//
//  Created by Mac Pro on 28.07.2023.
//

import Foundation
import AVFoundation
import UIKit
import Photos

class CameraViewModel: NSObject {
    
    var captureSession: AVCaptureSession = AVCaptureSession()
    private var currentDevice: AVCaptureDevice!
    private var videoOutput: AVCaptureMovieFileOutput!
    
    private var photoCompletion: ((Result<UIImage, Error>) -> Void)?
    private var videoCompletion: ((Result<URL, Error>) -> Void)?
    
    func setupCaptureSession(for view: UIView) {
        
        captureSession.sessionPreset = .high
        
        let videoDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices
        
        currentDevice = videoDevices.first
        
        do {
            let inputDevice = try AVCaptureDeviceInput(device: currentDevice!)
            guard captureSession.canAddInput(inputDevice) else {
                print("Error: Could not add input device to the capture session.")
                return
            }
            
            let captureOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(captureOutput) {
                captureSession.addOutput(captureOutput)
            }
            
            videoOutput = AVCaptureMovieFileOutput()
            if captureSession.canAddOutput(videoOutput!) {
                captureSession.addOutput(videoOutput!)
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
            
        } catch {
            print("Error setting up capture session: \(error.localizedDescription)")
        }
    }
    
    func switchCamera() {
        
        if let currentInput = captureSession.inputs.first {
            captureSession.removeInput(currentInput)
        }
        
        if currentDevice?.position == .back {
            currentDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        } else {
            currentDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
        
        do {
            let inputDevice = try AVCaptureDeviceInput(device: currentDevice!)
            if captureSession.canAddInput(inputDevice) {
                captureSession.addInput(inputDevice)
            }
        } catch {
            print("Error switching camera: \(error.localizedDescription)")
        }
    }
    
    func takePhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
           guard let captureOutput = captureSession.outputs.first as? AVCapturePhotoOutput else {
               completion(.failure(NSError(domain: "Capture session not set up properly.", code: -1, userInfo: nil)))
               return
           }

        var photoSettings = AVCapturePhotoSettings()
           if captureOutput.availablePhotoCodecTypes.contains(.jpeg) {
             
               photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
           }
           
           captureOutput.capturePhoto(with: photoSettings, delegate: self)
           self.photoCompletion = completion
       }
        
        func startRecordingVideo(completion: @escaping (Result<URL, Error>) -> Void) {
            guard let videoOutput = videoOutput else {
                completion(.failure(NSError(domain: "Capture session not set up properly.", code: -1, userInfo: nil)))
                return
            }
            
            let outputURL = getOutputURL()
            videoOutput.startRecording(to: outputURL, recordingDelegate: self)
            self.videoCompletion = completion
        }
    
    func stopRecording(completion: @escaping (Error?) -> Void) {
        guard self.captureSession.isRunning else {
            return
        }
        self.videoOutput.stopRecording()
    }

        private func getOutputURL() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let id = Int.random(in: 0...1000)
            let outputURL = paths[0].appendingPathComponent("\(id).mp4")
            try? FileManager.default.removeItem(at: outputURL)
            return outputURL
        }
    }

extension CameraViewModel: AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate  {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
            }) { saved, error in
                if saved {
                 //
                }
            }
        } else {
        }
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let image = UIImage(data: imageData) else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
    
}

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

class CameraViewModel: NSObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    
    var captureSession: AVCaptureSession?
    private var currentDevice: AVCaptureDevice?
    private var videoOutput: AVCaptureMovieFileOutput?
    
    private var photoCompletion: ((Result<UIImage, Error>) -> Void)?
    private var videoCompletion: ((Result<URL, Error>) -> Void)?
    
    func setupCaptureSession(for view: UIView) {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        
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
                captureSession.startRunning()
            }
            
        } catch {
            print("Error setting up capture session: \(error.localizedDescription)")
        }
    }
    
    func switchCamera() {
        guard let captureSession = captureSession else { return }
        
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
    
    func capturePhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
           guard let captureSession = captureSession,
                 let captureOutput = captureSession.outputs.first as? AVCapturePhotoOutput else {
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
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                         didFinishProcessingPhoto photo: AVCapturePhoto,
                         error: Error?) {
            if let error = error {
                photoCompletion?(.failure(error))
                return
            }

            if let imageData = photo.fileDataRepresentation(),
               let image = UIImage(data: imageData) {
                photoCompletion?(.success(image))
            } else {
                photoCompletion?(.failure(NSError(domain: "Error converting photo data to UIImage.", code: -1, userInfo: nil)))
            }
        }
        
        
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            if let error = error {
                videoCompletion?(.failure(error))
                return
            }
            
            videoCompletion?(.success(outputFileURL))
        }
        
        private func getOutputURL() -> URL {
            let tempDir = NSTemporaryDirectory()
            let fileName = "video_\(Date().timeIntervalSince1970).mov"
            let outputURL = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)
            return outputURL
        }
        
        func savePhotoToGallery(image: UIImage) {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    print("Photo saved to gallery successfully.")
                } else if let error = error {
                    print("Error saving photo to gallery: \(error)")
                } else {
                    print("Unknown error while saving photo to gallery.")
                }
            }
        }
        
        func stopRecordingVideo(completion: @escaping (Result<URL, Error>) -> Void) {
            guard let videoOutput = videoOutput else {
                completion(.failure(NSError(domain: "Capture session not set up properly.", code: -1, userInfo: nil)))
                return
            }
            
            videoOutput.stopRecording()
            self.videoCompletion = completion
        }
        
        func saveVideoToGallery(videoURL: URL) {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if success {
                    print("Video saved to gallery successfully.")
                } else if let error = error {
                    print("Error saving video to gallery: \(error)")
                } else {
                    print("Unknown error while saving video to gallery.")
                }
            }
        }
    }
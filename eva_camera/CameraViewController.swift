//
//  CameraViewController.swift
//  eva_camera
//
//  Created by Mac Pro on 28.07.2023.
//

import UIKit
import AVFoundation
import Photos
import CameraButton

class CameraViewController: UIViewController, CameraButtonDelegate {
    
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var cameraSwitchButton: UIButton!
    
    let viewModel = CameraViewModel()
    let button = CameraButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCameraPreview()
        viewModel.setupCaptureSession(for: cameraPreviewView)
        prepareUI()
    }
    

    
    
    func setupCameraPreview() {
        guard let captureSession = viewModel.captureSession else {
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = cameraPreviewView.bounds
        cameraPreviewView.layer.addSublayer(previewLayer)
    }

    
    func prepareUI() {
        button.delegate = self
        
        view.addSubview(button)
        view.addSubview(cameraSwitchButton)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 72),
            button.heightAnchor.constraint(equalToConstant: 72),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -64)
        ])
        
        button.borderColor = .red
        button.fillColor = (.purple, .orange)
        button.progressColor = .green
        button.progressDuration = 5
        
        cameraSwitchButton.tintColor = .black
    }
    
    func didTap(_ button: CameraButton) {
        if !button.isRecording {
            button.stop()
            viewModel.capturePhoto { (result: Result<UIImage, Error>) in
                switch result {
                case .success(let image):
                    self.viewModel.savePhotoToGallery(image: image)
                case .failure(let error):
                    print("Error capturing photo: \(error)")
                }
            }
        } else if button.isRecording {
            button.start()
            viewModel.startRecordingVideo { (result: Result<URL, Error>) in
                switch result {
                case .success(let url):
                    self.viewModel.saveVideoToGallery(videoURL: url)
                case .failure(let error):
                    print("Error recording video: \(error)")
                }
            }
        }
    }
    
    func didRelease(_ button: CameraButton) {
        if button.isRecording {
            viewModel.stopRecordingVideo { [weak self] (result: Result<URL, Error>) in
                switch result {
                case .success(let url):
                    self?.viewModel.saveVideoToGallery(videoURL: url)
                case .failure(let error):
                    print("Error stopping video recording: \(error)")
                }
            }
        }
    }
    
    
    func didFinishProgress() {
        didRelease(button)
    }
    
    @IBAction func switchCameraAction(_ sender: Any) {
        viewModel.switchCamera()
    }
    
}

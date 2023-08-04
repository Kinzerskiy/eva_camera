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
        prepareUI()
    }
    
    
    func setupCameraPreview() {
        viewModel.setupCaptureSession(for: cameraPreviewView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        cameraPreviewView.frame = self.view.frame
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
            viewModel.takePhoto { [weak self] result  in
                
                guard let self = self else { return }
                
                switch result {
                case .success:
                    let alertController = UIAlertController(title: "Your photo was successfully saved", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    DispatchQueue.main.async {
                        self.present(alertController, animated: true, completion: nil)
                    }
                case .failure(let error):
                    print("Error starting recording: \(error.localizedDescription)")
                }
                
            }
            
            
        } else if button.isRecording {
            button.start()
            
            viewModel.startRecordingVideo { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    button.stop()
                    viewModel.stopRecording { error in
                        print("Error stoping recording: \(String(describing: error?.localizedDescription))")
                    }
                    let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    DispatchQueue.main.async {
                        self.present(alertController, animated: true, completion: nil)
                    }
                case .failure(let error):
                    print("Error starting recording: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func didFinishProgress() {
      
    }
    
    @IBAction func switchCameraAction(_ sender: Any) {
        viewModel.switchCamera()
    }
    
}

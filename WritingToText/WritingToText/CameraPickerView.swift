import SwiftUI
import AVFoundation

// Camera View Representable for SwiftUI
struct CameraPickerView: UIViewControllerRepresentable {
    var didTakePicture: (UIImage) -> Void
    //@Environment(\.dismiss) private var dismiss // Access dismiss environment action
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraPickerView
        var session: AVCaptureSession?
        var photoOutput: AVCapturePhotoOutput?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var captureButton: UIButton?
        
        init(parent: CameraPickerView) {
            self.parent = parent
        }
        
        func startSession(in view: UIView) {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                self.session = AVCaptureSession()
                
                guard let session = self.session else { return }
                
                // Setup camera input
                guard let videoDevice = AVCaptureDevice.default(for: .video),
                      let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                      session.canAddInput(videoDeviceInput) else { return }
                
                session.addInput(videoDeviceInput)
                
                // Setup photo output
                self.photoOutput = AVCapturePhotoOutput()
                guard let photoOutput = self.photoOutput, session.canAddOutput(photoOutput) else { return }
                session.addOutput(photoOutput)
                
                // Start the session
                session.startRunning()
                
                // Add the preview layer to the view on the main thread
                DispatchQueue.main.async {
                    self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
                    self.previewLayer?.videoGravity = .resizeAspectFill
                    self.previewLayer?.frame = view.bounds
                    if let previewLayer = self.previewLayer {
                        view.layer.insertSublayer(previewLayer, at: 0) // Insert at the bottom of the layer stack
                    }
                }
            }
        }


        // Capture photo
        @objc func capturePhoto() {
            guard let photoOutput = photoOutput else { return }
            let photoSettings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
        
        // Stop the session
        func stopSession() {
            session?.stopRunning()
        }
        
        // Delegate method to process captured photo
        func photoOutput(_ photoOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            //print("works")
            if let error = error {
                print("Error capturing photo: \(error.localizedDescription)")
                return
            }
            if let imageData = photo.fileDataRepresentation(),
               let image = UIImage(data: imageData) {
                parent.didTakePicture(image) // Pass image back to parent
                //print(parent.didTakePicture)
                self.stopSession()
                
                DispatchQueue.main.async {
                    //self.parent.dismiss() // Call back to SwiftUI to dismiss the view
                }
            }
            else { print("Error saving photos")}
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        // Start the camera session
        context.coordinator.startSession(in: viewController.view)
        
        // Add the preview layer first
        if let previewLayer = context.coordinator.previewLayer {
            viewController.view.layer.addSublayer(previewLayer)
        }
        
        // Add a button to capture the photo
        let captureButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width / 2 - 35, y: UIScreen.main.bounds.height - 100, width: 70, height: 70))
        captureButton.layer.cornerRadius = 35
        captureButton.backgroundColor = .white
        captureButton.addTarget(context.coordinator, action: #selector(Coordinator.capturePhoto), for: .touchUpInside)
        viewController.view.addSubview(captureButton)
        viewController.view.bringSubviewToFront(captureButton)
        context.coordinator.captureButton = captureButton
        
        return viewController
    }

    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates required
    }
}

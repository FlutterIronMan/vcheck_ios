//
//  VideoUploadViewController.swift
//  VcheckSDKDemoIOS
//
//  Created by Kirill Kaun on 10.05.2022.
//

import Foundation
import UIKit
import CoreMedia
import AVKit
import Photos

class VideoProcessingViewController: UIViewController {
    
    private let viewModel = VideoProcessingViewModel()
    
    var livenessVC: LivenessScreenViewController? = nil
    
    @IBOutlet weak var videoProcessingIndicator: UIActivityIndicatorView!
        
    var videoFileURL: URL?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoProcessingIndicator.isHidden = false
        
        let token = VCheckSDK.shared.getVerificationToken()
        
        viewModel.didUploadVideoResponse = {
            if (self.viewModel.uploadedVideoResponse != nil) {
                print("DATA: \(String(describing: self.viewModel.uploadedVideoResponse))")
                if (statusCodeToLivenessChallengeStatus(code: self.viewModel.uploadedVideoResponse!.status!)
                        == LivenessChallengeStatus.FAIL) {
                    if (self.viewModel.uploadedVideoResponse!.reason != nil
                        && !self.viewModel.uploadedVideoResponse!.reason!.isEmpty) {
                        self.onBackendObstacleMet(reason: strCodeToLivenessFailureReason(
                            strCode: (self.viewModel.uploadedVideoResponse?.reason!)!))
                    } else {
                        self.livenessSuccessAction()
                    }
                } else {
                    self.livenessSuccessAction()
                }
            }
        }
        
        viewModel.showAlertClosure = {
            if (self.viewModel.error?.errorCode == 400) {
                self.livenessSuccessAction()
            } else {
                self.performSegue(withIdentifier: "VideoUploadToFailure", sender: nil)
            }
        }
        
        if (!token.isEmpty && videoFileURL != nil) {
            uploadVideo()
        } else {
            //FOR TESTS
            //if (videoFileURL != nil) {
                print("VCheckSDK - Error: TOKEN/VIDEO FILE IS NIL")
                //VIDEO FILE SIZE: \(String(describing: self.viewModel.fileSize(forURL: videoFileURL))) MB")
                //playLivenessVideoPreview()
            //}
        }
    }
    
    func onBackendObstacleMet(reason: LivenessFailureReason) {
        switch(reason) {
            case LivenessFailureReason.FACE_NOT_FOUND:
                self.performSegue(withIdentifier: "InProcessToLookStraight", sender: nil)
            case LivenessFailureReason.MULTIPLE_FACES:
                self.performSegue(withIdentifier: "InProcessToObstacles", sender: nil)
            case LivenessFailureReason.FAST_MOVEMENT:
                self.performSegue(withIdentifier: "InProcessToSharpMovement", sender: nil)
            case LivenessFailureReason.TOO_DARK:
                self.performSegue(withIdentifier: "InProcessToTooDark", sender: nil)
            case LivenessFailureReason.INVALID_MOVEMENTS:
                self.performSegue(withIdentifier: "InProcessToWrongGesture", sender: nil)
            case LivenessFailureReason.UNKNOWN:
                self.performSegue(withIdentifier: "InProcessToObstacles", sender: nil)
        }
    }
    
    //TODO: TEST!
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "InProcessToLookStraight") {
            let vc = segue.destination as! NoFaceDetectedViewController
            vc.onRepeatBlock = { result in
                self.navigationController?.popViewController(animated: false)
                self.livenessVC?.renewLivenessSessionOnRetry()
            }
        }
        if (segue.identifier == "InProcessToObstacles") {
            let vc = segue.destination as! MultipleFacesDetectedViewController
            vc.onRepeatBlock = { result in
                self.navigationController?.popViewController(animated: false)
                self.livenessVC?.renewLivenessSessionOnRetry()
            }
        }
        if (segue.identifier == "InProcessToSharpMovement") {
            let vc = segue.destination as! SharpMovementsViewController
            vc.onRepeatBlock = { result in
                self.navigationController?.popViewController(animated: false)
                self.livenessVC?.renewLivenessSessionOnRetry()
            }
        }
        if (segue.identifier == "InProcessToTooDark") {
            let vc = segue.destination as! NoBrightnessViewController
            vc.onRepeatBlock = { result in
                self.navigationController?.popViewController(animated: false)
                self.livenessVC?.renewLivenessSessionOnRetry()
            }
        }
        if (segue.identifier == "InProcessToWrongGesture") {
            let vc = segue.destination as! WrongGestureViewController
            vc.onRepeatBlock = { result in
                self.navigationController?.popViewController(animated: false)
                self.livenessVC?.renewLivenessSessionOnRetry()
            }
        }
        if (segue.identifier == "VideoUploadToFailure") {
            let vc = segue.destination as! VideoFailureViewController
            vc.videoProcessingViewController = self
        }
    }
    
    func livenessSuccessAction() {
        self.viewModel.didReceivedCurrentStage = {
            if (self.viewModel.currentStageResponse?.errorCode != nil && self.viewModel.currentStageResponse?.errorCode == StageObstacleErrorType.USER_INTERACTED_COMPLETED.toTypeIdx()) {
                VCheckSDK.shared.onFinish()
            } else {
                self.showToast(message: "Stage Error", seconds: 3.0)
            }
        }
        self.viewModel.getCurrentStage()
    }
    
    func uploadVideo() {
        viewModel.uploadVideo(videoFileURL: videoFileURL!)
    }
    
    
   // FOR TESTS ONLY
//    func playLivenessVideoPreview() {
//        //let videoURL = URL.init(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
//
//        let playerController = AVPlayerViewController()
//        let player = AVPlayer(url: self.videoFileURL!)
//        playerController.player = player
//
//        self.addChild(playerController)
//        playerController.view.frame = self.view.frame
//        self.view.addSubview(playerController.view)
//
//        player.play()
//
//        //ONLY FOR TESTS:
////        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [unowned self] (status) in
////            DispatchQueue.main.async { [unowned self] in
////                saveVideoToGallery(url: self.videoFileURL!)
////            }
////        }
//     }
    
    
    //TODO: only for tests; remove
//    private func saveVideoToGallery(url: URL) {
//        PHPhotoLibrary.shared().performChanges({
//            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
//        }) { saved, error in
//            if saved {
//                let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
//                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
//                alertController.addAction(defaultAction)
//                self.present(alertController, animated: true, completion: nil)
//            }
//        }
//    }
}

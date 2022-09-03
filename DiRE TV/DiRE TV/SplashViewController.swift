//
//  SplashViewController.swift
//  DiRE TV
//
//  Created by ARUN PRASATH on 31/08/22.
//

import UIKit
import AVKit
import AVFoundation

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        playVideo()
      
    }
    
    private func playVideo() {
        let path = Bundle.main.path(forResource: "splash_background", ofType: "mp4")!
        let videoURL = URL(fileURLWithPath: path)
        let player = AVPlayer(url: videoURL)
        NotificationCenter.default
            .addObserver(self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        self.view.layer.addSublayer(playerLayer)
        player.play()
    }
    
   @objc func playerDidFinishPlaying(_ note: NSNotification) {
       self.performSegue(withIdentifier: "gotoapp", sender: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
           let menuPressRecognizer = UITapGestureRecognizer()
           menuPressRecognizer.addTarget(self, action: #selector(self.menuButtonAction(recognizer:)))
        menuPressRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
           self.view.addGestureRecognizer(menuPressRecognizer)
    }
    
    @objc func menuButtonAction(recognizer:UITapGestureRecognizer) {
        exit(EXIT_SUCCESS)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoapp" {
            if let nextViewController = segue.destination as? AppViewController {
                nextViewController.getVideos(completion: { (videos) in
                    DispatchQueue.main.async {
                        nextViewController.videosList = videos
                        nextViewController.playerIndex = 0
                        nextViewController.playVideoUrl()
                    }
                })
            }
        }
    }

    
    
    
    

}

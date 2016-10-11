//
//  LibraryViewController.swift
//  SloMoVideo
//
//  Created by amir sankar on 10/7/16.
//  Copyright © 2016 amir sankar. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit
import Photos
import UIKit

class LibraryViewController: UIViewController {
    
    var dataManager = DAO.dataManager
    @IBOutlet var collectionView: UICollectionView!
    var emptyAlert = UIView()
  
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector:#selector(recieveNotification), name: NSNotification.Name(rawValue: "refresh"), object: nil)
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        let mainBundle = Bundle.main
        self.emptyAlert = mainBundle.loadNibNamed("EmptyView", owner: self, options:nil)?[0] as! UIView
        self.emptyAlert.frame = CGRect(x: self.view.center.x - 150, y: self.view.center.y - 150, width: 300, height: 250)
           
        if self.dataManager.videos.count == 0 {
            self.collectionView.isHidden = true
            self.navigationController?.isToolbarHidden = true
            self.emptyAlert.isHidden = false
            
            DispatchQueue.main.async(execute: {
                self.view.addSubview(self.emptyAlert)
            })
            
        } else {
            self.navigationController?.isToolbarHidden = false
            DispatchQueue.main.async(execute: {
                self.emptyAlert.isHidden = true
                self.collectionView.isHidden = false
                self.view.setNeedsDisplay()
            })
        }
    }
    
    
    
    override var prefersStatusBarHidden : Bool {
        return true
    }

    
    
    func recieveNotification(_ notification:Notification) {
        if notification.name == "refresh" {
            
            DispatchQueue.main.async(execute: {
                self.emptyAlert.isHidden = true
                self.collectionView.reloadData()
                UIApplication.shared.endIgnoringInteractionEvents()
                self.tabBarController?.selectedIndex = 0
            })
        }
    }
    
    
}


//Extension for UICollectionViewDataSource delegate methods


extension LibraryViewController : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       return self.dataManager.videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! movieCell
        
        let currentVideo = self.dataManager.videos[(indexPath as NSIndexPath).row]
        cell.imageView.image = currentVideo.thumbnail
        
        return cell
    }
}


//Extension for UICollectionViewDelegate delegate methods


extension LibraryViewController : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        

        let currentVideo = self.dataManager.videos[(indexPath as NSIndexPath).row]
        let currentPlayerItem = AVPlayerItem(asset: currentVideo.asset)
        if currentPlayerItem.canPlaySlowForward {
            print("YES GOOD")
        }
        let player = AVPlayer(url: currentVideo.assetURL as URL)
        player.allowsExternalPlayback = false
        
        
        //DO I NEED PLAYER ITEM>? 
        //SOME WEIRD GLITCHES IN VIDEOS
        //TRY TO MAKE FRAME RATE OF RECORDING HIGHER
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        present(playerViewController, animated: true) {
            player.rate = 0.2
            playerViewController.player!.play()
            player.rate = 0.2
        }
    }
}



//custom collectionviewcell class


class movieCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    
    
}








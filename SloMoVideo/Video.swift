//
//  Video.swift
//  SloMoVideo
//
//  Created by amir sankar on 10/10/16.
//  Copyright © 2016 amir sankar. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class Video {
    
    var asset : AVAsset
    var thumbnail : UIImage?
    var assetURL: URL
    
    init(fromURL: URL){
        self.asset = AVAsset(url: fromURL)
        self.assetURL = fromURL
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let imageRef = try imageGenerator.copyCGImage(at: kCMTimeZero,
                                                                actualTime: nil)
            let image = UIImage(cgImage: imageRef)
            self.thumbnail = image
            
        } catch {
            print("Error generating image: \(error)")
        }

    }

}



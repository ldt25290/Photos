//
//  PhotoAlbumCell.swift
//  JHPhotos
//
//  Created by winter on 2017/6/29.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit
import Photos

class PhotoAlbum: NSObject {
    var asset: PHAsset!
    var isSelected = false
    var canSelected = false
    
    init(_ a: PHAsset) {
        self.asset = a
    }
}

class PhotoAlbumCell: UICollectionViewCell {
    
    typealias resultBlock = (_ obj: PhotoAlbum?) -> Void
    // MARK: - private
    fileprivate var block: (resultBlock)?
    fileprivate var model: PhotoAlbum!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var button: UIButton!
    
    @IBAction func buttonAction(_ sender: UIButton) {
        if model.canSelected {
            sender.isSelected = !sender.isSelected
            model.isSelected = !model.isSelected
            block?(model)
        }
        else { block?(nil) }
    }
    
    // MARK: - public
    
    func setPhotoAlbum(_ model: PhotoAlbum, selectBlock: resultBlock?) {
        self.model = model
        self.block = selectBlock
        self.coverView.isHidden = model.canSelected
        self.button.isSelected = model.isSelected
        
        PhotoAlbumTool.requestImage(for: model.asset,
                                    size: self.imageView.frame.size,
                                    resizeMode: .exact,
                                    contentMode: .aspectFill) { [unowned self] (image) in
                                        self.imageView.image = image
                                    }
    }
}
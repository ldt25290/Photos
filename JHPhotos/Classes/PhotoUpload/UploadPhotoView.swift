//
//  UploadPhotoView.swift
//  JHPhotos
//
//  Created by winter on 2017/6/30.
//  Copyright © 2017年 DJ. All rights reserved.
//

import UIKit

public final class UploadPhotoView: UIView {
    
    public weak var delegate: (JHUploadPhotoViewDelegate & JHUploadPhotoDataDelegate)?{
        didSet {
            if let obj = delegate {
                viewController = SystemHelper.getCurrentPresentingVC(obj)
                uploadPhotoMaxCount = obj.maxDisplayUPloadPhotoNumber()
                let item7 = uploadPhotoMaxCount % 7
                let item4 = uploadPhotoMaxCount % 4
                
                if item4 == 0 || item7 == 0 {
                    uploadPhotoLineItemCount = 4
                }
                else {
                    uploadPhotoLineItemCount = 3
                }
            }
        }
    }
    public var isDirectDisplayPhotoAlbum = true // 是否直接进入相册选择照片
    
    fileprivate weak var viewController: UIViewController?
    
    fileprivate var photoCollectionView: DragCellCollectionView!
    fileprivate var viewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10;
        layout.minimumInteritemSpacing = 10;
        return layout;
    }()
    
    fileprivate var browserPhotos: [Photo] = []
    fileprivate var imageViews: [UploadImageView] = []
    
    fileprivate var uploadPhotoMaxCount = 0
    fileprivate var uploadPhotoLineItemCount = 4
    
    fileprivate var imageViewWidth: CGFloat = 0
    fileprivate var imageViewWidthSpace: CGFloat = 0
    fileprivate var imageViewOriginYFix: CGFloat = 5
    
    fileprivate lazy var addButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.my_bundleImage(named: "icon_upload_add"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupViews()
    }
    
    func setupViews() {
//        addButton.addTarget(self, action: #selector(selectImage(sender:)), for: .touchUpInside)
//        self.addSubview(addButton)
        photoCollectionView = DragCellCollectionView(frame: CGRect.zero, collectionViewLayout: viewLayout)
        self.addSubview(photoCollectionView);
        photoCollectionView.myDelegate = self as? DragCellCollectionViewDelegate;
        photoCollectionView.myDataSource = self as? DragCellCollectionViewDataSource
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        let width = self.bounds.width - 2 * 15
        let height = self.bounds.height - 2 * 15
        photoCollectionView.frame = CGRect(x: 15, y: 15, width: width, height: height)
        
        let itemW = width / 4.0
        viewLayout.itemSize = CGSize(width: itemW, height: itemW)
        
//        if imageViewWidth < 1 {
//            let width = self.frame.width
//            let space = 10 * CGFloat(uploadPhotoLineItemCount - 1)
//            imageViewWidth = (width - space) / CGFloat(uploadPhotoLineItemCount)
//            imageViewWidthSpace = imageViewWidth + 10
//            
//            addButton.frame = CGRect(x: 0, y: imageViewOriginYFix, width: imageViewWidth, height: imageViewWidth)
//            
//            delegate?.uploadPhotoView(viewHeight: imageViewWidthSpace)
//        }
    }
    
    // MARK: - public
    
    public init(_ frame: CGRect, delegate: JHUploadPhotoViewDelegate & JHUploadPhotoViewDelegate) {
        super.init(frame: frame)
        self.delegate = delegate as? (JHUploadPhotoDataDelegate & JHUploadPhotoViewDelegate)
    }

    public func setupImageViews(_ imageUrls: [String]) {
        if imageUrls.count == 0 {
            return
        }
        
        // 清除之前的
        removeAllImageViews()
        
        let width = self.frame.width
        let space = 10 * CGFloat(uploadPhotoLineItemCount - 1)
        imageViewWidth = (width - space) / CGFloat(uploadPhotoLineItemCount)
        imageViewWidthSpace = imageViewWidth + 10
        
        // 添加已经有的图片
        var idx = 0
        for url in imageUrls {
            if let Url = NSURL(string: url) {
                browserPhotos.append(Photo(url: Url))
            }
            
            let x = imageViewWidthSpace * CGFloat(idx % uploadPhotoLineItemCount)
            let y = imageViewWidthSpace * CGFloat(idx / uploadPhotoLineItemCount) + imageViewOriginYFix
            let view = UploadImageView(frame: CGRect(x: x, y: y, width: imageViewWidth, height: imageViewWidth))
            
            view.tag = idx
            view.setImage(url)
            self.addSubview(view)
            imageViews.append(view)
            
            view.clickAction = { [unowned self] (index, isDeleted) in
                if isDeleted {
                    self.updateImageViewsForRemove(index)
                }
                else {
                    self.handleImageClickAction(index)
                }
            }
            idx += 1
        }
        
        var fix: Float = 0.0;
        if needUploadPhotoCount() == 0 {
            addButton.isHidden = true
        }
        else {
            addButton.isHidden = false
            let x = imageViewWidthSpace * CGFloat(idx % uploadPhotoLineItemCount)
            let i = idx / uploadPhotoLineItemCount
            let y = imageViewWidthSpace * CGFloat(i) + imageViewOriginYFix
            addButton.frame = CGRect(x: x, y: y, width: imageViewWidth, height: imageViewWidth)
            fix = 0.5
        }
        
        let tempS = CGFloat(lroundf(Float(idx / uploadPhotoLineItemCount) + fix))
        let height = imageViewWidthSpace * tempS
        updateSelfViewHeight(height)
        delegate?.uploadPhotoView(viewHeight: height)
    }
}

fileprivate extension UploadPhotoView {
    func updateSelfViewHeight(_ height: CGFloat) {
        var frame = self.frame
        frame.size.height = height
        self.frame = frame
    }
    
    func updateAddButton(_ origin: CGPoint) {
        var frame = addButton.frame
        frame.origin = origin
        addButton.frame = frame
    }
    
    func needUploadPhotoCount() -> Int {
        return uploadPhotoMaxCount - imageViews.count
    }
    
    func removeAllImageViews() {
        for view in imageViews {
            view.reloadInputViews()
        }
        imageViews.removeAll()
        browserPhotos.removeAll()
        
        addButton.isHidden = false
        updateAddButton(CGPoint(x: 0, y: 0))
    }
    
    func addImageDatas(_ datas: [Data]) {
        if viewController == nil {
            return
        }
        
        for data in datas {
            addImageView(imageData: data)
        }
    }
    
    // 添加新的图片view
    func addImageView(imageData data: Data) {
        let count = imageViews.count
        let x = imageViewWidthSpace * CGFloat(count % uploadPhotoLineItemCount)
        let i = count / uploadPhotoLineItemCount
        let y = imageViewWidthSpace * CGFloat(i) + imageViewOriginYFix
        
        let view = UploadImageView(frame: CGRect(x: x, y: y, width: imageViewWidth, height: imageViewWidth))
        view.delegate = delegate
        self.addSubview(view)
        imageViews.append(view)
        updateImageViewsForAddButton()
        
        view.clickAction = { [unowned self] (index, isDeleted) in
            if isDeleted {
                self.updateImageViewsForRemove(index)
            }
            else {
                self.handleImageClickAction(index)
            }
        }
        
        view.uploadImage(imageData: data, block: { [unowned self] (objView, success) in
            if success {
                self.browserPhotos.append(Photo(image: objView.currentImage!))
            }
            else {
                self.updateImageViewsForUploadFailed(objView.tag)
            }
        })
    }
    
    func updateImageViewsForAddButton() {
        var idx = 0
        for obj in imageViews {
            obj.tag = idx
            idx += 1
        }
        
        if uploadPhotoMaxCount == idx {
            addButton.isHidden = true
            return
        }
        else {
            addButton.isHidden = false
        }
        
        let x = imageViewWidthSpace * CGFloat(idx % uploadPhotoLineItemCount)
        let i = idx / uploadPhotoLineItemCount
        let y = imageViewWidthSpace * CGFloat(i) + imageViewOriginYFix
        updateAddButton(CGPoint(x: x, y: y))
        
        let tempS = CGFloat(lroundf(Float(idx / uploadPhotoLineItemCount) + 0.5))
        let height = imageViewWidthSpace * tempS
        updateSelfViewHeight(height)
        delegate?.uploadPhotoView(viewHeight: height)
    }
    
    func updateImageViewsForUploadFailed(_ index: Int) {
        print("上传图片失败  \(index)")
        imageViews[index].removeFromSuperview()
        imageViews.remove(at: index)
        delegate?.uploadPhotoViewForDeleteOrFailed(index)
        
        updateAllImageViewsForDeleteOrFailed()
    }
    
    func updateImageViewsForRemove(_ index: Int) {
        print("删除图片 \(index)")
        browserPhotos.remove(at: index)
        imageViews.remove(at: index)
        delegate?.uploadPhotoViewForDeleteOrFailed(index)
        
        updateAllImageViewsForDeleteOrFailed()
    }
    
    func updateAllImageViewsForDeleteOrFailed() {
        var idx = 0
        for obj in imageViews {
            obj.tag = idx
            let x = imageViewWidthSpace * CGFloat(idx % uploadPhotoLineItemCount)
            let y = imageViewWidthSpace * CGFloat(idx / uploadPhotoLineItemCount) + imageViewOriginYFix
            updateImageView(imageView: obj, origin: CGPoint(x: x, y: y))
            idx += 1
        }
        
        if uploadPhotoMaxCount == idx {
            addButton.isHidden = true
            return
        }
        else {
            addButton.isHidden = false
        }
        
        let x = imageViewWidthSpace * CGFloat(idx % uploadPhotoLineItemCount)
        let i = idx / uploadPhotoLineItemCount
        let y = imageViewWidthSpace * CGFloat(i) + imageViewOriginYFix
        updateAddButton(CGPoint(x: x, y: y))
        
        let tempS = CGFloat(lroundf(Float(idx / uploadPhotoLineItemCount) + 0.5))
        let height = imageViewWidthSpace * tempS
        updateSelfViewHeight(height)
        delegate?.uploadPhotoView(viewHeight: height)
    }
    
    func updateImageView(imageView: UploadImageView, origin: CGPoint) {
        var frame = imageView.frame
        frame.origin = origin
        imageView.frame = frame
    }
    
    // MARK: - action

    @objc func selectImage(sender: UIButton) {
        if let vc = viewController {
            if !isDirectDisplayPhotoAlbum {
                let selectImageView = SelectImageView(vc, maxSelectCount: needUploadPhotoCount())
                selectImageView.showView()
                selectImageView.block = { [unowned self] (datas) in
                    print("selected Photo number is \(datas.count)")
                    self.addImageDatas(datas)
                }
            }
            else {
                SystemHelper.verifyPhotoLibraryAuthorization(success: { [unowned self] () in
                    let nvc = PhotoAlbumViewController.photoAlbum(maxSelectCount: self.needUploadPhotoCount(), block: { (datas) in
                        print("selected \(datas.count) from album!")
                        self.addImageDatas(datas)
                    })
                    self.viewController?.present(nvc, animated: true, completion: nil)
                }, failed: nil)
            }
        }
        else {
            print("UploadPhotoView delegate(viewController) must not be nil")
        }
    }
    
    func handleImageClickAction(_ index: Int) {
        // 启动图片浏览器
        let photoBrowser = PhotoBrowser(delgegate: self)
        photoBrowser.setCurrentPageIndex(index)
        let nav = UINavigationController(rootViewController: photoBrowser)
        nav.modalTransitionStyle = .crossDissolve
        self.viewController?.present(nav, animated: true, completion: nil)
    }
}

extension UploadPhotoView: JHPhotoBrowserDelegate {
    public func numberOfPhotosInPhotoBrowser(_ photoBrowser: PhotoBrowser) -> Int {
        return browserPhotos.count
    }
    
    public func photoBrowser(_ photoBrowser: PhotoBrowser, photoAtIndex: Int) -> Photo? {
        if photoAtIndex < browserPhotos.count {
            return browserPhotos[photoAtIndex]
        }
        return nil
    }
}

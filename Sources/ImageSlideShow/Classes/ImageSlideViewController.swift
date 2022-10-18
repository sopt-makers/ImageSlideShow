//
//  ImageSlideViewController.swift
//
//  Created by Dimitri Giani on 02/11/15.
//  Copyright © 2015 Dimitri Giani. All rights reserved.
//

import UIKit

class ImageSlideViewController: UIViewController, UIScrollViewDelegate
{
  @IBOutlet weak var scrollView: UIScrollView?
  @IBOutlet weak var imageView: UIImageView?
  @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView?
  
  private let maximumZoomScale: CGFloat = 2.0
  private let minimumZoomScale: CGFloat = 1.0
  var slide: ImageSlideShowProtocol?
  var enableZoom = false
  var willBeginZoom: () -> Void = {}
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .black
    if self.enableZoom {
      self.scrollView?.maximumZoomScale = self.maximumZoomScale
      self.scrollView?.minimumZoomScale = self.minimumZoomScale
      self.scrollView?.zoomScale = 1.0
    }
    self.scrollView?.contentInsetAdjustmentBehavior = .never
    self.scrollView?.isHidden = true
    self.loadingIndicatorView?.startAnimating()
    
    self.slide?.image(completion: { (image, error) -> Void in
      DispatchQueue.main.async {
        self.imageView?.image = image
        self.loadingIndicatorView?.stopAnimating()
        self.scrollView?.isHidden = false
      }
    })
  }
  
  override func viewDidDisappear(_ animated: Bool) {
     super.viewDidDisappear(animated)
     if self.enableZoom {
       //  Reset zoom scale when the controller is hidden
       self.scrollView?.zoomScale = 1.0
     }
   }

   //  MARK: UIScrollViewDelegate
   
   func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
     self.willBeginZoom()
   }

   func viewForZooming(in scrollView: UIScrollView) -> UIView? {
     if self.enableZoom {
       return self.imageView
     }
     return nil
   }
 }

 // MARK: Gesture
 extension ImageSlideViewController {
   public func onDoubleTap() {
     guard let scrollView = self.scrollView else { return }
     if scrollView.zoomScale > scrollView.minimumZoomScale {
       scrollView.setZoomScale(self.minimumZoomScale, animated: true)
     } else {
       scrollView.setZoomScale(self.maximumZoomScale, animated: true)
     }
   }
 }

 // MARK: Save Image
extension ImageSlideViewController {
  func saveToGalleryCurrentImage() {
    guard let image = self.imageView?.image else { return }
    UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
  }
  
  @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
    if let _ = error {
      showAlertWith(title: "에러", message: "사진을 저장하는데 실패하였습니다")
    } else {
      showAlertWith(title: "알림", message: "사진이 저장되었습니다.")
    }
  }
  
  private func showAlertWith(title: String?, message: String) {
    let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
    ac.addAction(.init(title: "확인", style: .default, handler: nil))
    self.present(ac, animated: true)
  }
}

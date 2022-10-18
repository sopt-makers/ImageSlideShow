//
//  ViewController.swift
//  Demo
//
//  Created by Dimitri Giani on 16/10/2016.
//  Copyright © 2016 Dimitri Giani. All rights reserved.
//

import UIKit

//	Very bad Class, but just for Demo ;-)

class Image: NSObject, ImageSlideShowProtocol
{
	private let url: URL
	let title: String?
	
	init(title: String, url: URL) {
		self.title = title
		self.url = url
	}
	
	func slideIdentifier() -> String {
		return String(describing: url)
	}
	
	func image(completion: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {
		
		let session = URLSession(configuration: URLSessionConfiguration.default)
		session.dataTask(with: self.url) { data, response, error in
			
			if let data = data, error == nil
			{
				let image = UIImage(data: data)
				completion(image, nil)
			}
			else
			{
				completion(nil, error)
			}
			
		}.resume()
		
	}
}

class ViewController: UIViewController {

	fileprivate var images:[Image] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.generateImages()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	fileprivate func generateImages()
	{
		let scale:Int = Int(UIScreen.main.scale)
		let height:Int = Int(view.frame.size.height) * scale
		let width:Int = Int(view.frame.size.width) * scale
		
		images = [
			Image(title: "Image 1", url: URL(string: "https://dummyimage.com/\(width)x\(height)/09a/fff.png&text=Image+1")!),
			Image(title: "Image 2", url: URL(string: "https://dummyimage.com/\(600)x\(600)/09b/fff.png&text=Image+2")!),
			Image(title: "Image 3", url: URL(string: "https://dummyimage.com/\(width)x\(height)/09c/fff.png&text=Image+3")!),
			Image(title: "Image 4", url: URL(string: "https://dummyimage.com/\(600)x\(600)/09d/fff.png&text=Image+4")!),
			Image(title: "Image 5", url: URL(string: "https://dummyimage.com/\(width)x\(height)/09e/fff.png&text=Image+5")!),
			Image(title: "Image 6", url: URL(string: "https://dummyimage.com/\(width)x\(height)/09f/fff.png&text=Image+6")!),
		]
	}
	
	@IBAction func presentSlideShow(_ sender:AnyObject?)
	{
		ImageSlideShowViewController.presentByCustomTransitionFrom(self){ [weak self] controller in
			controller.dismissOnPanGesture = true
			controller.slides = self?.images
			controller.enableZoom = true
			controller.controllerDidDismiss = {
				debugPrint("Controller Dismissed")

				debugPrint("last index viewed: \(controller.currentIndex)")
			}

			controller.slideShowViewDidLoad = {
				debugPrint("Did Load")
			}

			controller.slideShowViewWillAppear = { animated in
				debugPrint("Will Appear Animated: \(animated)")
			}

			controller.slideShowViewDidAppear = { animated in
				debugPrint("Did Appear Animated: \(animated)")
			}

		}
	}
}


extension ViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ImageSlideShowViewController.presentLikePush
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ImageSlideShowViewController.dismissLikePush
    }
}

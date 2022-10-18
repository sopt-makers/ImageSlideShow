//
//  ImageSlideShowViewController.swift
//
//  Created by Dimitri Giani on 02/11/15.
//  Copyright © 2015 Dimitri Giani. All rights reserved.
//

import UIKit

public protocol ImageSlideShowProtocol {
  var title: String? { get }
  
  func slideIdentifier() -> String
  func image(completion: @escaping (_ image: UIImage?, _ error: Error?) -> Void)
}

class ImageSlideShowCache: NSCache<AnyObject, AnyObject> {
  override init() {
    super.init()
    NotificationCenter.default.addObserver(self, selector: #selector(NSMutableArray.removeAllObjects), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self);
  }
}

open class ImageSlideShowViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  
  static var imageSlideShowStoryboard: UIStoryboard = UIStoryboard(name: "ImageSlideShow", bundle: Bundle(for: ImageSlideShowViewController.self))
  
  open var slides: [ImageSlideShowProtocol]?
  open var initialIndex: Int = 0
  open var pageSpacing: CGFloat = 10.0
  open var panDismissTolerance: CGFloat = 30.0
  open var dismissOnPanGesture: Bool = false
  open var enableZoom: Bool = false
  open var statusBarStyle: UIStatusBarStyle = .darkContent
  open var navigationBarTintColor: UIColor = .white
  open var hideNavigationBarOnAction: Bool = true
  
  //  Current index and slide
  public var currentIndex: Int {
    return _currentIndex
  }
  public var currentSlide: ImageSlideShowProtocol? {
    return slides?[currentIndex]
  }
  
  public var slideShowViewDidLoad: (() -> Void)?
  public var slideShowViewWillAppear: ((_ animated: Bool) -> Void)?
  public var slideShowViewDidAppear: ((_ animated: Bool) -> Void)?
  
  open var controllerDidDismiss: () -> Void = {}
  open var stepAnimate: ((_ offset: CGFloat, _ viewController: UIViewController) -> Void) = { _, _ in }
  open var restoreAnimation: ((_ viewController: UIViewController) -> Void) = { _ in }
  open var dismissAnimation: ((_ viewController: UIViewController, _ panDirection: CGPoint, _ completion: @escaping () -> Void) -> Void) = { _, _, _ in }
  
  fileprivate var originPanViewCenter: CGPoint = .zero
  fileprivate var panViewCenter: CGPoint = .zero
  fileprivate var navigationBarHidden: Bool = false
  fileprivate var toggleBarButtonItem: UIBarButtonItem?
  fileprivate var _currentIndex: Int = 0
  fileprivate let slidesViewControllerCache = ImageSlideShowCache()
  
  override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
    return .fade
  }
  
  override open var preferredStatusBarStyle: UIStatusBarStyle {
    return statusBarStyle
  }
  
  override open var prefersStatusBarHidden: Bool {
    return navigationBarHidden
  }
  
  override open var shouldAutorotate: Bool {
    return true
  }
  
  override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .all
  }
  
  //  MARK: - Class methods
  
  class func imageSlideShowNavigationController() -> ImageSlideShowNavigationController {
    let controller = ImageSlideShowViewController.imageSlideShowStoryboard.instantiateViewController(withIdentifier: "ImageSlideShowNavigationController") as! ImageSlideShowNavigationController
    controller.modalPresentationStyle = .overFullScreen
    controller.modalPresentationCapturesStatusBarAppearance = true
    return controller
  }
  
  class func imageSlideShowViewController() -> ImageSlideShowViewController {
    let controller = ImageSlideShowViewController.imageSlideShowStoryboard.instantiateViewController(withIdentifier: "ImageSlideShowViewController") as! ImageSlideShowViewController
    controller.modalPresentationStyle = .overCurrentContext
    controller.modalPresentationCapturesStatusBarAppearance = true
    return controller
  }
  
  class open func presentFrom(_ viewController: UIViewController, configure: ((_ controller: ImageSlideShowViewController) -> Void)?) {
    let navController = self.imageSlideShowNavigationController()
    if let issViewController = navController.visibleViewController as? ImageSlideShowViewController {
      configure?(issViewController)
      viewController.present(navController, animated: true, completion: nil)
    }
  }
  
  class open func presentByCustomTransitionFrom(_ viewController: UIViewController, configure: ((_ controller: ImageSlideShowViewController) -> Void)?) {
    let navController = self.imageSlideShowNavigationController()
    navController.modalPresentationStyle = .custom
    if let issViewController = navController.visibleViewController as? ImageSlideShowViewController, let delegate = viewController as? UIViewControllerTransitioningDelegate {
      navController.transitioningDelegate = delegate
      configure?(issViewController)
      viewController.present(navController, animated: true, completion: nil)
    }
  }
  
  class open func pushFrom(_ navigationController: UINavigationController, configure: ((_ controller: ImageSlideShowViewController) -> Void)?) {
    let issViewController = imageSlideShowViewController()
    
    configure?(issViewController)
    navigationController.pushViewController(issViewController, animated: true)
  }
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    self.prepareAnimations()
  }
  
  //  MARK: - UI Component
  private let leftImage: UIImageView = {
    let iv = UIImageView()
    iv.contentMode = .scaleAspectFit
    iv.image = UIImage(systemName: "chevron.backward")
    iv.translatesAutoresizingMaskIntoConstraints = false
    iv.tintColor = UIColor(red: 0.682, green: 0.686, blue: 0.69, alpha: 1)
    return iv
  }()
  
  private let rightImage: UIImageView = {
    let iv = UIImageView()
    iv.contentMode = .scaleAspectFit
    iv.image = UIImage(systemName: "chevron.right")
    iv.translatesAutoresizingMaskIntoConstraints = false
    iv.tintColor = UIColor(red: 0.682, green: 0.686, blue: 0.69, alpha: 1)
    return iv
  }()
  
  private let countLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 16, weight: .light)
    label.textColor = UIColor(red: 0.682, green: 0.686, blue: 0.69, alpha: 1)
    label.numberOfLines = 1
    label.textAlignment = .center
    label.sizeToFit()
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  //  MARK: - Instance methods
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    delegate = self
    dataSource = self
    hidesBottomBarWhenPushed = true
    let image = UIImage(systemName: "arrow.backward")
    let downloadImage = UIImage(systemName: "square.and.arrow.down")
    let leftBarButtonItem = UIBarButtonItem(image: image, style: .done, target: self, action: #selector(dismiss))
    let rightBarButtonItem = UIBarButtonItem.init(image: downloadImage, style: .done, target: self, action: #selector(saveToGallery))
    navigationItem.leftBarButtonItem = leftBarButtonItem
    navigationItem.rightBarButtonItem = rightBarButtonItem
    view.backgroundColor = .black
    self.presentingViewController?.view.backgroundColor = .black
    
    //  Manage Gestures
    var gestures = self.gestureRecognizers
    
    let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.doubleTapGesture(_:)))
    doubleTapGesture.numberOfTapsRequired = 2
    gestures.append(doubleTapGesture)
    
    let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.singleTapGesture(_:)))
    singleTapGesture.numberOfTapsRequired = 1
    singleTapGesture.require(toFail: doubleTapGesture)
    gestures.append(singleTapGesture)
    
    if dismissOnPanGesture {
      let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(_:)))
      gestures.append(panGesture)
      
      
      scrollView()?.isDirectionalLockEnabled = true
      scrollView()?.alwaysBounceVertical = false
    }
    view.gestureRecognizers = gestures
    slideShowViewDidLoad?()
    
    self.setLayout()
  }
  
  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setPage(withIndex: initialIndex)
    slideShowViewWillAppear?(animated)
  }
  
  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.view.backgroundColor = .black
    
    slideShowViewDidAppear?(animated)
  }
  
  //  MARK: Actions
  
  @objc open func dismiss(sender: AnyObject?){
    dismiss(animated: true, completion: nil)
    controllerDidDismiss()
  }
  
  @objc open func saveToGallery() {
    guard let slideViewController = self.slideViewController(forPageIndex: self.currentIndex) else {
      print("Image not found!")
      return
    }
    slideViewController.saveToGalleryCurrentImage()
  }
  
  open func goToPage(withIndex index: Int) {
    if index != _currentIndex {
      setPage(withIndex: index)
    }
  }
  
  open func goToNextPage() {
    let index = _currentIndex + 1
    if index < (slides?.count)! {
      setPage(withIndex: index)
    }
  }
  
  open func goToPreviousPage() {
    let index = _currentIndex - 1
    if index >= 0 {
      setPage(withIndex: index)
    }
  }
  
  func setLayout() {
    [leftImage, countLabel, rightImage].forEach { self.view.addSubview($0) }
    
    leftImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 142 / 375 * UIScreen.main.bounds.width).isActive = true
    leftImage.widthAnchor.constraint(equalToConstant: 24).isActive = true
    leftImage.heightAnchor.constraint(equalToConstant: 24).isActive = true
    leftImage.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -36).isActive = true
    
    countLabel.centerYAnchor.constraint(equalTo: leftImage.centerYAnchor).isActive = true
    countLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    
    rightImage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -142 / 375 * UIScreen.main.bounds.width).isActive = true
    rightImage.widthAnchor.constraint(equalToConstant: 24).isActive = true
    rightImage.heightAnchor.constraint(equalToConstant: 24).isActive = true
    rightImage.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -36).isActive = true
  }
  
  func setPage(withIndex index: Int) {
    if  let viewController = slideViewController(forPageIndex: index) {
      setViewControllers([viewController], direction: (index > _currentIndex ? .forward: .reverse), animated: true, completion: nil)
      _currentIndex = index
      updateSlideBasedUI()
    }
  }
  
  func setNavigationBar(visible: Bool) {
    guard hideNavigationBarOnAction else { return }
    guard let view = self.navigationController?.view else { return }
    self.navigationBarHidden = !visible
    if visible {
      self.navigationController?.setNavigationBarHidden(!visible, animated: false)
    }
    UIView.transition(
      with: view,
      duration: 0.2,
      options: .transitionCrossDissolve
    ) {
      self.navigationController?.setNavigationBarHidden(!visible, animated: false)
    }
  }
  
  // MARK: UIPageViewControllerDataSource
  
  
  public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
    //    self.setNavigationBar(visible: false)
  }
  
  public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    if completed {
      _currentIndex = indexOfSlideForViewController(viewController: (pageViewController.viewControllers?.last)!)
      updateSlideBasedUI()
    }
  }
  
  public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    let index = indexOfSlideForViewController(viewController: viewController)
    
    if index > 0 {
      return slideViewController(forPageIndex: index - 1)
    } else {
      return nil
    }
  }
  
  public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    let index = indexOfSlideForViewController(viewController: viewController)
    if let slides = slides, index < slides.count - 1 {
      return slideViewController(forPageIndex: index + 1)
    } else {
      return nil
    }
  }
  
  // MARK: Accessories
  
  private func indexOfProtocolObject(inSlideViewController controller: ImageSlideViewController) -> Int? {
    var index = 0
    if let object = controller.slide, let slides = slides {
      for slide in slides {
        if slide.slideIdentifier() == object.slideIdentifier() {
          return index
        }
        index += 1
      }
    }
    return nil
  }
  
  private func indexOfSlideForViewController(viewController: UIViewController) -> Int {
    guard let viewController = viewController as? ImageSlideViewController else { fatalError("Unexpected view controller type in page view controller.") }
    guard let viewControllerIndex = indexOfProtocolObject(inSlideViewController: viewController) else { fatalError("View controller's data item not found.") }
    return viewControllerIndex
  }
  
  private func slideViewController(forPageIndex pageIndex: Int) -> ImageSlideViewController? {
    if let slides = slides, slides.count > 0 {
      let slide = slides[pageIndex]
      if let cachedController = slidesViewControllerCache.object(forKey: slide.slideIdentifier() as AnyObject) as? ImageSlideViewController {
        return cachedController
      } else {
        guard let controller = self.storyboard?.instantiateViewController(withIdentifier: "ImageSlideViewController") as? ImageSlideViewController else { fatalError("Unable to instantiate a ImageSlideViewController.") }
        controller.slide = slide
        controller.enableZoom = enableZoom
        //        controller.willBeginZoom = {
        //          self.setNavigationBar(visible: false)
        //        }
        slidesViewControllerCache.setObject(controller, forKey: slide.slideIdentifier() as AnyObject)
        return controller
      }
    }
    return nil
  }
  
  private func prepareAnimations() {
    stepAnimate = { step, viewController in
      if let viewController = viewController as? ImageSlideViewController {
        if step == 0 {
          viewController.imageView?.layer.shadowRadius = 10
          viewController.imageView?.layer.shadowOpacity = 1
          self.navigationController?.view.backgroundColor = .black
        } else {
          let alpha = CGFloat(1.0 - step)
          self.navigationController?.navigationBar.alpha = 0.0
          self.navigationController?.view.backgroundColor = .black
          let scale = max(0.8, alpha)
          viewController.imageView?.center = self.panViewCenter
          viewController.imageView?.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
      }
    }
    restoreAnimation = { viewController in
      if let viewController = viewController as? ImageSlideViewController {
        UIView.animate(
          withDuration: 0.2,
          delay: 0.0,
          options: .beginFromCurrentState,
          animations: {
            self.presentingViewController?.view.transform = .identity
            viewController.imageView?.center = self.originPanViewCenter
            viewController.imageView?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            viewController.imageView?.layer.shadowRadius = 0
            viewController.imageView?.layer.shadowOpacity = 1
          }
        )
      }
    }
    dismissAnimation = { viewController, panDirection, completion in
      if let viewController = viewController as? ImageSlideViewController {
        let velocity = panDirection.y
        UIView.animate(
          withDuration: 0.3,
          delay: 0.0,
          options: .beginFromCurrentState,
          animations: {
            self.presentingViewController?.view.transform = .identity
            var frame = viewController.imageView?.frame ?? .zero
            frame.origin.y = (velocity > 0 ? self.view.frame.size.height * 2 : -self.view.frame.size.height)
            viewController.imageView?.transform = .identity
            viewController.imageView?.frame = frame
            viewController.imageView?.alpha = 0.0
          }, completion: { completed in
            completion()
          }
        )
      }
    }
  }
  
  private func updateSlideBasedUI() {
    if let slidesCount = slides?.count {
      self.countLabel.text = "\(currentIndex + 1)/\(slidesCount)"
    }
    if let title = currentSlide?.title {
      navigationItem.title = title
    }
  }
}

// MARK: Gestures
extension ImageSlideShowViewController: UIGestureRecognizerDelegate {
  
  @objc private func doubleTapGesture(_ gesture: UITapGestureRecognizer) {
    guard let currentSlideViewController = self.slideViewController(forPageIndex: self.currentIndex) else { return }
    currentSlideViewController.onDoubleTap()
  }
  
  @objc private func singleTapGesture(_ gesture: UITapGestureRecognizer) {
    self.setNavigationBar(visible: self.navigationBarHidden == true)
  }
  
  @objc private func panGesture(_ gesture: UIPanGestureRecognizer) {
    let viewController = slideViewController(forPageIndex: currentIndex)
    
    switch gesture.state {
    case .began:
      //        presentingViewController?.view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
      originPanViewCenter = view.center
      panViewCenter = view.center
      stepAnimate(0, viewController!)
      
    case .changed:
      let translation = gesture.translation(in: view)
      panViewCenter = CGPoint(x: panViewCenter.x + translation.x, y: panViewCenter.y + translation.y)
      gesture.setTranslation(.zero, in: view)
      let distanceX = abs(originPanViewCenter.x - panViewCenter.x)
      let distanceY = abs(originPanViewCenter.y - panViewCenter.y)
      let distance = max(distanceX, distanceY)
      let center = max(originPanViewCenter.x, originPanViewCenter.y)
      let distanceNormalized = max(0, min((distance / center), 1.0))
      stepAnimate(distanceNormalized, viewController!)
      
    case .ended, .cancelled, .failed:
      let distanceY = abs(originPanViewCenter.y - panViewCenter.y)
      if (distanceY >= panDismissTolerance) {
        UIView.animate(
          withDuration: 0.3,
          delay: 0.0,
          options: .beginFromCurrentState,
          animations: { () -> Void in
            self.navigationController?.view.alpha = 0.0
          }
        )
        dismissAnimation(viewController!, gesture.velocity(in: gesture.view), {
          self.dismiss(sender: nil)
        })
      } else {
        UIView.animate(
          withDuration: 0.2,
          delay: 0.0,
          options: .beginFromCurrentState,
          animations: { () -> Void in
            self.navigationBarHidden = true
            self.navigationController?.navigationBar.alpha = 0.0
            self.navigationController?.view.backgroundColor = .black
          }
        )
        restoreAnimation(viewController!)
      }
      
    default: break
    }
  }
}

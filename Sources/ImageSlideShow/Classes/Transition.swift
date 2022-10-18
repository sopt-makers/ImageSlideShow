//
//  Transition.swift
//  Demo
//
//  Created by Junho Lee on 2022/10/18.
//  Copyright © 2022 Dimitri Giani. All rights reserved.
//

import UIKit
extension ImageSlideShowViewController {
    public class var presentLikePush: UIViewControllerAnimatedTransitioning {
        return PresentTransition()
    }
    
    public class var dismissLikePush: UIViewControllerAnimatedTransitioning {
        return DismissTransition()
    }
}

class PresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var animator: UIViewImplicitlyAnimating?

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let animator = self.interruptibleAnimator(using: transitionContext)
        animator.startAnimation()
    }
    
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        if self.animator != nil {
            return self.animator!
        }
        
        let container = transitionContext.containerView
        let fromVC = transitionContext.viewController(forKey: .from)!
        
        let fromViewInitialFrame = transitionContext.initialFrame(for: fromVC)
        
        let fromView = fromVC.view!
        let toView = transitionContext.view(forKey: .to)!
        
        var toViewInitialFrame = fromViewInitialFrame
        toViewInitialFrame.origin.x = toView.frame.size.width
        
        toView.frame = toViewInitialFrame
        container.addSubview(toView)
        
        let animator = UIViewPropertyAnimator(duration: self.transitionDuration(using: transitionContext), curve: .easeInOut) {
            
            toView.frame = fromViewInitialFrame
        }
        
        animator.addCompletion { _ in
            transitionContext.completeTransition(true)
        }
        
        self.animator = animator
        
        return animator
        
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        self.animator = nil
    }
}


import UIKit

class DismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var animator: UIViewImplicitlyAnimating?

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let animator = self.interruptibleAnimator(using: transitionContext)
        animator.startAnimation()
    }
    
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        if self.animator != nil {
            return self.animator!
        }
        
        let fromVC = transitionContext.viewController(forKey: .from)!
        
        var fromViewInitialFrame = transitionContext.initialFrame(for: fromVC)
        fromViewInitialFrame.origin.x = 0
        var fromViewFinalFrame = fromViewInitialFrame
        fromViewFinalFrame.origin.x = fromViewFinalFrame.width
        
        let fromView = fromVC.view!
        
        let animator = UIViewPropertyAnimator(duration: self.transitionDuration(using: transitionContext), curve: .easeInOut) {
            
            fromView.frame = fromViewFinalFrame
        }
        
        animator.addCompletion { _ in
            transitionContext.completeTransition(true)
        }
        
        self.animator = animator
        
        return animator
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        self.animator = nil
    }
}


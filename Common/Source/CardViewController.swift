//
//  CardViewController.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 02/09/16.
//  Copyright © 2016 Magnus Eriksson. All rights reserved.
//

import UIKit
import GLKit

public struct CardViewControllerFactory {
    
    static public func make(cards: [UIView]) -> CardViewController {
        
        let nib = UINib(nibName: String(describing: CardViewController.self),
                        bundle: Bundle(for: CardViewController.self))
            .instantiate(withOwner: nil, options: nil)
        
        let vc = nib.first as! CardViewController
        vc.cards = cards
        return vc
    }
}

public protocol CardViewControllerDelegate: class {
    func cardViewController(_ cardViewController: CardViewController, didSelect card: UIView, at index: Int)
    func cardViewController(_ cardViewController: CardViewController, didNavigateTo card: UIView, at index: Int)
}

public typealias TransitionInterpolator = (_ transitionProgress: CGFloat) -> (CGFloat)

public class CardViewController: UIViewController {
    
    //MARK: Configurable
    
    public weak var delegate: CardViewControllerDelegate? = nil
    
    ///The card views
    public var cards: [UIView] = [] {
        didSet {
            DispatchQueue.main.async {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                oldValue.forEach { $0.removeFromSuperview() }
                self.add(cards: self.cards)
                self.applyInitialCardTransform()
                self.scrollView.cv_scrollToPageAtIndex(0, animated: false)
                self.currentCardIndex = 0
                CATransaction.commit()
            }
        }
    }
    
    ///The width of the card in relation to the parent view. 
    ///Must be between 0.1 - 1.0. Default is 0.5 (i.e. half the size of the parent view).
    public var cardWidthRatio: CGFloat = 0.5 {
        didSet {
            let minValue: CGFloat = 0.1
            let maxValue: CGFloat = 1.0
            cardWidthRatio = max(minValue, min(maxValue, cardWidthRatio))
            
            //Update the scroll view's horizontal page size
            scrollView.cv_pageSizeFactor = cardWidthRatio
        }
    }
    
    ///The height of the card in relation to its own width.
    ///Must be between 0.5 - 2. Default is 1.0 (i.e. the same height as width).
    public var cardHeightRatio: CGFloat = 1.0  {
        didSet {
            let minValue: CGFloat = 0.5
            let maxValue: CGFloat = 2.0
            cardHeightRatio = max(minValue, min(maxValue, cardHeightRatio))
        }
    }
    
    ///The number of degrees to rotate the background cards
    public var degreesToRotateCard: CGFloat = 45
    
    ///The z translation factor applied to the cards during transition. The formula is (cardWidth * factor)
    public var cardZTranslationFactor: CGFloat = 1/3
    
    ///The alpha of the background cards
    public var backgroundCardAlpha: CGFloat = 0.65
    
    ///If the edge cards should bounce when scrolling beyond the edges
    public var isBounceEnabled = true
    
    ///If paging between the cards should be enabled
    public var isPagingEnabled = true
    
    ///The transition interpolation applied to the source card during transition
    public var sourceTransitionInterpolator: TransitionInterpolator = CardInterpolator.cubicOut
    
    ///The transition interpolation applied to the destination card during transition
    public var destinationTransitionInterpolator: TransitionInterpolator = CardInterpolator.cubicOut
    
    
    
    
    //MARK: Properties
    
    ///The index of the current card
    public internal(set) var currentCardIndex: Int = 0 {
        didSet {
            guard let delegate = delegate,
                let card = card(at: currentCardIndex),
                oldValue != currentCardIndex else {
                return
            }
            delegate.cardViewController(self, didNavigateTo: card, at: currentCardIndex)
        }
    }
    
    ///Spacing between cards
    fileprivate let cardSpacing: CGFloat = 0
    
    private var pageIndexBeforeRotation: Int = 0
    
    
    
    
    //MARK: IBOutlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIStackView!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewTapGestureRecognizer: UITapGestureRecognizer!
    
   
    
    
    
    //MARK: Life cycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        contentView.spacing = cardSpacing
        scrollView.bounces = isBounceEnabled
        
        #if os(tvOS)
            //Workaround to enable smooth scrolling in tvOS
            scrollView.isScrollEnabled = false
        #endif
        
        handleRotation()
    }
    
    //MARK: Rotation related events
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        pageIndexBeforeRotation = scrollView.cv_currentPage()
        
        coordinator.animate(alongsideTransition: { context in
            //Restore previous page
            self.handleRotation()
        })
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    private func handleRotation() {
        updateOrientationRelatedConstraints()
        applyInitialCardTransform()
        scrollView.cv_scrollToPageAtIndex(pageIndexBeforeRotation, animated: false)
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    /// Updates the leading and trailing constraints to the remaining width of the screen
    private func updateOrientationRelatedConstraints() {
        let totalBorderMargin = view.bounds.width * (1 - cardWidthRatio)
        leadingConstraint.constant = totalBorderMargin / 2.0
        trailingConstraint.constant = totalBorderMargin / 2.0
    }
    
    
    //MARK: Public
    
    /// Returns the card at the received index, or nil if the index is out of bounds
    public func card(at index: Int) -> UIView? {
        guard index >= 0 && index < cards.count else {
            return nil
        }
        
        return cards[index]
    }
    
    ///Navigates to the card at the received index, if the index is within bounds
    public func scrollToCardAtIndex(_ index: Int) {
        guard card(at: index) != nil else {
            return
        }
        
        #if os(iOS)
            //On iOS: Disable manual scrolling during programatical scrolling
            scrollViewWillScrollToCard()
        #endif
        
        scrollView.cv_scrollToPageAtIndex(index, animated: true)
    }
    
    ///Prepares the scroll view prior to programatically scrolling to a card
    private func scrollViewWillScrollToCard() {
        scrollView.isScrollEnabled = false
        contentViewTapGestureRecognizer.isEnabled = false
    }
    
    ///Restores the scroll view after programatically scrolling to a card
    fileprivate func scrollViewDidScrollToCard() {
        scrollView.isScrollEnabled = true
        contentViewTapGestureRecognizer.isEnabled = true
    }
    
    
    //MARK: Card transform
    
    private func add(cards: [UIView]) {
        for card in cards {
            //IMPORTANT: Changes to the horizontal spacing between cards must be reflected in 'UIScrollView::pageSize()' to account for it
            contentView.addArrangedSubview(card)
            card.translatesAutoresizingMaskIntoConstraints = false
            
            //Set up width in relation to the parent view
            card.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: cardWidthRatio).isActive = true
            
            //Set up height in relation to the card's own width
            card.heightAnchor.constraint(equalTo: card.widthAnchor, multiplier: cardHeightRatio).isActive = true
        }
    }
    
    private func applyInitialCardTransform() {
        for (index, card) in cards.enumerated() {
            if index == currentCardIndex {
                let zTranslation = (card.bounds.width * cardZTranslationFactor)
                applyViewTransformation(to: card,
                                        degrees: 0,
                                        alpha: 1,
                                        zTranslation: zTranslation,
                                        rotateBeforeTranslate: true)
            } else {
                let direction: CGFloat = index < currentCardIndex ? 1 : -1
                applyViewTransformation(to: card,
                                        degrees: (direction * degreesToRotateCard),
                                        alpha: backgroundCardAlpha,
                                        zTranslation: 0,
                                        rotateBeforeTranslate: true)
            }
        }
    }
    
    fileprivate func applyViewTransformation(to view: UIView,
                                             degrees: CGFloat,
                                             alpha: CGFloat,
                                             zTranslation: CGFloat,
                                             rotateBeforeTranslate: Bool) {
        view.alpha = alpha
        
        if rotateBeforeTranslate {
            CATransform3DMakeYRotationAndZTranslation(view.layer, degrees: degrees, zTranslation: zTranslation)
        } else {
            CATransform3DMakeZTranslationAndYRotation(view.layer, zTranslation: zTranslation, degrees: degrees)
        }
    }
}

extension CardViewController: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let isGoingBackwards = scrollView.cv_currentPage() < currentCardIndex
        
        //"percentScrolledInPage" represents the X-scroll percentage within the current page, starting at index 0.
        //E.g. if the scroll view is 50% between page 5 and 6, the  will be 4.5
        let percentScrolledInPage = scrollView.cv_horizontalPercentScrolledInCurrentPage()
        
        //The transition progress of the leftmost page involved in the transition
        let leftTransitionProgress = percentScrolledInPage - CGFloat(scrollView.cv_currentPage())
        
        //The transition progress of the rightmost page involved in the transition (the opposite of the leftTransitionProgress)
        let rightTransitionProgress = (1 - leftTransitionProgress)
        
        //The transition progress of the current/source page
        var sourceTransitionProgress = isGoingBackwards ? rightTransitionProgress : leftTransitionProgress
        sourceTransitionProgress = sourceTransitionInterpolator(sourceTransitionProgress)
        sourceTransitionProgress *= isGoingBackwards ? -1 : 1
        
        //The transition progress of the destination page
        var destTransitionProgress = isGoingBackwards ? leftTransitionProgress : rightTransitionProgress
        destTransitionProgress = destinationTransitionInterpolator(destTransitionProgress)
        destTransitionProgress *= isGoingBackwards ? 1 : -1
        
        //The index of the leftmost element involved in the transition
        let transitionLeftElementIndex = scrollView.cv_currentPage()
        
        //The index of the rightmost element involved in the transition
        let transitionRightElementIndex = transitionLeftElementIndex + 1
        
        //The index of the transition source element
        let transitionSourceElementIndex = isGoingBackwards ? transitionRightElementIndex : transitionLeftElementIndex
        
        //The index of the transition destination element
        let transitionDestinationElementIndex = isGoingBackwards ? transitionLeftElementIndex : transitionRightElementIndex
        
        if let sourceCard = card(at: transitionSourceElementIndex) {
            //Gradually remove y rotation (i.e. move towards an y rotation of zero)
            let sourceDegrees = sourceTransitionProgress * degreesToRotateCard
            
            //Gradually move towards a normal alpha (i.e. move towards an alpha value of one)
            let sourceAlpha = max(backgroundCardAlpha, abs(destTransitionProgress))
            
            //Gradually move closer to the camera (i.e. move towards a positive Z translation)
            let maxZTranslation = (sourceCard.bounds.width * cardZTranslationFactor)
            let sourceZTranslation = abs(destTransitionProgress * maxZTranslation)
            applyViewTransformation(to: sourceCard, degrees: sourceDegrees, alpha: sourceAlpha, zTranslation: sourceZTranslation, rotateBeforeTranslate: true)
        }
        
        if let destCard = card(at: transitionDestinationElementIndex) {
            //Gradually add y rotation (i.e. move towards an y rotation of 'self.degreesToRotate')
            let destDegrees = destTransitionProgress * degreesToRotateCard
            
            //Gradually move towards a faded alpha (i.e. move towards an alpha value of 0..1)
            let destAlpha = max(backgroundCardAlpha, abs(sourceTransitionProgress))
            let maxZTranslation = (destCard.bounds.width * cardZTranslationFactor)
            
            //Gradually move away to the camera (i.e. move back towards the normal z translation of zero)
            let destZTranslation = abs(sourceTransitionProgress * maxZTranslation)
            applyViewTransformation(to: destCard, degrees: destDegrees, alpha: destAlpha, zTranslation: destZTranslation, rotateBeforeTranslate: false)
        }
        
        //Restore the previous source card's view transform to the 'initial background state'
        //since 'scrollViewDidScroll' may not be called for every transition progress percentage (0-1) if the user is scrolling very quickly
        //and may therefor end up in a halfway state
        let previousSourceIndex = transitionSourceElementIndex + (isGoingBackwards ? 1 : -1)
        if let previousSourceCard = card(at: previousSourceIndex) {
            let degrees = degreesToRotateCard * (isGoingBackwards ? -1 : 1)
            applyViewTransformation(to: previousSourceCard, degrees: degrees, alpha: backgroundCardAlpha, zTranslation: 0, rotateBeforeTranslate: true)
        }
    }
    
    ///Apply paging by updating the target content offset to the nearest card
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard isPagingEnabled else {
            return
        }
        guard let cardSize = card(at: 0)?.bounds.width else {
            return
        }
        
        let minIndex: CGFloat = 0
        let maxIndex = CGFloat(cards.count)
        
        //Calculate x coordinate of destination, including velocity
        let velocityBoostFactor: CGFloat = 5
        let destX = scrollView.contentOffset.x + (velocity.x * velocityBoostFactor)
        
        //Calculate index of destination card
        var destCardIndex = round(destX / (cardSize + cardSpacing))
        
        //Avoid "jumping" to initial position when making very small swipes
        if velocity.x > 0 {
            destCardIndex = ceil(destX / (cardSize + cardSpacing))
        } else {
            destCardIndex = floor(destX / (cardSize + cardSpacing))
        }
        
        //Ensure index is within bounds
        destCardIndex = max(minIndex, min(maxIndex, destCardIndex))
        
        //Update target content offset
        targetContentOffset.pointee.x = destCardIndex * (cardSize + cardSpacing)
    }
    
    ///Save the index of the current card when the scroll view has stopped scrolling
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            currentCardIndex = scrollView.cv_currentPage()
        }
    }
    
    ///Save the index of the current card when the scroll view has stopped scrolling
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentCardIndex = scrollView.cv_currentPage()
    }
    
    ///Called when the scroll view ends scrolling programatically (e.g. when a user taps on a card)
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        currentCardIndex = scrollView.cv_currentPage()
        
        //Restore the settings. Will not be called on tvOS
        #if os(iOS)
            scrollViewDidScrollToCard()
        #endif
    }
}

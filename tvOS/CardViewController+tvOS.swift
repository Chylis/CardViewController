//
//  CardViewController+tvOS.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 2017-03-18.
//  Copyright © 2017 Magnus Eriksson. All rights reserved.
//

import Foundation

extension CardViewController {
    
    override public func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        guard let destinationView = context.nextFocusedView,
            let destinationIndex = cards.index(of: destinationView),
            currentCardIndex != destinationIndex else {
                return false
        }
        return true
    }
    
    public override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        //context.nextFocusedView may be nil if we're e.g. dismissing the current view controller
        guard let destinationView = context.nextFocusedView,
            let destinationIndex = cards.index(of: destinationView) else {
                return
        }
        
        coordinator.addCoordinatedAnimations({
            self.scrollToCardAtIndex(destinationIndex)
        })
    }
    
    @IBAction func tvos_onScrollViewTapped(_ sender: UITapGestureRecognizer) {
        guard let currentCard = card(at: currentCardIndex) else {
            return
        }
        delegate?.cardViewController(self, didSelect: currentCard, at: currentCardIndex)
    }
}

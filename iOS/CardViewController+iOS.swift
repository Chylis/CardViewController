//
//  CardViewController+iOS.swift
//  CardViewController
//
//  Created by Magnus on 2017-03-20.
//  Copyright © 2017 Magnus Eriksson. All rights reserved.
//

import Foundation

extension CardViewController {
    
    @IBAction func iOS_onScrollViewTapped(_ sender: UITapGestureRecognizer) {
        guard let currentCard = card(at: currentCardIndex) else {
            return
        }
        
        //Check if the touch point is in the currently centered card or in a neighbouring card
        var selectedCardIndex = -1
        let touchPoint = sender.location(in: contentView)
        if touchPoint.x > currentCard.frame.maxX {
            selectedCardIndex = currentCardIndex + 1
        } else if touchPoint.x < currentCard.frame.minX {
            selectedCardIndex = currentCardIndex - 1
        } else {
            //Tapped the current card - notify delegate
            delegate?.cardViewController(self, didSelect: currentCard, at: currentCardIndex)
            return
        }
        
        //Tapped a neighbouring card - navigate to it
        scrollToCardAtIndex(selectedCardIndex)
    }
}

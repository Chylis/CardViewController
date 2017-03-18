//
//  CardViewController+tvOS.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 2017-03-18.
//  Copyright © 2017 Magnus Eriksson. All rights reserved.
//

import Foundation

//MARK: TVOS UIFocusEnvironment

extension CardViewController {
    
    //TODO: Consider alternative to extensions in a framework.
    public override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        guard let destinationView = context.nextFocusedView,
            let destinationIndex = cards.index(of: destinationView) else {
                return
        }
        
        scrollToCardAtIndex(destinationIndex)
    }
}


//
//  AppDelegate.swift
//  Demo
//
//  Created by Magnus Eriksson on 2017-03-24.
//  Copyright © 2017 Magnus Eriksson. All rights reserved.
//

import UIKit
import CardViewController


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //1. Create card views to be presented in the CardViewController:
        let cardViews: [UIView] = ["bird", "larva", "bulbasaur", "togepi", "evee"].map { UIImageView(image: UIImage(named: $0)) }
        cardViews.forEach { $0.backgroundColor = .blue }
        
        //2. Create the cardViewController:
        let cardVc = CardViewControllerFactory.make(cards: cardViews)
        
        //3. *Optional* Configure the card view controller:
        cardVc.delegate = self
        
        //The number of degrees to rotate the background cards
        cardVc.degreesToRotateCard = 45
        
        //The alpha of the background cards
        cardVc.backgroundCardAlpha = 0.65
        
        //The z translation factor applied to the cards during transition
        cardVc.cardZTranslationFactor = 1/3
        
        //If paging between the cards should be enabled
        cardVc.isPagingEnabled = true
        
        //The transition interpolation applied to the source and destination card during transition
        //The CardInterpolator contains some predefined functions, but feel free to provide your own.
        cardVc.sourceTransitionInterpolator = CardInterpolator.cubicOut
        cardVc.destinationTransitionInterpolator = CardInterpolator.cubicOut
        
        
        self.window = UIWindow()
        window?.rootViewController = cardVc
        window?.makeKeyAndVisible()
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            cardVc.cards = self.cardViews1()
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
//            cardVc.cards = self.cardViews2()
//        }
        return true
    }
    
    func cardViews1() -> [UIView ]{
        return ["evee", "bird", "togepi", "togepi", "evee"].map { UIImageView(image: UIImage(named: $0)) }
    }
    func cardViews2() -> [UIView]{
        return ["evee", "togepi"].map { UIImageView(image: UIImage(named: $0)) }
    }
    
}

extension AppDelegate: CardViewControllerDelegate {
    
    func cardViewController(_ cardViewController: CardViewController, didNavigateTo card: UIView, at index: Int) {
        print("Did navigate to card at index: \(index)")
    }
    
    func cardViewController(_ cardViewController: CardViewController, didSelect card: UIView, at index: Int) {
        print("Did select card at index: \(index)")
    }
}

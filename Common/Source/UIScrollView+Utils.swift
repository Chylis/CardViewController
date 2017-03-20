//
//  UIScrollView+Utils.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 02/09/16.
//  Copyright © 2016 Magnus Eriksson. All rights reserved.
//

import Foundation

import UIKit

extension UIScrollView {
    private struct AssociatedKeys {
        static var pageSizeFactor = "mge_ScrollViewPageSizeFactor"
    }
    
    var cv_pageSizeFactor: CGFloat? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.pageSizeFactor) as? CGFloat
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self,
                                         &AssociatedKeys.pageSizeFactor,
                                         newValue as CGFloat?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }
}

extension UIScrollView {
    
    func cv_scrollToPageAtIndex(_ index: Int, animated: Bool = false) {
        let newX = CGFloat(index) * cv_pageSize()
        cv_setHorizontalContentOffset(newX, animated: animated)
    }
    
    /**
     "Safely" updates the scroll view's horizontal content offset within its bounds.
     Minimum value is 0 (i.e. left of first page).
     Maximum value is 'contentSize.width - pageSize' (i.e. left of last page)
     */
    func cv_setHorizontalContentOffset(_ x: CGFloat, animated: Bool = false) {
        let newX = max(cv_minimumHorizontalOffset(), min(cv_maximumHorizontalOffset(), x))
        setContentOffset(CGPoint(x: newX, y: 0), animated: animated)
    }
    
    /**
     Calculates the current X-scroll percentage within the current page.
     Starts at index 0. E.g. if the scroll view is 50% between page 5 and 6, this function will return 4.5
     */
    func cv_horizontalPercentScrolledInCurrentPage() -> CGFloat {
        let maxHorizontalOffset = cv_pageSize()
        if maxHorizontalOffset > 0 {
            return (contentOffset.x / maxHorizontalOffset)
        }
        
        return 0
    }
    
    /**
     Minimum value is 0 (i.e. left of first page).
     */
    func cv_minimumHorizontalOffset() -> CGFloat {
        return 0
    }
    
    /**
     Maximum value is 'contentSize.width - pageSize' (i.e. left of last page)
     */
    func cv_maximumHorizontalOffset() -> CGFloat {
        return contentSize.width - cv_pageSize()
    }
    
    /**
     Returns the current page number, or -1 if content offset is < 0
     */
    func cv_currentPage() -> Int {
        guard contentOffset.x >= 0 else {
            return -1
        }
        
        let pageNumber = Int(contentOffset.x / cv_pageSize())
        return pageNumber
    }
    
    func cv_pageSize() -> CGFloat {
        //NOTE: This value must correspond to the card width + card spacing
        return bounds.size.width * (cv_pageSizeFactor ?? 0.5)
    }
}

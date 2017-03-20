//
//  CATransform3DUtils.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 08/09/16.
//  Copyright © 2016 Magnus Eriksson. All rights reserved.
//

import GLKit

/*
 The perspective transform is a single value in the 4x4 matrix - m34. 
 m34 is used to scale the X and Y values in proportion to how far away they are from the camera.
 By default m34 has a value of zero. This can be changes by setting it to -1.0 / d, 
 where d is the distance between the imaginary camera and the screen, measured in points. (We make a value up). 
 A ‘d’ value between 500-1000 usually works fine. Decreasing the value increases the perspective effect, 
 and increasing the value will decrease the effect, making the isometric projection again.
 */
#if os(tvOS)
let cameraPerspective: CGFloat = -1/1000 //1000 seems to be a good value for tvOS
#else
let cameraPerspective: CGFloat = -1/500 //500 seems to be a good value for iOS
#endif


func CATransform3DMakeYRotationAndZTranslation(_ layer: CALayer, degrees: CGFloat, zTranslation: CGFloat) {
    var perspective = CATransform3DIdentity
    perspective.m34 = cameraPerspective
    layer.transform = perspective
    layer.transform = CATransform3DRotate(layer.transform, CGFloat(GLKMathDegreesToRadians(Float(degrees))), 0, 1, 0)
    layer.transform = CATransform3DTranslate(layer.transform, 0, 0, zTranslation)
}

func CATransform3DMakeZTranslationAndYRotation(_ layer: CALayer, zTranslation: CGFloat, degrees: CGFloat) {
    var perspective = CATransform3DIdentity
    perspective.m34 = cameraPerspective
    layer.transform = perspective
    layer.transform = CATransform3DTranslate(layer.transform, 0, 0, zTranslation)
    layer.transform = CATransform3DRotate(layer.transform, CGFloat(GLKMathDegreesToRadians(Float(degrees))), 0, 1, 0)
}

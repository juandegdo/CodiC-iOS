//
//  PlaySlider.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-11-20.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class PlaySlider: UISlider {

    let trackHeight: CGFloat = 3.0;
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var newBounds = super.trackRect(forBounds: bounds)
        newBounds.origin.y = bounds.size.height - trackHeight
        newBounds.size.height = trackHeight
        return newBounds
    }

}

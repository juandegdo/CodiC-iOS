//
//  RadAvatar.swift
//  MedicConnect
//
//  Created by alessandro on 11/27/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit

class RadAvatar: UIImageView {
    
    let ColorOrange = UIColor(red: 244/255, green: 145/255, blue: 28/255, alpha: 1.0)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.contentMode = .scaleAspectFill
        
        self.layer.masksToBounds = true
        self.clipsToBounds = true
        
        self.backgroundColor = UIColor.white //ColorOrange
        self.layer.cornerRadius = self.frame.height / 2
        
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1.5
    }
    
}

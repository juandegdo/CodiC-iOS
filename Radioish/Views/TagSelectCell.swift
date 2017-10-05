//
//  TagSelectCell.swift
//  Radioish
//
//  Created by alessandro on 1/2/17.
//  Copyright © 2017 Loewen. All rights reserved.
//

import UIKit

class TagSelectCell: UICollectionViewCell {
    
    @IBOutlet var tagButton: UIButton!
    
    func setTagTitle(tagTitle: String) {
        self.tagButton.setTitle(tagTitle, for: .normal)
    }

}

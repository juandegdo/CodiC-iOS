//
//  SettingHeaderCell.swift
//  Radioish
//
//  Created by alessandro on 12/22/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit

class SettingHeaderCell: UITableViewCell {
    
    @IBOutlet var lblTitle: UILabel!
    
    func setTitle(title: String) {
        
        self.lblTitle.text = title
        
    }

}

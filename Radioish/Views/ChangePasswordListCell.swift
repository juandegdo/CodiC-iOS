//
//  ChangePasswordListCell.swift
//  Radioish
//
//  Created by alessandro on 12/25/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import UIKit

class ChangePasswordListCell: UITableViewCell {
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var txField: UITextField!
    
    func setCellWithTitle(title: String) {
        
        self.selectionStyle = UITableViewCellSelectionStyle.default
        
        self.lblTitle.text = title
        
    }
    
}

//
//  DataManager.swift
//  MedicConnect
//
//  Created by alessandro on 12/3/16.
//  Copyright © 2016 Loewen. All rights reserved.
//

import Foundation

class DataManager {
    
    static let Instance = DataManager()
    
    var theLastTabIndex: Int = 0

    
    // MARK: Saved Tab Index
        
    func getLastTabIndex() -> Int {
        
        return self.theLastTabIndex
        
    }
    
    func setLastTabIndex(tabIndex: Int) {
        
        self.theLastTabIndex = tabIndex
        
    }
    
}

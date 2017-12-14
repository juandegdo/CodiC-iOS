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
    var postType: String = Constants.PostTypeDiagnosis
    var patientId: String = ""
    var referringUserId: String = ""
    
    // MARK: Saved Tab Index
        
    func getLastTabIndex() -> Int {
        return self.theLastTabIndex
    }
    
    func setLastTabIndex(tabIndex: Int) {
        self.theLastTabIndex = tabIndex
    }
    
    // MARK: Post Type
    
    func getPostType() -> String {
        return self.postType
    }
    
    func setPostType(postType: String) {
        self.postType = postType
    }
    
    // MARK: Patient Id
    
    func getPatientId() -> String {
        return self.patientId
    }
    
    func setPatientId(patientId: String) {
        self.patientId = patientId
    }
    
    // MARK: Referring User Id
    
    func getReferringUserId() -> String {
        return self.referringUserId
    }
    
    func setReferringUserId(referringUserId: String) {
        self.referringUserId = referringUserId
    }
    
}

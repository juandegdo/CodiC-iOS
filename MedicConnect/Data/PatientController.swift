//
//  PatientController.swift
//  MedicConnect
//
//  Created by Daniel Yang on 2017-11-29.
//  Copyright © 2017 Loewen. All rights reserved.
//

import Foundation

class PatientController {
    
    static let Instance = PatientController()
    
    fileprivate var patients: [Patient] = []
    
    //MARK: Patients
    
    func getPatients() -> [Patient] {
        return self.patients.reversed()
    }
    
    func setPatients(_ patients: [Patient]) {
        self.patients = patients.sorted(by: { $0.birthdate < $1.birthdate })
    }
    
}

//
//  ConsultService.swift
//  ReferringDocApp
//
//  Created by Daniel Yang on 2018-04-10.
//  Copyright © 2018 Loewen. All rights reserved.
//

import Alamofire
import Foundation

class ConsultService: BaseTaskController {
    
    static let Instance = ConsultService()
    
    func addCallHistory(toUser: String, type: String, callId: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let url = "\(self.baseURL)\(self.URLAddCallHistory)"
        let parameter = [
            "toUser": toUser,
            "type": type,
            "callId": callId
        ]
        print(parameter)
        
        manager!.request(url, method: .post, parameters: parameter, encoding: URLEncoding.default)
            .responseJSON { response in
                
                if let _ = response.result.value {
                    print("Response: \(response.result.value!)")
                }
                
                if let err = response.result.error as NSError?, err.code == -1009 {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    AlertUtil.showSimpleAlert((appDelegate.window?.visibleViewController())!, title: "You aren't online.", message: "Get connected to the internet\nand try again.", okButtonTitle: "OK")
                    
                    completion(false)
                    return
                }
                
                completion(response.response?.statusCode == 200)
                
        }
        
    }
    
}

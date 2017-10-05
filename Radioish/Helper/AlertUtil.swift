//
//  AlertUtil.swift
//  Beauty Lab
//
//  Created by alessandro on 09/01/16.
//  Copyright © 2016 Andres Bonilla. All rights reserved.
//

import UIKit

class AlertUtil {
    
    static func showOKAlert(_ vc: UIViewController, message: String) {
        let alertController = AlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelButtonTitle = "OK"
        
        // Create the action.
        let cancelAction = AlertAction(title: cancelButtonTitle, style: .cancel) { action in
            
        }
        
        // Add the action.
        alertController.addAction(cancelAction)
        
        vc.present(alertController, animated: true, completion: nil)
    }
    
    static func showOKAlert(_ vc: UIViewController, message: String, okCompletionBlock: @escaping (() -> Void)) {
        let alertController = AlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelButtonTitle = "OK"
        
        // Create the action.
        let cancelAction = AlertAction(title: cancelButtonTitle, style: .cancel) { action in
            okCompletionBlock()
        }
        
        // Add the action.
        alertController.addAction(cancelAction)
        
        vc.present(alertController, animated: true, completion: nil)
    }
    
    static func showConfirmAlert(_ vc: UIViewController, message: String, okButtonTitle: String, cancelButtonTitle: String, okCompletionBlock: (() -> Void)!, cancelCompletionBlock: (() -> Void)!) {
        let alertController = AlertController(title: nil, message: message, preferredStyle: .alert)
        
        // Create the action.
        let cancelAction = AlertAction(title: cancelButtonTitle, style: .default) { action in
            cancelCompletionBlock()
        }
        
        let okAction = AlertAction(title: okButtonTitle, style: .cancel) { action in
            okCompletionBlock()
        }
        
        // Add the action.
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        vc.present(alertController, animated: true, completion: nil)
    }
}


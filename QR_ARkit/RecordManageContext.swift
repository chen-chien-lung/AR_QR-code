//
//  RecordManageContext.swift
//  QR_ARkit
//
//  Created by Joe Chen on 2018/12/13.
//  Copyright © 2018 Joe Chen. All rights reserved.
//

import Foundation
import CoreData
import UIKit



class RecordContext {
    private static let sharedContext: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    // Properties
    
    let string: String
    // Initialization
    private init(string: String) {
        self.string = string
    }
    // Accessors
    class func shared() -> NSManagedObjectContext {
        return sharedContext
    }
    
}

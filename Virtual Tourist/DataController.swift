//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Fatima Aljaber on 28/01/2019.
//  Copyright © 2019 Fatima. All rights reserved.
//

import Foundation
import CoreData
class DataController {
   
    let persistentContainer:NSPersistentContainer
    
    init(nameOfTheModel:String) {
        persistentContainer = NSPersistentContainer(name: nameOfTheModel)
    }
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores(completionHandler: {
            storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        })
    }
}

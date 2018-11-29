//
//  Item+CoreDataClass.swift
//  Local Labor Market Data
//
//  Created by Nidhi Chawla on 11/28/18.
//  Copyright © 2018 Department of Labor. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Item)
public class Item: NSManagedObject {
    class func getSuperParents<T: Item>(context: NSManagedObjectContext) -> [T]?
    {
        let results: [T]?
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = T.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "parent == nil")
        fetchRequest.entity = T.entity()
        do {
            results = try context.fetch(fetchRequest) as? [T]
        } catch let error as NSError {
            print("context.fetch error in getWholeEntity(): " + error.debugDescription)
            results = nil
        }
        
        return results?.sorted()
    }
    
    // Sorted SubItems
    func subItems() -> [Item]? {
        return (children?.allObjects as? [Item])?.sorted()
    }
}

extension Item: Comparable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.code == rhs.code
    }
    
    public static func < (lhs: Item, rhs: Item) -> Bool {
        return (lhs.code ?? "") < (rhs.code ?? "")
    }
}
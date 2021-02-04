//
//  HomeTimelineIndex.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation
import CoreData

final public class HomeTimelineIndex: NSManagedObject {
    
    public typealias ID = String
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var domain: String
    @NSManaged public private(set) var userID: String
    
    @NSManaged public private(set) var hasMore: Bool    // default NO
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var deletedAt: Date?

    
    // many-to-one relationship
    @NSManaged public private(set) var toot: Toot
    
}

extension HomeTimelineIndex {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        toot: Toot
    ) -> HomeTimelineIndex {
        let index: HomeTimelineIndex = context.insertObject()
        
        index.identifier = property.identifier
        index.domain = property.domain
        index.userID = toot.author.id
        index.createdAt = toot.createdAt
        
        index.toot = toot
        
        return index
    }
    
    public func update(hasMore: Bool) {
        if self.hasMore != hasMore {
            self.hasMore = hasMore
        }
    }
    
    // internal method for Toot call
    func softDelete() {
        deletedAt = Date()
    }
    
}

extension HomeTimelineIndex {
    public struct Property {
        public let identifier: String
        public let domain: String
    
        public init(domain: String) {
            self.identifier = UUID().uuidString + "@" + domain
            self.domain = domain
        }
    }
}

extension HomeTimelineIndex: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \HomeTimelineIndex.createdAt, ascending: false)]
    }
}


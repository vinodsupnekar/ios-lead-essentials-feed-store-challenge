//
//  ManagedCache.swift
//  FeedStoreChallenge
//
//  Created by vinod supnekar on 22/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

internal class ManagedCache: NSManagedObject {
	@NSManaged public var timestamp: Date
	@NSManaged public var feed: NSOrderedSet
}

extension ManagedCache {
	
	var localFeed : [LocalFeedImage] {
		return feed.compactMap { ($0 as? ManagedFeedImage)?.local
		}
	}
	
	static func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
		try ManagedCache.find(in: context).map { obj in
			context.delete(obj)
		}
		return ManagedCache(context: context)
	}
	
	static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
		let request = NSFetchRequest<ManagedCache> (entityName: entity().name!)
		request.returnsObjectsAsFaults = false
		return try context.fetch(request).first
	}

}

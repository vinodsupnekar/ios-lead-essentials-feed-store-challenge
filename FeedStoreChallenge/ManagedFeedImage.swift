//
//  ManagedFeedImage.swift
//  FeedStoreChallenge
//
//  Created by vinod supnekar on 22/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

@objc(ManagedFeedImage)
internal class ManagedFeedImage: NSManagedObject {
	
	@NSManaged var id: UUID
	@NSManaged var imageDescription: String?
	@NSManaged var location: String?
	@NSManaged var url: URL
	@NSManaged var cache: ManagedCache?
}

extension ManagedFeedImage {

	@nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedFeedImage> {
		return NSFetchRequest<ManagedFeedImage>(entityName: "ManagedFeedImage")
	}
	
	var local: LocalFeedImage {
		return LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
	}
	
	static func images(from localFeed: [LocalFeedImage], in context: NSManagedObjectContext) -> NSOrderedSet {
		return NSOrderedSet(array: localFeed.map { local in
			let managed = ManagedFeedImage(context: context)
			managed.id = local.id
			managed.imageDescription = local.description
			managed.location = local.location
			managed.url = local.url
			return managed
		})
	}
}

//
//  CoreDataFeedStore.swift
//  FeedStoreChallenge
//
//  Created by vinod supnekar on 22/01/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

enum CustomError : Error {
	case noRecordFound
	case fetchError
}
 
class CoreDataFeedStore: FeedStore {

	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext
	
	public init(storeURL: URL, bundle: Bundle = .main) throws {
		NSPersistentContainer.load()
		container = try NSPersistentContainer.load(modelName: "CoreDataImageFeed", storeURL: storeURL, in: bundle)
		
		context = container.newBackgroundContext()
	}
	
	func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		
		perform { context in
			do {
				try ManagedCache.find(in:context).map { obj in
					context.delete(obj)
				}.map {
					try context.save()
				}
				completion(nil)
			}
			catch {
				completion(error)
			}
		}
	}
	
	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

		perform { context in
			do {
				let managedCache = try ManagedCache.newUniqueInstance(in: context)
				managedCache.timestamp = timestamp
				managedCache.feed = ManagedFeedImage.images(from: feed, in: context)

				try context.save()
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
	
	func retrieve(completion: @escaping RetrievalCompletion) {
		
		perform {  context in
			do {
				if let cache = try ManagedCache.find(in: context) {
					completion(.found(feed: cache.localFeed,timestamp: cache.timestamp!))
				}
				else {
					completion(.empty)
				}
			}
			catch {
				completion(.failure(error))
			}

		}
	}
		
	private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
		let context = self.context
		context.perform {
			action(context)
		}
	}
	
	// MARK:- Helper
	
	func anyURL() -> URL {
	  return URL(string: "www.any-url.com")!
	}
	
}


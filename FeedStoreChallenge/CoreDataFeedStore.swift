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
	
	struct CodableFeedImage: Equatable,Codable {
		public let id: UUID
		public let description: String?
		public let location: String?
		public let url: URL

		init( image: LocalFeedImage) {
			id = image.id
			description = image.description
			location = image.location
			url = image.url
		}
		
		public var local: LocalFeedImage {
			return LocalFeedImage.init(id: id, description: description, location: location, url: url)
			}
	}
	
	private struct Cache: Codable {
		let feed: [CodableFeedImage]
		let timestamp: Date
		
		var localFeed: [LocalFeedImage] {
			return feed.map { $0.local
			}
		}
	}
	
	lazy var managedObjectModel: NSManagedObjectModel = {
		
//		if let modelURL = Bundle.main.url(forResource: "CoreDataImageFeed", withExtension: "momd"), let model = NSManagedObjectModel(contentsOf: modelURL) {
//		return model
//		}
//		else {
		let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for:  type(of: self))])!
		return managedObjectModel
//		}
	}()
		
	
	lazy var persistentContainer: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "CoreDataImageFeed"
			 , managedObjectModel: self.managedObjectModel)

		container.loadPersistentStores(completionHandler: {
			(storeDescription, error) in

			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		return container
	}()
	
	var feedImages: [NSManagedObject] = []
	
	lazy var context : NSManagedObjectContext = {
//		persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		return persistentContainer.viewContext
	}()
	
	private let queue = DispatchQueue(label: "\(CoreDataFeedStore.self) Queue",qos: .userInitiated,attributes: .concurrent)

	func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		let selfForBlcok = self

		self.context.perform {
			let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreDataFeedImage")
			let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

			do {
				try selfForBlcok.context.execute(batchDeleteRequest)
				completion(nil)
			} catch  {
				completion(error)
			}
		}
	}
	
	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let selfForBlcok = self
		self.context.perform {
			selfForBlcok.deleteCacheItems()
			selfForBlcok.storeCache(imgs: feed.map{ CodableFeedImage(image: $0) }, date: timestamp, completion: completion)
		}
	}
	
	func retrieve(completion: @escaping RetrievalCompletion) {
		self.context.perform {
			if let result = self.fetchFeedImage() {
				completion(.found(feed: result.localFeed, timestamp: result.timestamp))
			}
			else {
				completion(.empty)
			}
		}
	}

	func anyURL() -> URL {
	  return URL(string: "www.any-url.com")!
	}
	
	func uniqueLocalImage() -> CodableFeedImage {
		 return CodableFeedImage(image: LocalFeedImage(id: UUID(), description: "the first image feed", location: "Sangli", url: anyURL()))
	}
	
	func storeCache( imgs : [CodableFeedImage],date: Date, completion: @escaping InsertionCompletion) {
		for img in imgs {
			let feed =  CoreDataFeedImage(context: context)
			feed.date = date
			feed.id = img.id
			feed.imageInfo = img.description
			feed.location = img.location
			feed.url = img.url
			
			do {
//				context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
				try context.save()
			} catch let error as NSError {
				completion(error)
				print("error \(error), \(error.userInfo)")
			}
		}
		completion(nil)
	}
	
	private func fetchFeedImage() -> Cache? {
		var feeds = [CodableFeedImage]()
		do {
			let fetchRequest = 	NSFetchRequest<NSFetchRequestResult>(entityName: "CoreDataFeedImage")

			guard let result = try context.fetch(fetchRequest) as? [CoreDataFeedImage], result.count > 0 else { return nil }
			
			feeds = result.map {
				CodableFeedImage(image: LocalFeedImage(id: $0.id, description: $0.imageInfo!, location: $0.location!, url: $0.url!))
			}
			let cache = Cache.init(feed: feeds, timestamp: (result.first?.date)!)
			return cache

		} catch {
			return nil
		}
	}
	
	private func deleteCacheItems() {
		do {
			guard let feeds = try context.fetch(CoreDataFeedImage.fetchRequest()) as? [CoreDataFeedImage] else {
				return }
			
			for feed in feeds {
				context.delete(feed)
			}
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

			try context.save()
		} catch  {
			print(error)
		}
	}
	
	func saveCache() {
		saveContext(backgroundContext: persistentContainer.viewContext)
	}
	
	
	func saveContext(backgroundContext: NSManagedObjectContext? = nil) {
		
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

		guard context.hasChanges else {
			return
		}
		
		do {
			try context.save()
		} catch let error as NSError {
			print("error \(error), \(error.userInfo)")
		}
	}
	
	
	
	// MARK:- Helper
	
}

extension CoreDataFeedStore {
	@discardableResult
	public func loadDataModel() -> NSPersistentContainer{
		return self.persistentContainer
	}
}



//func loadModelFromBundle() -> NSManagedObjectModel {
//
//		var str : URL = anyURL()
//
////		Bundle.
////		for bundle in Bundle.allBundles {
//
////			if bundle.url(forResource: "FeedStoreModel", withExtension: ".xcdatamodeld") != nil {
////				str == bundle.url(forResource: "FeedStoreModel", withExtension: ".xcdatamodeld")
////			}
////			guard str == bundle.path(forResource: "FeedStoreModel", ofType: ".momd")else {
////				break
////			}
////		}
////		let str = Bundle.main.path(forResource: "FeedStoreModel", ofType: ".momd")!
////		let url = URL(string: str)
//		let model = NSManagedObjectModel(contentsOf: str)
////	let modelURL = Bundle.main.url(forResource:  "FeedStore", withExtension: ".momd")
////	let model = NSManagedObjectModel(contentsOf: modelURL!)!
//		return model!
//	}

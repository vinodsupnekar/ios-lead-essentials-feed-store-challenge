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
	
//	private struct CodableFeedImage: Equatable,Codable {
//		public let id: UUID
//		public let description: String?
//		public let location: String?
//		public let url: URL
//
//		init( image: LocalFeedImage) {
//			id = image.id
//			description = image.description
//			location = image.location
//			url = image.url
//		}
//
//		public var local: LocalFeedImage {
//			return LocalFeedImage.init(id: id, description: description, location: location, url: url)
//			}
//	}
	
//	private struct Cache: Codable {
//		let feed: [CodableFeedImage]
//		let timestamp: Date
//
//		var localFeed: [LocalFeedImage] {
//			return feed.map { $0.local
//			}
//		}
//	}
	
	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext
	
	public init(storeURL: URL, bundle: Bundle = .main) throws {
		NSPersistentContainer.load()
		container = try NSPersistentContainer.load(modelName: "CoreDataImageFeed", storeURL: storeURL, in: bundle)
		
		context = container.newBackgroundContext()
	}
	
	
//	lazy var managedObjectModel: NSManagedObjectModel = {
//		let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for:  type(of: self))])!
//		return managedObjectModel
//	}()
//
//
//	lazy var persistentContainer: NSPersistentContainer = {
//		let container = NSPersistentContainer(name: "CoreDataImageFeed"
//			 , managedObjectModel: self.managedObjectModel)
//
//		container.loadPersistentStores(completionHandler: {
//			(storeDescription, error) in
//
//			if let error = error as NSError? {
//				fatalError("Unresolved error \(error), \(error.userInfo)")
//			}
//		})
//		return container
//	}()
//
//	lazy var context : NSManagedObjectContext = {
//		return persistentContainer.viewContext
//	}()
//
//	public func loadDataModel() -> NSPersistentContainer{
//		return self.persistentContainer
//	}
	
	private let queue = DispatchQueue(label: "\(CoreDataFeedStore.self) Queue",qos: .userInitiated,attributes: .concurrent)

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

//extension CoreDataFeedStore {
//	@discardableResult
	
//
//	func clearCache() {
//	 let selfLocal = self
//
//	self.context.perform {
//		do {
//			let fetchRequest: NSFetchRequest<CoreDataFeedImage> = NSFetchRequest<CoreDataFeedImage>(entityName: "CoreDataFeedImage")
//
//			guard let feeds = try? selfLocal.context.fetch(fetchRequest) else {
//				return
//			}
//
//			for feed in feeds {
//				selfLocal.context.delete(feed)
//			}
//			try selfLocal.context.save()
//		} catch  {
//		}
//	 }
//	}
//}

@objc(ManagedFeedImage)
public class ManagedFeedImage: NSManagedObject {
	
	@NSManaged public var id: UUID
	@NSManaged public var imageDescription: String?
	@NSManaged public var location: String?
	@NSManaged public var url: URL
	@NSManaged public var cache: ManagedCache?
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


public class ManagedCache: NSManagedObject {
	@NSManaged public var timestamp: Date?
	@NSManaged public var feed: NSOrderedSet?
	
	var localFeed : [LocalFeedImage] {
		return feed!.compactMap { ($0 as? ManagedFeedImage)?.local
		}
	}
}

extension ManagedCache {

	@nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedCache> {
		return NSFetchRequest<ManagedCache>(entityName: "ManagedCache")
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

extension NSPersistentContainer {
	enum LoadingError : Swift.Error {
		case modelNotFound
		case failedToLoadPersistentStores(Swift.Error)
	}
	
	static func load(modelName name: String, storeURL: URL, in bundle: Bundle) throws -> NSPersistentContainer {
		
		guard let model = NSManagedObjectModel.with(name: name, in : bundle) else {
			throw LoadingError.modelNotFound
		}
		
		let description = NSPersistentStoreDescription(url: storeURL)
		let container = NSPersistentContainer(name: name, managedObjectModel: model)
		container.persistentStoreDescriptions = [description]
		
		var loadError: Swift.Error?
		container.loadPersistentStores {
			loadError = $1
		}
		
		try loadError.map {
			throw LoadingError.failedToLoadPersistentStores($0)
		}
		return container
	}
}

extension NSManagedObjectModel {
	static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
		return bundle.url(forResource: name, withExtension: "momd").flatMap {
			NSManagedObjectModel(contentsOf: $0)
		}
	}
}

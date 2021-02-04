//
//  CoreDataFeedImage+CoreDataProperties.swift
//  FeedStoreChallenge
//
//  Created by vinod supnekar on 04/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreDataFeedImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataFeedImage> {
        return NSFetchRequest<CoreDataFeedImage>(entityName: "CoreDataFeedImage")
    }

    @NSManaged public var url: URL?
    @NSManaged public var location: String?
    @NSManaged public var imageInfo: String?
    @NSManaged public var ss: NSObject?
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?

}

extension CoreDataFeedImage : Identifiable {

}

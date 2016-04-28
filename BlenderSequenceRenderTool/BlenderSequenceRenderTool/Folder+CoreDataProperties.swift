//
//  Folder+CoreDataProperties.swift
//  BlenderSequenceRenderTool
//
//  Created by Paul Hamilton on 27/04/2016.
//  Copyright © 2016 Paul Hamilton. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Folder {

    @NSManaged var path: String?
    @NSManaged var ext: String?

}

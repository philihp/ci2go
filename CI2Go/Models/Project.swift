//
//  Project.swift
//  CI2Go
//
//  Created by Atsushi Nagase on 11/1/14.
//  Copyright (c) 2014 LittleApps Inc. All rights reserved.
//

import Foundation
import CoreData

public class Project: CI2GoManagedObject {

  @NSManaged public var parallelCount: NSNumber?
  @NSManaged public var repositoryName: String?
  @NSManaged public var username: String?
  @NSManaged public var urlString: String?
  @NSManaged public var branches: NSSet?
  @NSManaged public var builds: NSSet?
  @NSManaged public var commits: NSSet?
  @NSManaged public var projectID: String?

  public var URL: NSURL? {
    get {
      return urlString == nil ? nil : NSURL(string: urlString!)
    }
  }

  public func importBranches(json: NSDictionary!) -> Bool {
    if let branchesData = json["branches"] as? Dictionary<String, AnyObject> {
      let mSet = NSMutableSet()
      if let repo = json["vcs_url"] as? String {
        for branchName in branchesData.keys.array {
          let dict = [
            "name": branchName.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!,
            "branchID": "\(repo)#\(branchName)"
          ]
          if let b = Branch.MR_importFromObject(dict, inContext: managedObjectContext!) as? Branch {
            mSet.addObject(b)
          }
        }
      }
      branches = mSet.copy() as? NSSet
    }
    return true
  }

  
  
}

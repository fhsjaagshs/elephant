//
//  Elephant.swift
//  Elephant
//
//  Created by Nathaniel Symer on 8/10/16.
//  Copyright © 2016 Nathaniel Symer. All rights reserved.
//

import Foundation

public class Elephant: NSObject {
    public var dataPath: String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!;
    internal var dataStructurePaths: [String:String] = [:]; // [key,(class,path,size)]
    
    public class var shared: Elephant {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: Elephant? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = Elephant();
        }
        
        return Static.instance!;
    }

    public override init() {
        super.init();
        self.dataStructurePaths = NSKeyedUnarchiver.unarchiveObjectWithFile(self.dataPath + "/elephant.plist") as? [String:String] ?? [:];
    }
    
    public subscript(key: String) -> ETDataStructure? {
        get {
            if let path = self.dataStructurePaths[key] {
                do {
                    let attrs: [String:AnyObject] = try NSFileManager.defaultManager().attributesOfItemAtPath(path);
                    
                    if let s: UInt64 = (attrs[NSFileSize] as? NSNumber)?.unsignedLongLongValue {
                        return ETDataStructure(memory: ETMemoryRegion(filePath: path, length: UInt64(s)));
                    }
                } catch {}
            }
            return nil;
        }
        set (ds) {
            if let s = ds {
                self.dataStructurePaths[key] = s.memory?.filePath;
            } else {
                self.dataStructurePaths[key] = nil;
            }
            
            NSKeyedArchiver.archiveRootObject(self.dataStructurePaths, toFile: self.dataPath + "/elephant.plist")
        }
    }
}

//
//  DataCache.swift
//

import UIKit
import ImageIO

protocol Datable {
    init?(data: NSData)
    func toData() -> NSData
}

extension UIImage: Datable {
    func toData() -> NSData {
        return UIImagePNGRepresentation(self)
    }
}

class DataCache<T: Datable> {
    private let queue = NSOperationQueue()
    private let cache = LRUCache<NSURL, T>(maxSize: 100)
    var count: Int { return self.cache.count }
    
    init() {
        self.queue.name = "DataCacheQueue"
        self.queue.maxConcurrentOperationCount = 10;
    }
    
    func clear() {
        self.cache.clear()
    }
    
    subscript (url: NSURL) -> T? {
        get {
            if let data = NSData(contentsOfURL: url) {
                if let datable = T(data: data) {
                    self.cache[url] = datable
                    return datable
                }
            }
            return nil
        }
    }
    
    func containsKey(key: NSURL) -> Bool {
        return self.cache.containsKey(key)
    }
   
    func objectForURL(url: NSURL, block: ((url: NSURL, object: T) -> Void)?) -> T? {
        if let cachedImage = self.cache[url] {
            return cachedImage
        } else {
            self.queue.addOperationWithBlock() {
                if let data = NSData(contentsOfURL: url) {
                    if data.length > 0 {
                        if let datable = T(data: data) {
                            datable.toData()
                            self.cache[url] = datable
                            
                            if block != nil {
                                NSOperationQueue.mainQueue().addOperationWithBlock() {
                                    block!(url: url, object: datable)
                                }
                            }
                        }
                    }
                }
            }
            return nil
        }
    }
}

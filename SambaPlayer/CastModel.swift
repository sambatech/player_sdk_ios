//
//  CastModel.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 19/09/2018.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation


class CastModel {
    var title : String?
    var m : String?
    var live: String?
    var duration : CLong?
    var theme : String?
    var ph : String?
    var qs : CastQuery?
    var thumbURL : String?
    var baseURL : String?
    var drm : CastDRM?
    
    public class func modelsFromDictionaryArray(array:NSArray) -> [CastModel] {
        var models:[CastModel] = []
        for item in array
        {
            models.append(CastModel(dictionary: item as! NSDictionary)!)
        }
        return models
    }
    
    public init() {}
    
    public init?(dictionary: NSDictionary) {
        
        title = dictionary["title"] as? String
        m = dictionary["m"] as? String
        live = dictionary["live"] as? String
        duration = dictionary["duration"] as? CLong
        theme = dictionary["theme"] as? String
        ph = dictionary["ph"] as? String
        if (dictionary["qs"] != nil) { qs = CastQuery(dictionary: dictionary["qs"] as! NSDictionary) }
        if (dictionary["drm"] != nil) { drm = CastDRM(dictionary: dictionary["drm"] as! NSDictionary) }
        thumbURL = dictionary["thumbURL"] as? String
        baseURL = dictionary["baseURL"] as? String
    }
    
    
    public func dictionaryRepresentation() -> NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        dictionary.setValue(self.title, forKey: "title")
        dictionary.setValue(self.m, forKey: "m")
        dictionary.setValue(self.live, forKey: "live")
        dictionary.setValue(self.duration, forKey: "duration")
        dictionary.setValue(self.theme, forKey: "theme")
        dictionary.setValue(self.ph, forKey: "ph")
        dictionary.setValue(self.qs?.dictionaryRepresentation(), forKey: "qs")
        dictionary.setValue(self.drm?.dictionaryRepresentation(), forKey: "drm")
        dictionary.setValue(self.thumbURL, forKey: "thumbURL")
        dictionary.setValue(self.baseURL, forKey: "baseURL")
        dictionary.setValue(self.drm, forKey: "drm")
        
        return dictionary
    }
    
}

//MARK: - Cast Query

class CastQuery {
    var html5 : Bool?
    var castApi : String?
    var castAppId : String?
    var captionTheme : String?
    var initialTime : CLong?
    
    class func modelsFromDictionaryArray(array:NSArray) -> [CastQuery] {
        var models:[CastQuery] = []
        for item in array
        {
            models.append(CastQuery(dictionary: item as! NSDictionary)!)
        }
        return models
    }
    
    init() {}

    init?(dictionary: NSDictionary) {
        
        html5 = dictionary["html5"] as? Bool
        castApi = dictionary["castApi"] as? String
        castAppId = dictionary["castAppId"] as? String
        captionTheme = dictionary["captionTheme"] as? String
        initialTime = dictionary["initialTime"] as? CLong
    }
    
    func dictionaryRepresentation() -> NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        dictionary.setValue(self.html5, forKey: "html5")
        dictionary.setValue(self.castApi, forKey: "castApi")
        dictionary.setValue(self.castAppId, forKey: "castAppId")
        dictionary.setValue(self.captionTheme, forKey: "captionTheme")
        dictionary.setValue(self.initialTime, forKey: "initialTime")
        
        return dictionary
    }
    
}


//MARK: - Cast DRM

class CastDRM {
    
    var sessionId : String?
    var ticket : String?
    
    class func modelsFromDictionaryArray(array:NSArray) -> [CastDRM] {
        var models:[CastDRM] = []
        for item in array
        {
            models.append(CastDRM(dictionary: item as! NSDictionary)!)
        }
        return models
    }

    init() {
    }
    
    init?(dictionary: NSDictionary) {
        
        sessionId = dictionary["SessionId"] as? String
        ticket = dictionary["Ticket"] as? String
    }
    
    func dictionaryRepresentation() -> NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        dictionary.setValue(self.sessionId, forKey: "SessionId")
        dictionary.setValue(self.ticket, forKey: "Ticket")
        
        return dictionary
    }
    
}

//
//  Extensions.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 07/12/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation


extension Notification.Name {
    
    public static let SambaDownloadStateChanged = Notification.Name(rawValue: "SambaDownloadStateChangedNotification")
    static let SambaDRMErrorNotification = Notification.Name(rawValue: "SambaDRMErrorNotification")
    
}

@objc extension NSNotification {
    public static let SambaDownloadStateChanged = Notification.Name.SambaDownloadStateChanged
}

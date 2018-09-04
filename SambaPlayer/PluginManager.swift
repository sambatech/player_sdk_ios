//
//  PluginManager.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 31/08/2018.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation


protocol Plugin: class {
    func onLoadPlugin(with player: SambaPlayer)
    func onDestroyPlugin()
}


class PluginManager: Plugin {
    
    static var sharedInstance = PluginManager()
    
    private init(){}
    
    var plugins: [Plugin]?
    
    func onLoadPlugin(with player: SambaPlayer) {
        
         plugins = [
            getTracking(by: player.media.isLive)
         ]
        
         plugins?.forEach { $0.onLoadPlugin(with: player) }
    }
    
    func onDestroyPlugin() {
        plugins?.forEach { $0.onDestroyPlugin() }
        plugins = nil
    }
    
}

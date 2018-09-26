//
//  SambaCastButton.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 18/09/2018.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation
import GoogleCast


public class SambaCastButton: GCKUICastButton {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
    }
    
    public required init(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    @objc private func buttonClicked() {
        SambaCast.sharedInstance.isCastDialogShowing = true
    }
    
    deinit {
        removeTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
    }
}

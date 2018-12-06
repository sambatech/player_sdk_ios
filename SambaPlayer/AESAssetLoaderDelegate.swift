//
//  AESAssetLoaderDelegate.swift
//  SambaPlayer
//
//  Created by Kesley Vaz on 06/12/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import Foundation


class AESAssetLoaderDelegate: NSObject {
    
    /// The AVURLAsset associated with the asset.
    fileprivate let asset: AVURLAsset
    
    /// The name associated with the asset.
    fileprivate let assetName: String
    
    /// The document URL to use for saving persistent content key.
    fileprivate let documentURL: URL
    
    fileprivate var previousScheme: String
    
    init(asset: AVURLAsset, assetName: String, previousScheme: String) {
        // Determine the library URL.
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { fatalError("Unable to determine library URL") }
        documentURL = URL(fileURLWithPath: documentPath)
        
        self.asset = asset
        self.assetName = assetName
        self.previousScheme = previousScheme
        
        super.init()
        
        self.asset.resourceLoader.setDelegate(self, queue: DispatchQueue(label: "\(assetName)-delegateQueue"))
        self.asset.resourceLoader.preloadsEligibleContentKeys = true
    }
    
}



extension AESAssetLoaderDelegate: AVAssetResourceLoaderDelegate {
    
  
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        var component = URLComponents(url: loadingRequest.request.url!, resolvingAgainstBaseURL: true)
        component?.scheme = previousScheme
        
        loadingRequest.redirect = URLRequest(url: (component?.url)!)
        
        
        if let data = UserDefaults.standard.data(forKey: "teste") {
            loadingRequest.contentInformationRequest?.contentType = AVStreamingKeyDeliveryPersistentContentKeyType
            loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
            loadingRequest.contentInformationRequest?.contentLength = Int64(data.count)
            loadingRequest.dataRequest?.respond(with: data)
            UserDefaults.standard.set(data, forKey: "teste")
            loadingRequest.finishLoading()
        } else {
            let request = URLRequest(url: URL(string: "https://fast.player.liquidplatform.com/v3/v1/key/\(assetName)")!)
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                guard let data = data, error == nil else {
                    loadingRequest.finishLoading()
                    return
                }
                
                loadingRequest.contentInformationRequest?.contentType = AVStreamingKeyDeliveryPersistentContentKeyType
                loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
                loadingRequest.contentInformationRequest?.contentLength = Int64(data.count)
                loadingRequest.dataRequest?.respond(with: data)
                UserDefaults.standard.set(data, forKey: "teste")
                loadingRequest.finishLoading()
            }
            task.resume()
        }
        return true
    }
    

    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        
        return true
    }
    
}

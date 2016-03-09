//
//  SambaApi.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/9/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import Alamofire

public class SambaApi {
	
	public func requestMedia(request: SambaMediaRequest, callback: SambaMedia -> ()) {
		//let delimiter = request.mediaId != nil ? Int(request.mediaId.("(?=\\d[a-zA-Z]*$)")[1].substring(0, 1)) : 0;
		
		Alamofire.request(.GET, Commons.dict["playerapi_endpoint"]! + request.projectHash + (request.mediaId != nil ? "/" + request.mediaId! : "")).responseString { response in
			guard let token = response.result.value else {
				print("Error: No media response data!")
				return
			}
			
			print(token)
			
			//print(NSJSONSerialization.JSONObjectWithData(token, .AllowFragments))
		}
	}
}
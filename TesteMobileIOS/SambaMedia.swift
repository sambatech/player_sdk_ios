//
//  SambaModel.swift
//
//
//  Created by Leandro Zanol on 3/3/16.
//
//

class SambaMedia : CustomStringConvertible {
	var title:String
	var outputs:[Output]
	var thumb:String
	
	init(title:String, outputs:[Output], thumb:String) {
		self.title = title
		self.outputs = outputs
		self.thumb = thumb
	}
	
	var description:String { return title; }
}

struct Output {
	let url:String, label:String
}

/*var outputs = [Output]()

for jsonOutput in jsonNode["files"] as! [AnyObject] {
outputs.append(Output(
url: jsonOutput["url"] as? String ?? "",
label: jsonOutput["outputName"] as? String ?? ""))
}*/
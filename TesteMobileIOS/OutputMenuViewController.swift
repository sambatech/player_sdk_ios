//
//  OutputMenuViewController.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/23/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import UIKit

class OutputMenuViewController: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
	
	private let outputs: [SambaMedia.Output]
	
	init(_ outputs: [SambaMedia.Output]) {
		self.outputs = outputs
	}
	
	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		print(outputs.count)
		return outputs.count
	}
	
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		print(outputs[row].label)
		return outputs[row].label
	}
	
	func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		print("Selected \(row) row")
	}
}

//
//  OptionsMenuView.swift
//  SambaPlayer
//
//  Created by Luiz Henrique Bueno Byrro on 18/10/17.
//  Copyright © 2017 Samba Tech. All rights reserved.
//

import UIKit

class OptionsMenuView: UIViewController {

    
    @IBOutlet weak var qualityOptionView: UIView!
    @IBOutlet weak var speedOptionView: UIView!
    
    weak var delegate: MenuOptionsDelegate?
    
    var options: MenuOptions = .all {
        didSet {
            switch options {
            case .qualityOnly:
                speedOptionView.isHidden = true
                qualityOptionView.isHidden = false
                break
            case .speedOnly:
                speedOptionView.isHidden = false
                qualityOptionView.isHidden = true
                break
            default:
                speedOptionView.isHidden = false
                qualityOptionView.isHidden = false
                break
            }
        }
    }
    
    
    init(withOptions options: MenuOptions) {
        super.init(nibName: "OptionsMenuView", bundle: Bundle(for: type(of: self)))
        loadViewIfNeeded()
        self.options = options
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func didTouchOption(_ sender: UIButton) {
        switch sender.superview {
        case qualityOptionView?:
            delegate?.didTouchQuality()
            break
        case speedOptionView?:
            delegate?.didTouchSpeed()
            break
        default:
            break
        }
    }
    
    @IBAction func didTouchClose(_ sender: Any) {
        delegate?.didTouchClose()
    }
}


enum MenuOptions {
    case qualityOnly, speedOnly, all
}

protocol MenuOptionsDelegate: class {
    func didTouchQuality()
    func didTouchSpeed()
    func didTouchClose()
}

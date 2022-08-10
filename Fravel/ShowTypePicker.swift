//
//  ShowTypePicker.swift
//  Fravel
//
//  Created by 강태준 on 2022/08/11.
//

import Foundation
import UIKit


class ShowTypePicker: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
}

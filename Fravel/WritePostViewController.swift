//
//  WritePostViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/08/09.
//

import UIKit

class WritePostViewController: UIViewController {
    @IBOutlet weak var postButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.topItem?.title = ""
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func tapWrtieButton(_ sender: UIButton) {
        print("asdfasdf")
    }
}

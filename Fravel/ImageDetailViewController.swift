//
//  ImageDetailViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/08/09.
//

import UIKit
import Kingfisher


class ImageDetailViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    var imageURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureImageView()
    }
    
    func configureImageView() {
        guard let imageURL = imageURL else {
            return
        }
        
        imageView.kf.setImage(with: imageURL)
    }
}

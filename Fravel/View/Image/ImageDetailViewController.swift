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
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .light
        
        configureImageView()
    }
    
    func configureImageView() {
        if let imageURL = imageURL {
            imageView.kf.setImage(with: imageURL)
        } else if let image = image {
            imageView.image = image
        }
    }
}

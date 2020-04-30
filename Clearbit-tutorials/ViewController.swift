//
//  ViewController.swift
//  Clearbit-tutorials
//
//  Created by Rakesh Kumar on 10/04/20.
//  Copyright © 2020 Rakesh Kumar. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tf_companyNAme: CustomSearchTextField!
    @IBOutlet weak var companyLogo: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setCompanyLogo()
    }
    
    func setCompanyLogo() {
        CustomSearchTextField.setCompanyLogo = { logo in
            
            DispatchQueue.global().async { [weak self] in
                if let data = try? Data(contentsOf: URL(string: logo)!) {
                       if let image = UIImage(data: data) {
                           DispatchQueue.main.async {
                            self!.companyLogo.image = image
                           }
                       }
                   }
               }
        }
    }
}


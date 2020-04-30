//
//  CustomSearchTextField.swift
//  CustomSearchField
//
//  Created by Emrick Sinitambirivoutin on 19/02/2019.
//  Copyright © 2019 Emrick Sinitambirivoutin. All rights reserved.
//

import UIKit
import CoreData

class CustomSearchTextField: UITextField{
    
    var resultsList = [[String: Any]]()
    var tableView: UITableView?
    
    static var setCompanyLogo: ((_ urlString: String) ->())?
    
    // Connecting the new element to the parent view
    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        tableView?.removeFromSuperview()
        
    }
    
    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        self.addTarget(self, action: #selector(CustomSearchTextField.textFieldDidChange), for: .editingChanged)
        self.addTarget(self, action: #selector(CustomSearchTextField.textFieldDidBeginEditing), for: .editingDidBegin)
        self.addTarget(self, action: #selector(CustomSearchTextField.textFieldDidEndEditing), for: .editingDidEnd)
        self.addTarget(self, action: #selector(CustomSearchTextField.textFieldDidEndEditingOnExit), for: .editingDidEndOnExit)
    }
    
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        buildSearchTableView()
        
    }
    
    
    //////////////////////////////////////////////////////////////////////////////
    // Text Field related methods
    //////////////////////////////////////////////////////////////////////////////
    
    @objc open func textFieldDidChange(){
        print("Text changed ...")
        self.fetchCompanyName(name: self.text!)
    }
    
    @objc open func textFieldDidBeginEditing() {
        print("Begin Editing")
    }
    
    @objc open func textFieldDidEndEditing() {
        print("End editing")

    }
    
    @objc open func textFieldDidEndEditingOnExit() {
        print("End on Exit")
    }

}

extension CustomSearchTextField: UITableViewDelegate, UITableViewDataSource {
    // Create SearchTableview
    func buildSearchTableView() {

        if let tableView = tableView {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CustomSearchTextFieldCell")
            tableView.delegate = self
            tableView.dataSource = self
            self.window?.addSubview(tableView)

        } else {
            //addData()
            print("tableView created")
            tableView = UITableView(frame: CGRect.zero)
        }
        
        updateSearchTableView()
    }
    
    // Updating SearchtableView
    func updateSearchTableView() {
        
        if let tableView = tableView {
            superview?.bringSubviewToFront(tableView)
            var tableHeight: CGFloat = 0
            tableHeight = tableView.contentSize.height
            
            // Set a bottom margin of 10p
            if tableHeight < tableView.contentSize.height {
                tableHeight -= 10
            }
            
            // Set tableView frame
            var tableViewFrame = CGRect(x: 0, y: 0, width: frame.size.width - 4, height: tableHeight)
            tableViewFrame.origin = self.convert(tableViewFrame.origin, to: nil)
            tableViewFrame.origin.x += 2
            tableViewFrame.origin.y += frame.size.height + 10
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.tableView?.frame = tableViewFrame
            })
            
            //Setting tableView style
            tableView.layer.masksToBounds = true
            tableView.separatorInset = UIEdgeInsets.zero
            tableView.layer.cornerRadius = 5.0
            tableView.separatorColor = UIColor.lightGray
            tableView.backgroundColor = UIColor.white.withAlphaComponent(1.0)
            tableView.dropShadow()
            
            if self.isFirstResponder {
                superview?.bringSubviewToFront(self)
            }
            tableView.reloadData()
        }
    }
    
    
    
    // MARK: TableViewDataSource methods
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsList.count
    }
    
    // MARK: TableViewDelegate methods

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomSearchTextFieldCell", for: indexPath) as UITableViewCell
        cell.backgroundColor = UIColor.clear
        
        let dict = resultsList[indexPath.row]
        cell.textLabel?.text = dict["name"] as? String
        cell.detailTextLabel?.text = dict["domain"] as? String
        let logo = dict["logo"] as? String
        
//        DispatchQueue.global().async { [weak self] in
//            if let data = try? Data(contentsOf: URL(string: logo!)!) {
//                       if let image = UIImage(data: data) {
//                           DispatchQueue.main.async {
//                            cell.imageView?.image = self!.generateThumbImage(image: image)
//                           }
//                       }
//                   }
//               }
        
        DispatchQueue.global(qos: .background).async {
            if let data = try? Data(contentsOf: URL(string: logo!)!){
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        cell.imageView?.image = self.generateThumbImage(image: image)
                    }
                }
            }
        }
        
        return cell
    }
    
    func generateThumbImage(image: UIImage) -> UIImage{

        let thumbSize = CGSize(width: 30, height: 30)
        UIGraphicsBeginImageContext(thumbSize)
        image.draw(in: CGRect(x: 0, y: 0, width: thumbSize.width, height: thumbSize.height))
        let thumbImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return thumbImage!
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected row")
        let dict = resultsList[indexPath.row] as? [String: Any]
        self.text = dict!["name"] as? String
        let logo = dict!["logo"] as? String
        
        if let closure = CustomSearchTextField.setCompanyLogo {
            closure(logo!)
        }
        tableView.isHidden = true
        self.endEditing(true)
    }
    
}

extension CustomSearchTextField {
    func fetchCompanyName(name :String){
        print("INTER TEXT: ====== \(name)")
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        let strUrl = "https://autocomplete.clearbit.com/v1/companies/suggest?query=\(name)"
        let safeURL = strUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: safeURL)
        
        let task = session.dataTask(with: url!) { data, response, error in

            guard error == nil else {
                print ("error: \(error!)")
                return
            }
            guard let content = data else {
                print("No data")
                return
            }
            guard let json = (try? JSONSerialization.jsonObject(with: content, options: [])) as? [[String: Any]] else {
                print("Not containing JSON")
                return
            }
            
//            print("gotten json response dictionary is \n \(json)")
            DispatchQueue.main.async {
                self.resultsList = json
                self.updateSearchTableView()
                self.tableView?.isHidden = false
            }
        }
        task.resume()
    }
}


extension UIView {
    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.54
        layer.shadowOffset = CGSize(width: 0, height: 1.0)//.zero
        layer.shadowRadius = 4
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
}

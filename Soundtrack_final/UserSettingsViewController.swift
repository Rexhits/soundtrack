//
//  UserSettingsViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/6/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import Lockbox
import RSKImageCropper

class UserSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, RSKImageCropViewControllerDelegate {
    
    @IBOutlet weak var userSettingsTable: UITableView!
    
    @IBOutlet weak var playControlBar: UIView!
    
    
    
    var info = UserInfo()
    
    override func viewDidLoad() {
        userSettingsTable.delegate = self
        userSettingsTable.dataSource = self
        userSettingsTable.backgroundColor = UIColor.clear
        self.view.backgroundColor = UIColor.lightGray
    }
    override func viewWillAppear(_ animated: Bool) {
        info = UserInfo()
        fetch()
    }
    
    @IBAction func logout(_ sender: UIBarButtonItem) {
        print("Logged Out! \(Lockbox.archiveObject(nil, forKey: "Token")))")
        self.performSegue(withIdentifier: "logout", sender: self)
    }
    
    func fetch() {
        Server.get(api: "users/current", body: nil) { (response, err, errCode) in
            guard err == nil, errCode == nil else {
                switch errCode! {
                case 403:
                    print("Need re-login")
                default:
                    break
                }
                return
            }
            guard response != nil else {return}
            let res = response! as! JSONPackage
            self.info = UserInfo(json: res)
            self.userSettingsTable.reloadData()
        }
        

    }
    
    func patch(key: String, value: Any) {
        let para = [key: value]
        Server.patch(api: "users/\(info.id!)", body: para as JSONPackage) { (response, err, errCode) in
            guard err == nil, errCode == nil else {
                switch errCode! {
                case 403:
                    print("Need re-login")
                default:
                    break
                }
                return
            }
            guard response != nil else {return}
            let res = response! as! JSONPackage
            self.info = UserInfo(json: res)
            self.userSettingsTable.reloadData()
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return info.keys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = userSettingsTable.dequeueReusableCell(withIdentifier: "userSettingsCell", for: indexPath)
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.textColor = UIColor.lightText
        cell.detailTextLabel?.textColor = UIColor.white
        let selView = UIView()
        selView.backgroundColor = UIColor.orange
        selView.layer.cornerRadius = 10
        cell.selectedBackgroundView = selView
        if indexPath.row == 0 {
            cell.detailTextLabel?.text = ""
            cell.textLabel?.text = ""
            cell.contentView.layer.backgroundColor = UIColor.gray.cgColor
            let selView = UIView()
            selView.backgroundColor = UIColor.orange
            cell.selectedBackgroundView = selView
            let label = UILabel(frame: CGRect(origin: cell.center, size: CGSize(width: 110, height: 110)))
            label.font = label.font.withSize(20)
            label.textColor = UIColor.white
            var imgView = UIImageView()
            if info.avatar != nil {
                label.removeFromSuperview()
                let img = UIImage(data: info.avatar!)
                let resizedImg = resizeImage(image: img!, toTheSize: CGSize(width: 110, height: 110))
                imgView = UIImageView(image: resizedImg)
                imgView.layer.masksToBounds = false
                imgView.layer.cornerRadius = 55
                imgView.clipsToBounds = true
                imgView.center = cell.center
                cell.contentView.addSubview(imgView)
            } else {
                imgView.removeFromSuperview()
                label.text = "Add Avatar"
                label.textAlignment = NSTextAlignment.center
                label.center = cell.center
                cell.contentView.addSubview(label)
            }
            
        } else {
            cell.textLabel?.text = info.keys[indexPath.row - 1]
            if !info.values.isEmpty {
                cell.detailTextLabel?.text = info.values[indexPath.row - 1]
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 120
        } else {
            return 50
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let alerview = UIAlertController(title: "Choosing Photo", message: nil, preferredStyle: .actionSheet)
            alerview.view.tintColor = UIColor.orange
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            let library = UIAlertAction(title: "Choose From Library", style: .default, handler: { _ in
                imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
                self.present(imagePicker, animated: true, completion: nil)
            })
            let camera = UIAlertAction(title: "Taking Photo", style: .default, handler: { _ in
                imagePicker.sourceType = UIImagePickerControllerSourceType.camera
                self.present(imagePicker, animated: true, completion: nil)
            })
            alerview.addAction(library)
            alerview.addAction(camera)
            self.present(alerview, animated: true, completion: nil)
        } else {
            let title = "Editing \(info.keys[indexPath.row-1])"
            let alerview = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alerview.addTextField(configurationHandler: { textField in
                textField.placeholder = "Enter New \(self.info.keys[indexPath.row-1])"
            })
            let canel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let ok = UIAlertAction(title: "OK", style: .default) { action in
                self.patch(key: self.info.searchKeys[indexPath.row-1], value: alerview.textFields![0].text!)
            }
            alerview.addAction(canel)
            alerview.addAction(ok)
            self.present(alerview, animated: true, completion: nil)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        dismiss(animated: true) {
            let imageCropVC = RSKImageCropViewController(image: selectedImage)
            imageCropVC.delegate = self
            self.present(imageCropVC, animated: true, completion: nil)
        }
    }
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        dismiss(animated: true, completion: nil)
    }
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
        let resized = downsizeImage(image: croppedImage, toTheSize: CGSize(width: 500, height: 500))
        let imgData = UIImageJPEGRepresentation(resized, 0.5)
        Server.uploadAvatar(data: imgData!, filename: "\(self.info.username!).jpeg") { (response, err, errCode) in
            guard err == nil, errCode == nil else {
                switch errCode! {
                case 403:
                    print("Need re-login")
                default:
                    break
                }
                return
            }
            guard response != nil else {return}
            self.info = UserInfo(json: response!)
            self.userSettingsTable.reloadData()
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func resizeImage(image:UIImage, toTheSize size:CGSize)->UIImage{
        
        
        let scale = CGFloat(max(size.width/image.size.width,
                                size.height/image.size.height))
        let width:CGFloat  = image.size.width * scale
        let height:CGFloat = image.size.height * scale;
        
        let rr:CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0);
        image.draw(in: rr)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func downsizeImage(image:UIImage, toTheSize size:CGSize)->UIImage{
        
        
        let scale = CGFloat(max(size.width/image.size.width,
                                size.height/image.size.height))
        let width:CGFloat  = image.size.width * scale
        let height:CGFloat = image.size.height * scale;
        
        let rr:CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0);
        image.draw(in: rr)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

}

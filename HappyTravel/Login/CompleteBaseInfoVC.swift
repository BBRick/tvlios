//
//  CompleteBaseInfoVC.swift
//  HappyTravel
//
//  Created by 陈奕涛 on 16/9/9.
//  Copyright © 2016年 陈奕涛. All rights reserved.
//

import Foundation
import XCGLogger
import Alamofire
import SVProgressHUD
import Qiniu

class CompleteBaseInfoVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, AddressSelVCDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    var headerUrl:String?
    var table:UITableView?
    
    var token:String?
    
    var cityName: String? = NSUserDefaults.standardUserDefaults().valueForKey(UserDefaultKeys.homeLocation) as? String
    
    var headView:UIImageView?
    
    var headImagePath:String?
    
    var headImageName:String?
    
    var nickname:String?
    
    var sex = 0
    
    var address:String?
    
    var cells:Dictionary<Int, UITableViewCell> = [:]
    
    let tags = ["titleLab": 1001,
                "nicknameField": 1002,
                "description": 1003,
                "separateLine": 1004,
                "headBG": 1005,
                "headView": 1006,
                "selectedRetLab": 1007,
                "iconBtn": 1008]
    
    var imagePicker:UIImagePickerController? = nil
    
    var userInfoModel:UserInfoModel?
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "完善基本资料"
        userInfoModel = CurrentUser
        initView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //隐藏红点
        let viewHidden = tabBarController?.view.viewWithTag(10)
        viewHidden?.hidden = true
        //注册通知
        registerNotify()
        if navigationItem.rightBarButtonItem == nil {
            let sureBtn = UIButton.init(frame: CGRectMake(0, 0, 40, 30))
            sureBtn.setTitle("完成", forState: .Normal)
            sureBtn.titleLabel?.font = UIFont.systemFontOfSize(S18)
            sureBtn.setTitleColor(UIColor(red: 38/255.0, green: 38/255.0, blue: 38/255.0, alpha: 1), forState: .Normal)
            sureBtn.backgroundColor = UIColor.whiteColor()
            sureBtn.addTarget(self, action: #selector(sureAction(_:)), forControlEvents: .TouchUpInside)
            
            let sureItem = UIBarButtonItem.init(customView: sureBtn)
            navigationItem.rightBarButtonItem = sureItem
            
        }
        
        APIHelper.commonAPI().uploadPhotoToken( { [weak self](response) in
            if let model = response as? UploadPhotoModel {
                self?.token = model.img_token_
            }
            }, error: { (err) in
                
        })
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
    }
    
    func sureAction(sender: UIButton) {
        guard headImageName != nil || CurrentUser.head_url_ != nil else {
            SVProgressHUD.showWainningMessage(WainningMessage: "您还没有上传头像哦", ForDuration: 1.5, completion: nil)
            return
        }

        let nicknameField = self.cells[1]?.contentView.viewWithTag(self.tags["nicknameField"]!) as? UITextField
        guard nicknameField?.text?.characters.count > 0 else {
            
            SVProgressHUD.showWainningMessage(WainningMessage: "您还没有填写用户名哦", ForDuration: 1.5, completion: nil)
            return
        }
        let sexLab = self.cells[2]?.contentView.viewWithTag(self.tags["selectedRetLab"]!) as? UILabel
        guard sexLab?.text?.characters.count > 0 else {
            SVProgressHUD.showWainningMessage(WainningMessage: "您还没有选择性别呢", ForDuration: 1.5, completion: nil)

            return
        }
        guard address?.characters.count > 0 else {
            SVProgressHUD.showWainningMessage(WainningMessage: "您还没有选择常住地哦", ForDuration: 1.5, completion: nil)
            return
        }
        
        guard headImagePath != nil else {
            updateBaseInfo((userInfoModel?.head_url_)!)
            
            return
        }
        let qiniuHost = "http://ofr5nvpm7.bkt.clouddn.com/"
        let qnManager = QNUploadManager()
        SVProgressHUD.showProgressMessage(ProgressMessage: "提交中...")
        unowned let weakSelf = self
        qnManager.putFile(headImagePath!, key: "user_center/head\(headImageName!)", token: token!, complete: { (info, key, resp) -> Void in
            
            if info.statusCode != 200 || resp == nil {
                self.navigationItem.rightBarButtonItem?.enabled = true
                SVProgressHUD.showErrorMessage(ErrorMessage: "提交失败，请稍后再试！", ForDuration: 1, completion: nil)
                return
            }
            
            if (info.statusCode == 200 ){
                let respDic: NSDictionary? = resp
                let value:String? = respDic!.valueForKey("key") as? String
                let url = qiniuHost + value!
                weakSelf.updateBaseInfo(url)
            }
            
        }, option: nil)
        
    }
    
    /**
     - parameter url:
     */
    func updateBaseInfo(url:String) {
        let UTF8Adress = address?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
        let addr = "http://restapi.amap.com/v3/geocode/geo?key=389880a06e3f893ea46036f030c94700&s=rsv3&city=35&address=\(UTF8Adress!)"
        Alamofire.request(.GET, addr).responseJSON() { response in
            
            if let info = (response.result.value as? Dictionary<String, AnyObject>) {
                
                if let array = info["geocodes"] as? Array<Dictionary<String, AnyObject>> {
                    
                    let geocodes = array.first
                    
                    let location = (geocodes!["location"] as! String).componentsSeparatedByString(",")
                    XCGLogger.debug("\(location)")
                    
                    let nicknameField = self.cells[1]?.contentView.viewWithTag(self.tags["nicknameField"]!) as? UITextField
                    self.nickname = nicknameField?.text
                    self.headerUrl = url
                    
                    let req = ModifyUserInfoModel()
                    req.uid_ = CurrentUser.uid_
                    req.nickname_ = self.nickname
                    req.gender_ = self.sex
                    req.head_url_ = url
                    req.address_ = self.address
                    req.longitude_ = Float.init(location[0])!
                    req.latitude_ = Float.init(location[1])!
                    APIHelper.userAPI().modifyUserInfo(req, complete: { [weak self](response) in
                        SVProgressHUD.showSuccessWithStatus("设置成功")
                        self?.navigationController?.popViewControllerAnimated(true)
                        CurrentUser.head_url_ = self?.headerUrl
                        CurrentUser.nickname_ = self?.nickname
                        CurrentUser.gender_ = self!.sex
                        CurrentUser.address_ = self?.address
                        CurrentUser.currentBanckCardName_ = self?.nickname
                        CurrentUser.register_status_ = 1
                        NSNotificationCenter.defaultCenter().postNotificationName(NotifyDefine.ImproveDataNoticeToOthers, object: nil, userInfo: nil)
                        }, error: { (err) in
                            SVProgressHUD.showWainningMessage(WainningMessage: "修改资料失败，请重试", ForDuration: 1.5, completion: nil)
                    })
                }
            }
            //            let geocodes = ((response.result.value as? Dictionary<String, AnyObject>)!["geocodes"] as! Array<Dictionary<String, AnyObject>>).first
            
        }
    }
    
    func initView() {
        table = UITableView(frame: CGRectZero, style: .Plain)
        table?.delegate = self
        table?.dataSource = self
        table?.estimatedRowHeight = 60
        table?.rowHeight = UITableViewAutomaticDimension
        table?.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        table?.separatorStyle = .None
        table?.backgroundColor = UIColor.init(decR: 241, decG: 242, decB: 243, a: 1)
        view.addSubview(table!)
        table?.snp_makeConstraints(closure: { (make) in
            make.edges.equalTo(view)
        })
        
        hideKeyboard()
    }
    
    func hideKeyboard() {
        let touch = UITapGestureRecognizer.init(target: self, action: #selector(touchWhiteSpace))
        touch.numberOfTapsRequired = 1
        touch.cancelsTouchesInView = false
        table?.addGestureRecognizer(touch)
    }
    
    func touchWhiteSpace() {
        view.endEditing(true)
    }
    
    func registerNotify() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    func keyboardWillShow(notification: NSNotification?) {
        let frame = notification!.userInfo![UIKeyboardFrameEndUserInfoKey]!.CGRectValue()
        let inset = UIEdgeInsetsMake(0, 0, frame.size.height, 0)
        table?.contentInset = inset
        table?.scrollIndicatorInsets = inset
    }
    
    func keyboardWillHide(notification: NSNotification?) {
        let inset = UIEdgeInsetsMake(0, 0, 0, 0)
        table?.contentInset = inset
        table?.scrollIndicatorInsets =  inset
    }
    
    //MARK: - TableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            var cell = tableView.dequeueReusableCellWithIdentifier("BaseInfoHeadCell")
            if cell == nil {
                cell = UITableViewCell()
                cell?.accessoryType = .None
                cell?.backgroundColor = UIColor.clearColor()
                cell?.contentView.backgroundColor = UIColor.clearColor()
                cell?.selectionStyle = .None
            }
            
            var bgView = cell?.contentView.viewWithTag(tags["headBG"]!)
            if bgView == nil {
                bgView = UIView()
                bgView?.backgroundColor = UIColor.clearColor()
                cell?.contentView.addSubview(bgView!)
                bgView?.snp_makeConstraints(closure: { (make) in
                    make.left.equalTo(cell!.contentView)
                    make.right.equalTo(cell!.contentView)
                    make.top.equalTo(cell!.contentView)
                    make.bottom.equalTo(cell!.contentView)
                    make.height.equalTo(UIScreen.mainScreen().bounds.size.width / 2.0)
                })
            }
        
            var headView = cell?.contentView.viewWithTag(tags["headView"]!) as? UIImageView
            if headView == nil {
                headView = UIImageView()
                headView?.tag = tags["headView"]!
                headView?.layer.cornerRadius = 100 / 2.0
                headView?.layer.masksToBounds = true
                headView?.image = UIImage.init(named: "default-head")
                cell?.contentView.addSubview(headView!)
                headView?.snp_makeConstraints(closure: { (make) in
                    make.center.equalTo(bgView!)
                    make.width.equalTo(100)
                    make.height.equalTo(100)
                })
                
            }
            self.headView = headView
            cells[indexPath.row] = cell!
            
            var iconBtn = cell?.contentView.viewWithTag(tags["iconBtn"]!) as? UIButton
            if iconBtn == nil {
                iconBtn = UIButton()
                iconBtn?.tag = tags["iconBtn"]!
                cell?.contentView.addSubview(iconBtn!)
                iconBtn?.snp_makeConstraints(closure: { (make) in
                    make.center.equalTo(headView!)
                    make.width.equalTo(headView!)
                    make.height.equalTo(headView!)
                })
                iconBtn?.addTarget(self, action: #selector(iconBtnDidClick), forControlEvents: UIControlEvents.TouchUpInside)
            }
            
            guard headImageName == nil else {
                return cell!
            }
            
            guard userInfoModel != nil else {
                return cell!
            }
            guard userInfoModel?.head_url_ != nil else {
                return cell!
            }
            
            
            if userInfoModel!.head_url_!.hasPrefix("http"){
                
                let headUrl = NSURL(string: userInfoModel!.head_url_!)
                headView?.kf_setImageWithURL(headUrl, placeholderImage: UIImage(named: "default-head"), optionsInfo: nil, progressBlock: nil) { (image, error, cacheType, imageURL) in
                    
                }
            } else if userInfoModel!.head_url_!.hasPrefix("var"){
                let headerUrl = NSURL(fileURLWithPath: userInfoModel!.head_url_!)
                headView?.kf_setImageWithURL(headerUrl, placeholderImage: UIImage(named: "default-head"), optionsInfo: nil, progressBlock: nil) { (image, error, cacheType, imageURL) in
                    
                }
            }
            return cell!
        } else {
            var cell = tableView.dequeueReusableCellWithIdentifier("BaseInfoCell")
            if cell == nil {
                cell = UITableViewCell()
                cell?.selectionStyle = .None
            }
            cell?.accessoryType = indexPath.row == 1 ? .None : .DisclosureIndicator
            
            var titleLab = cell?.contentView.viewWithTag(tags["titleLab"]!) as? UILabel
            if titleLab == nil {
                titleLab = UILabel()
                titleLab?.tag = tags["titleLab"]!
                titleLab?.backgroundColor = UIColor.clearColor()
                titleLab?.textColor = UIColor.blackColor()
                titleLab?.font = UIFont.systemFontOfSize(S15)
                cell?.contentView.addSubview(titleLab!)
                titleLab?.snp_makeConstraints(closure: { (make) in
                    make.left.equalTo(cell!.contentView).offset(20)
                    make.centerY.equalTo(cell!.contentView)
                    make.width.equalTo(100)
                })
            }
            let title = ["昵称", "性别", "常住地"]
            titleLab?.text = title[indexPath.row - 1]
            
            var separateLine = cell?.contentView.viewWithTag(tags["separateLine"]!)
            if separateLine == nil {
                separateLine = UIView()
                separateLine?.tag = tags["separateLine"]!
                separateLine?.backgroundColor = UIColor.init(red: 241/255.0, green: 242/255.0, blue: 243/255.0, alpha: 1)
                cell?.contentView.addSubview(separateLine!)
                separateLine?.snp_makeConstraints(closure: { (make) in
                    make.left.equalTo(titleLab!)
                    make.right.equalTo(cell!.contentView).offset(40)
                    make.bottom.equalTo(cell!.contentView).offset(0.5)
                    make.height.equalTo(1)
                })
            }
            separateLine?.hidden = (indexPath.row == 0 || indexPath.row == 3) ? true : false
            
            var nicknameField = cell?.contentView.viewWithTag(tags["nicknameField"]!) as? UITextField
            if nicknameField == nil {
                nicknameField = UITextField()
                nicknameField!.tag = tags["nicknameField"]!
                nicknameField!.secureTextEntry = false
                nicknameField!.delegate = self
                nicknameField!.textColor = UIColor.blackColor()
                nicknameField!.rightViewMode = .WhileEditing
                nicknameField!.clearButtonMode = .WhileEditing
                nicknameField!.backgroundColor = UIColor.clearColor()
                nicknameField!.textAlignment = .Right
                nicknameField!.attributedPlaceholder = NSAttributedString.init(string: "10个字符以内", attributes: [NSForegroundColorAttributeName: UIColor.grayColor()])
                cell?.contentView.addSubview(nicknameField!)
                nicknameField!.snp_makeConstraints(closure: { (make) in
                    make.left.equalTo(titleLab!)
                    make.top.equalTo(cell!.contentView).offset(10)
                    make.bottom.equalTo(cell!.contentView).offset(-10)
                    make.right.equalTo(cell!.contentView).offset(-20)
                    make.height.equalTo(25)
                })
            }
            nicknameField?.hidden = indexPath.row == 1 ? false : true
            
            var selectedRetLab = cell?.contentView.viewWithTag(tags["selectedRetLab"]!) as? UILabel
            if selectedRetLab == nil {
                selectedRetLab = UILabel()
                selectedRetLab?.tag = tags["selectedRetLab"]!
                selectedRetLab?.backgroundColor = UIColor.clearColor()
                selectedRetLab?.textColor = UIColor.grayColor()
                selectedRetLab?.textAlignment = .Right
                selectedRetLab?.font = UIFont.systemFontOfSize(S15)
                cell?.contentView.addSubview(selectedRetLab!)
                selectedRetLab?.snp_makeConstraints(closure: { (make) in
                    make.right.equalTo(cell!.contentView).offset(-10)
                    make.centerY.equalTo(titleLab!)
                })
            }
            
            cells[indexPath.row] = cell!
            
            
            guard userInfoModel != nil else {
                return cell!
            }
            
            if userInfoModel?.nickname_ != nil {
                nicknameField?.text = userInfoModel?.nickname_
                nickname = userInfoModel?.nickname_
            }
            
            if indexPath.row == 2 {
                sex = (userInfoModel?.gender_)!
                selectedRetLab?.text = userInfoModel?.gender_ == 0 ? "女" : "男"
            } else if indexPath.row == 3 {
                if userInfoModel?.address_ != nil && userInfoModel?.address_?.characters.count > 0 {
                    address = userInfoModel?.address_
                    selectedRetLab?.text = userInfoModel?.address_
                }else{
                    address = cityName
                    selectedRetLab?.text = cityName
                }
            }
            
            return cell!
        }

    }
    //头像按钮点击弹出相册
    func iconBtnDidClick() {
        view.endEditing(true)
        setHeadImage()
    }
    
    func setHeadImage() {
        initImagePick()

        let sheetController = UIAlertController.init(title: "选择图片", message: nil, preferredStyle: .ActionSheet)
        let cancelAction:UIAlertAction! = UIAlertAction.init(title: "取消", style: .Cancel) { action in
            
        }
        let cameraAction:UIAlertAction! = UIAlertAction.init(title: "相机", style: .Default) { action in
            self.imagePicker?.sourceType = .Camera
            self.presentViewController(self.imagePicker!, animated: true, completion: nil)
            self.updateRedHot()
        }
        let labAction:UIAlertAction! = UIAlertAction.init(title: "从系统相册中选择", style: .Default) { action in
            self.imagePicker?.sourceType = .PhotoLibrary
            self.presentViewController(self.imagePicker!, animated: true, completion: nil)
            self.updateRedHot()
        }
        sheetController.addAction(cancelAction)
        sheetController.addAction(cameraAction)
        sheetController.addAction(labAction)
        presentViewController(sheetController, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            view.endEditing(true)
        } else if indexPath.row == 2 {
            XCGLogger.debug("性别选择")
            let alertCtrl = UIAlertController.init(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            let male = UIAlertAction.init(title: "男", style: .Default, handler: { (sender: UIAlertAction) in
                self.sex = 1
                let sexLab = self.cells[2]?.contentView.viewWithTag(self.tags["selectedRetLab"]!) as? UILabel
                sexLab?.text = "男"
            })
            
            let female = UIAlertAction.init(title: "女", style: .Default, handler: { (sender: UIAlertAction) in
                self.sex = 0
                let sexLab = self.cells[2]?.contentView.viewWithTag(self.tags["selectedRetLab"]!) as? UILabel
                sexLab?.text = "女"
            })
            
            let cancel = UIAlertAction.init(title: "取消", style: .Cancel, handler: { (sender: UIAlertAction) in
                
            })
            
            alertCtrl.addAction(male)
            alertCtrl.addAction(female)
            alertCtrl.addAction(cancel)
            
            presentViewController(alertCtrl, animated: true, completion: nil)
            
        } else if indexPath.row == 3 {
            XCGLogger.debug("常住地选择")
            let addressSelVC = AddressSelVC()
            addressSelVC.delegate = self
            navigationController?.pushViewController(addressSelVC, animated: true)
        }
    }
    
    //MARK: - UITextField
    func textFieldShouldClear(textField: UITextField) -> Bool {
        switch textField.tag {
        case tags["nicknameField"]!:
            nickname = textField.text
            break
        default:
            break
        }
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if range.location > 9 {
            return false
        }
        if textField.tag == tags["nicknameField"]! {
            nickname = textField.text! + string
        }
        
        return true
    }

    //MARK: - AddressSelVCDelegate
    func addressSelected(address: String?) {
        self.address = address
        let addressLab = self.cells[3]?.contentView.viewWithTag(self.tags["selectedRetLab"]!) as? UILabel
        addressLab?.text = address!
        XCGLogger.debug("\(self.address!)")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIImagePickreControllerDelegate
    func initImagePick() {
        if imagePicker == nil {
            imagePicker = UIImagePickerController()
            imagePicker?.delegate = self
            imagePicker?.allowsEditing = true
        }
    }
    
    //模态跳转之后我的消费小红点的消失Bug处理
    func updateRedHot() {
        //评价完的时候请求订单数据,更新个人中心我的消费红点显示
        var count = 0
        let req = OrderListRequestModel()
        req.uid_ = CurrentUser.uid_
        APIHelper.consumeAPI().orderList(req, complete: { (response) in
            if let models = response as? [OrderListCellModel]{
                for model in models{
                    if model.is_evaluate_ == 0 {
                        count = count + 1
                    } else {
                        continue
                    }
                }
                
                if count == 0 {
                    NSNotificationCenter.defaultCenter().postNotificationName(NotifyDefine.OrderListNo, object: nil, userInfo: nil)
                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName(NotifyDefine.OrderList, object: nil, userInfo: nil)
                }
            }
            },error:{ (error) in
        })

    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        headView?.image = image.reSizeImage(CGSizeMake(100, 100))
        
        imagePicker?.dismissViewControllerAnimated(true, completion: nil)
        
        //先把图片转成NSData
        let data = UIImageJPEGRepresentation(image, 0.5)
        //图片保存的路径
        //这里将图片放在沙盒的documents文件夹中
        
        //Home目录
        let homeDirectory = NSHomeDirectory()
        let documentPath = homeDirectory + "/Documents"
        //文件管理器
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        //把刚刚图片转换的data对象拷贝至沙盒中 并保存为image.png
        do {
            try fileManager.createDirectoryAtPath(documentPath, withIntermediateDirectories: true, attributes: nil)
            
        }
        catch _ {
        }
        let timestemp:Int = Int(NSDate().timeIntervalSince1970)
        let fileName = "/\(CurrentUser.uid_)_\(timestemp).png"
        headImageName = fileName
        fileManager.createFileAtPath(documentPath.stringByAppendingString(fileName), contents: data, attributes: nil)
        //得到选择后沙盒中图片的完整路径
        let filePath: String = String(format: "%@%@", documentPath, fileName)
        headImagePath = filePath
    }
    
}


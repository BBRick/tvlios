//
//  ServantPersonalVC.swift
//  HappyTravel
//
//  Created by 陈奕涛 on 16/8/4.
//  Copyright © 2016年 陈奕涛. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import XCGLogger
import RealmSwift

public class ServantPersonalVC : UIViewController, UITableViewDelegate, UITableViewDataSource, ServiceCellDelegate, PhotosCellDelegate, ServiceSheetDelegate {
    //记录是邀约？预约？   ture为邀约  false 为预约
    var isNormal = true
    
    var personalInfo:UserInfoModel?
    var detailInfo:ServantDetailModel?
    var personalTable:UITableView?
    var bottomBar:UIImageView?
    var serviceSpread = true
    var invitaionVC = InvitationVC()
    var alertController:UIAlertController?
    var appointment_id_ = 0
    
    var service_price_oneday:Int?
    
    var daysAlertController:UIAlertController?
    
    var selectedServcie:ServiceModel?
    var photoModel:PhotoWallModel?
    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }
    
    func initView() {
        view.backgroundColor = UIColor.init(red: 33/255.0, green: 59/255.0, blue: 76/255.0, alpha: 1)
        title = personalInfo?.nickname_
        
        detailInfo = DataManager.getData(ServantDetailModel.self, filter: "uid_ = \(personalInfo!.uid_)")?.first
        
        bottomBar = UIImageView()
        bottomBar?.userInteractionEnabled = true
        bottomBar?.image = UIImage.init(named: "bottom-selector-bg")
        view.addSubview(bottomBar!)
        bottomBar?.snp_makeConstraints(closure: { (make) in
            make.left.equalTo(view)
            make.right.equalTo(view)
            make.bottom.equalTo(view)
            make.height.equalTo(50)
        })
        
        let chatBtn = UIButton()
        chatBtn.tag = 1001
        chatBtn.setTitle("开始聊天", forState: .Normal)
        chatBtn.backgroundColor = UIColor.clearColor()
        chatBtn.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        chatBtn.addTarget(self, action: #selector(bottomBarAction(_:)), forControlEvents: .TouchUpInside)
        bottomBar?.addSubview(chatBtn)
        chatBtn.snp_makeConstraints { (make) in
            make.left.equalTo(bottomBar!)
            make.top.equalTo(bottomBar!)
            make.bottom.equalTo(bottomBar!)
            make.right.equalTo(bottomBar!.snp_centerX)
        }
        let invitationBtn = UIButton()
        invitationBtn.tag = 1002
        invitationBtn.setTitle( isNormal ? "发起邀约" : "发起预约", forState: .Normal)
        invitationBtn.backgroundColor = UIColor.clearColor()
        invitationBtn.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        invitationBtn.addTarget(self, action: #selector(bottomBarAction(_:)), forControlEvents: .TouchUpInside)
        bottomBar?.addSubview(invitationBtn)
        invitationBtn.snp_makeConstraints { (make) in
            make.right.equalTo(bottomBar!)
            make.top.equalTo(bottomBar!)
            make.bottom.equalTo(bottomBar!)
            make.left.equalTo(bottomBar!.snp_centerX)
        }
        
        personalTable = UITableView(frame: CGRectZero, style: .Plain)
        personalTable!.registerClass(PersonalHeadCell.self, forCellReuseIdentifier: "PersonalHeadCell")
        personalTable!.registerClass(TallyCell.self, forCellReuseIdentifier: "TallyCell")
        personalTable!.registerClass(ServiceCell.self, forCellReuseIdentifier: "ServiceCell")
        personalTable!.registerClass(PhotosCell.self, forCellReuseIdentifier: "PhotosCell")
        personalTable!.tag = 1001
        personalTable!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        personalTable!.dataSource = self
        personalTable!.delegate = self
        personalTable!.estimatedRowHeight = 400
        personalTable!.rowHeight = UITableViewAutomaticDimension
        personalTable!.separatorStyle = .None
        personalTable!.backgroundColor = UIColor.init(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        view.addSubview(personalTable!)
        personalTable!.snp_makeConstraints { (make) in
            make.left.equalTo(view)
            make.right.equalTo(view)
            make.top.equalTo(view)
            make.bottom.equalTo(bottomBar!.snp_top)
        }
        
    }
    
    /**
     下面沟通 或者 邀约操作
     
     - parameter sender:
     */
    func bottomBarAction(sender: UIButton?) {
        if CurrentUser.has_recharged_ == 0 {
            let alert = UIAlertController.init(title: "余额不足", message: "服务者的最低价格为200元，还需充值200元", preferredStyle: .Alert)

            let ok = UIAlertAction.init(title: "确定", style: .Default, handler: { (action: UIAlertAction) in
                let rechargeVC = RechargeVC()
                self.navigationController?.pushViewController(rechargeVC, animated: true)
                
            })
            
            let cancel = UIAlertAction.init(title: "取消", style: .Cancel, handler: nil)
            alert.addAction(ok)
            alert.addAction(cancel)
            
            presentViewController(alert, animated: true, completion: nil)
            return
        }

        if sender?.tag == 1001 {
            let chatVC = ChatVC()
            chatVC.servantInfo = personalInfo
            navigationController?.pushViewController(chatVC, animated: true)
        } else if sender?.tag == 1002 {
            invitation()

        }
        
    }
    
    func invitation() {
        if alertController == nil {
            alertController = UIAlertController.init(title: "", message: nil, preferredStyle: .ActionSheet)
            let sheet = ServiceSheet()
            sheet.servantInfo = personalInfo
            sheet.servantDetail = detailInfo
            sheet.isNormal = isNormal
            sheet.delegate = self
            alertController!.view.addSubview(sheet)
            sheet.snp_makeConstraints { (make) in
                make.left.equalTo(alertController!.view).offset(-10)
                make.right.equalTo(alertController!.view).offset(10)
                make.bottom.equalTo(alertController!.view).offset(10)
                make.top.equalTo(alertController!.view).offset(-10)
            }
        }
        
        presentViewController(alertController!, animated: true, completion: nil)
        
    }
    
    // MARK: - ServiceSheetDelegate
    func cancelAction(sender: UIButton?) {
        alertController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /**
     邀约或者预约确定
     
     - parameter service:
     - parameter daysCount:
     */
    func sureAction(service: ServiceModel?, daysCount: Int?) {
        service_price_oneday = service?.service_price_
        
        if !isNormal { // 预约
            alertController?.dismissViewControllerAnimated(true, completion: nil)
            
//            let arrry = DataManager.getAppointmentRecordInfos(appointment_id_)
//            let appointmentInfo:AppointmentInfo? = arrry?.first
            
            // 预约天数
            let dayNum:Double = 1.0 // Double(((appointmentInfo?.end_time_)! - (appointmentInfo?.start_time_)!) / (24 * 60 * 60))
            
            // 预约总金额
            let totalMoney = service_price_oneday! * Int(dayNum)
            let currentCash = CurrentUser.user_cash_
            if currentCash >= totalMoney { // 余额充足
                let appointmentRequestModel = AppointmentServantRequestMdoel()
                appointmentRequestModel.appointment_id_ = appointment_id_
                appointmentRequestModel.service_id_ = service!.service_id_
                appointmentRequestModel.to_uid_ = personalInfo!.uid_
                appointmentRequestModel.from_uid_ = CurrentUser.uid_
                APIHelper.servantAPI().appointment(appointmentRequestModel, complete: { (response) in

                    let model = response as? AppointmentServantReplyMdoel
                    guard model != nil else {return}
                    var msg = "预约发起成功，等待对方接受邀请"
                    if model?.is_asked_ == 1 {
                        msg = "预约失败，您已经预约过对方"
                        let alert = UIAlertController.init(title: "预约状态",message: msg,preferredStyle: .Alert)
                        let action = UIAlertAction.init(title: "确定", style: .Default, handler: { (action: UIAlertAction) in })
                        alert.addAction(action)
                        self.presentViewController(alert, animated: true) {
                            DataManager.removeData(ChatSessionModel.self, filter: "uid_ = \(self.appointment_id_)")
                        }
                    }
                    }, error: { (error) in
                })
                
            } else {
                let alert = UIAlertController.init(title: "余额不足", message: "服务价格为\(totalMoney/100)元，还差\((totalMoney - currentCash)/100)元", preferredStyle: .Alert)
                
                let ok = UIAlertAction.init(title: "去充值", style: .Default, handler: { (action: UIAlertAction) in
                    let rechargeVC = RechargeVC()
                    rechargeVC.chargeNumber = totalMoney - currentCash
                    self.navigationController?.pushViewController(rechargeVC, animated: true)
                    
                })
                
                let cancel = UIAlertAction.init(title: "取消", style: .Cancel, handler: nil)
                alert.addAction(ok)
                alert.addAction(cancel)
                
                presentViewController(alert, animated: true, completion: nil)
            }
            
        } else { // 邀约
            unowned let weakSelf = self
            weakSelf.selectedServcie = service

            alertController?.dismissViewControllerAnimated(true, completion: {
                //移除天数选泽,默认一天
//                weakSelf.performSelector(#selector(ServantPersonalVC.inviteAction), withObject: nil, afterDelay: 0.2)
                weakSelf.daysSureAction(nil, targetDays: 1)
                //弹出保险页面
//                let insuranceVc = InsuranceVC()
//                insuranceVc.order_price = Int64(service!.service_price_)
//                self.navigationController?.pushViewController(insuranceVc, animated: true)
                
            })
        }

    }
    

    func inviteAction() {
        unowned let weakSelf = self
        if daysAlertController == nil {
            daysAlertController = UIAlertController.init(title: "", message: nil, preferredStyle: .ActionSheet)
            let sheet = CitysSelectorSheet()
            let days = [1, 2, 3, 4, 5, 6, 7]
           sheet.daysList = days
            sheet.delegate = self
            daysAlertController!.view.addSubview(sheet)
            sheet.snp_makeConstraints { (make) in
                make.left.equalTo(weakSelf.daysAlertController!.view).offset(-10)
                make.right.equalTo(weakSelf.daysAlertController!.view).offset(10)
                make.bottom.equalTo(weakSelf.daysAlertController!.view).offset(10)
                make.top.equalTo(weakSelf.daysAlertController!.view)
            }
        }
        
        presentViewController(weakSelf.daysAlertController!, animated: true, completion: nil)
    }
    func back() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        
    }
    
    func registerNotify() {
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(invitationResult(_:)), name: NotifyDefine.AskInvitationResult, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(receivedResults(_:)), name: NotifyDefine.AppointmentServantReply, object: nil)
        
    }
    
    /**
     预约回调
     
     - parameter notifucation:
     */
//    func receivedResults(notifucation: NSNotification?) {
//
//        
////        YD_ContactManager.checkIfUploadContact()
//
//        let dict = notifucation?.userInfo!["data"] as? Dictionary<String , AnyObject>
//        
//        var msg = "预约发起成功，等待对方接受邀请"
//        if dict!["is_asked_"] as! Int == 1 {
//            msg = "预约失败，您已经预约过对方"
//
//        }
//        
//        let alert = UIAlertController.init(title: "预约状态",
//                                           message: msg,
//                                           preferredStyle: .Alert)
//        
//
//        let action = UIAlertAction.init(title: "确定", style: .Default, handler: { (action: UIAlertAction) in
//            
//        })
//        
//        alert.addAction(action)
//
//        presentViewController(alert, animated: true) {
//            /**
//             预约完成 删除 推送的预约消息 测试状态 暂时不删
//             */
////            DataManager.deletePushMessage(appointment_id_)
//        }
//    }
    /**
     邀约回调
     
     - parameter notifucation:
     */
//    func invitationResult(notifucation: NSNotification?) {
//        
////        YD_ContactManager.checkIfUploadContact()
//        var msg = ""
//        if let err = SocketManager.getError((notifucation?.userInfo as? [String: AnyObject])!) {
//            msg = err.values.first!
//        }
//        
//        if let order = notifucation?.userInfo!["orderInfo"] as? HodometerInfo {
//            if msg == "" {
//                msg = order.is_asked_ == 0 ? "邀约发起成功，等待对方接受邀请" : "邀约失败，您已经邀约过对方"
//            }
//            let alert = UIAlertController.init(title: "邀约状态",
//                                               message: msg,
//                                               preferredStyle: .Alert)
//            
//            let action = UIAlertAction.init(title: "确定", style: .Default, handler: { (action: UIAlertAction) in
//                
//            })
//            alert.addAction(action)
//            presentViewController(alert, animated: true, completion: nil)
//            
//        }
//    }
    
    func requestPhoto() {
        if personalInfo != nil {
            let dict = ["uid_": personalInfo!.uid_,
                        "size_": 12,
                        "num_": 1]
            let model = PhotoWallRequestModel(value: dict)
            APIHelper.servantAPI().requestPhotoWall(model, complete: { (response) in
                
                self.photoModel = response as? PhotoWallModel
                self.personalTable?.reloadSections(NSIndexSet.init(index: 3), withRowAnimation: .Fade)
            }) { (error) in
                
            }
        }
        
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(false)
        personalTable!.reloadData()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerNotify()
        requestPhoto()

        guard isNormal else { return }
        if navigationItem.rightBarButtonItem == nil {
            let msgItem = UIBarButtonItem.init(image: UIImage.init(named: "nav-msg"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(msgAction(_:)))
            navigationItem.rightBarButtonItem = msgItem
        }
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
    }
    
    /**
    push to 聊天页面
     - parameter sender:
     */
    func msgAction(sender: AnyObject?) {
        let msgVC = PushMessageVC()

        if sender?.isKindOfClass(UIButton) == false {
            navigationController?.pushViewController(msgVC, animated: false)
            if let userInfo = sender as? [NSObject: AnyObject] {
                let type = userInfo["type"] as? Int
                if type == PushMessage.MessageType.Chat.rawValue {
                    performSelector(#selector(ForthwithVC.postPushMessageNotify(_:)), withObject: userInfo["data"], afterDelay: 0.5)
                }
            }
            
        } else {
            navigationController?.pushViewController(msgVC, animated: true)
        }
        
    }
    
    // MARK -- UITableViewDelegate & UITableViewDataSource
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("PersonalHeadCell", forIndexPath: indexPath) as! PersonalHeadCell
            cell.setInfo(personalInfo, servantDetail: detailInfo , detailInfo: nil)
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("TallyCell", forIndexPath: indexPath) as! TallyCell
            cell.setInfo(detailInfo?.tags)
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCellWithIdentifier("ServiceCell", forIndexPath: indexPath) as! ServiceCell
            cell.delegate = self
            cell.setInfo(detailInfo?.service_list_, setSpread: serviceSpread)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("PhotosCell", forIndexPath: indexPath) as! PhotosCell
            cell.delegate = self
            cell.setInfo(photoModel?.photo_list_, setSpread: serviceSpread)
            return cell
        }
        
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 3 {
            let photoWall = PhotoWallViewController()
            photoWall.info = personalInfo
            navigationController?.pushViewController(photoWall, animated: true)
        }
    }
    
    // MARK ServiceCellDelegate
    func spreadAction(sender: AnyObject?) {
        let cell =  sender as! ServiceCell
        let indexPath = personalTable?.indexPathForCell(cell)
        serviceSpread = !cell.spread
        personalTable?.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
    }
}


extension ServantPersonalVC:CitysSelectorSheetDelegate {
    func localNotify(body: String?, userInfo: [NSObject: AnyObject]?) {
        let localNotify = UILocalNotification()
        localNotify.fireDate = NSDate().dateByAddingTimeInterval(0.1)
        localNotify.timeZone = NSTimeZone.defaultTimeZone()
        localNotify.applicationIconBadgeNumber = DataManager.getUnreadMsgCnt(-1)
        localNotify.soundName = UILocalNotificationDefaultSoundName
        if #available(iOS 8.2, *) {
            localNotify.alertTitle = "优悦出行"
        } else {
            // Fallback on earlier versions
        }
        localNotify.alertBody = body!
        localNotify.userInfo = userInfo
        UIApplication.sharedApplication().scheduleLocalNotification(localNotify)
        
    }
    
    func daysSureAction(sender: UIButton?, targetDays: Int) {
        daysAlertController?.dismissViewControllerAnimated(true, completion: nil)
        
        let totalMoney = targetDays * service_price_oneday!  // 总价格
        let currentCash = CurrentUser.user_cash_      // 当前余额
        
        if currentCash >= totalMoney {
            let req = InvitationRequestModel()
            req.to_uid_ = personalInfo!.uid_
            req.service_id_ = selectedServcie!.service_id_
            req.day_count_ = targetDays
            APIHelper.servantAPI().invitaion(req, complete: { [weak self](response) in
                if let model = response as? HodometerInfoModel {
                    if UIApplication.sharedApplication().applicationState == .Background {
                        let body = "系统消息: 您有新的行程消息!"
                        var userInfo:[NSObject: AnyObject] = [NSObject: AnyObject]()
                        userInfo["type"] = PushMessage.MessageType.System.rawValue
                        userInfo["data"] = model
                        self!.localNotify(body, userInfo: userInfo)
                    } else {
                        let msg = model.is_asked_ == 0 ? "邀约发起成功，等待对方接受邀请" : "邀约失败，您已经邀约过对方"
                        let alert = UIAlertController.init(title: "邀约状态", message: msg, preferredStyle: .Alert)
                        let action = UIAlertAction.init(title: "确定", style: .Default, handler: nil)
                        alert.addAction(action)
                        self!.presentViewController(alert, animated: true, completion: nil)
                    }
                }
                }, error: { [weak self](err) in
                    let msg = "邀约失败，请稍后再试"
                    let alert = UIAlertController.init(title: "邀约状态", message: msg, preferredStyle: .Alert)
                    let action = UIAlertAction.init(title: "确定", style: .Default, handler: nil)
                    alert.addAction(action)
                    self!.presentViewController(alert, animated: true, completion: nil)
                })
            
        }else{
            let needChargeNum = Int(ceil(Float(totalMoney - currentCash)/100))
            let alert = UIAlertController.init(title: "余额不足", message: "服务价格为\(totalMoney/100)元，还差\(needChargeNum)元", preferredStyle: .Alert)

            let ok = UIAlertAction.init(title: "去充值", style: .Default, handler: { (action: UIAlertAction) in
                let rechargeVC = RechargeVC()
                rechargeVC.chargeNumber = totalMoney - currentCash
                self.navigationController?.pushViewController(rechargeVC, animated: true)

            })

            let cancel = UIAlertAction.init(title: "取消", style: .Cancel, handler: nil)
            alert.addAction(ok)
            alert.addAction(cancel)
            
            presentViewController(alert, animated: true, completion: nil)
            
            return
            
        }
    }
    
    func daysCancelAction(sender: UIButton?) {
        daysAlertController?.dismissViewControllerAnimated(true, completion: nil)
    }
}


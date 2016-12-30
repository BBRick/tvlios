//
//  PushMessageVC.swift
//  HappyTravel
//
//  Created by 陈奕涛 on 16/8/25.
//  Copyright © 2016年 陈奕涛. All rights reserved.
//

import Foundation
import RealmSwift
import XCGLogger
import MJRefresh


class PushMessageVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var currentAppointmentId = 0
    var segmentSC:UISegmentedControl?
    var selectedIndex = 0
    var table:UITableView?
    var servantsArray:Array<UserInfo>? = []
    var segmentIndex = 0
    var orderID = 0
    var hotometers:Results<HodometerInfo>?
    var timer:NSTimer?

    let header:MJRefreshStateHeader = MJRefreshStateHeader()
    let footer:MJRefreshAutoStateFooter = MJRefreshAutoStateFooter()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "消息中心"
        
        initView()
        segmentChange(segmentSC)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerNotify()
        table?.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
    }
    
    func registerNotify() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PushMessageVC.chatMessage(_:)), name: NotifyDefine.ChatMessgaeNotiy, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PushMessageVC.pushMessageNotify(_:)), name: NotifyDefine.PushMessageNotify, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PushMessageVC.obtainTripReply(_:)), name: NotifyDefine.ObtainTripReply, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PushMessageVC.receivedAppoinmentRecommendServants(_:)), name: NotifyDefine.AppointmentRecommendReply, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PushMessageVC.payForInvitationReply(_:)), name: NotifyDefine.PayForInvitationReply, object: nil)
    }
    
    func receivedAppoinmentRecommendServants(notification:NSNotification?) {
        
        if let data = notification?.userInfo!["data"] as? Dictionary<String, AnyObject> {
            servantsArray?.removeAll()
        
            if let servants = data["recommend_guide_"] as? Array<Dictionary<String, AnyObject>> {
                var uid_str = ""
                for servant in servants {
                    let servantInfo = UserInfo()
                    servantInfo.setInfo(.Servant, info: servant)
                    servantsArray?.append(servantInfo)
                    uid_str += "\(servantInfo.uid),"
                    
                }
                let recommendVC = RecommendServantsVC()
                recommendVC.isNormal = false
                recommendVC.appointment_id_ = currentAppointmentId
                recommendVC.servantsInfo = servantsArray
                navigationController?.pushViewController(recommendVC, animated: true)
                uid_str.removeAtIndex(uid_str.endIndex.predecessor())
                let dict:Dictionary<String, AnyObject> = ["uid_str_": uid_str]
                SocketManager.sendData(.GetUserInfo, data: dict)
            }
           
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PushMessageVC.obtainTripReply(_:)), name: NotifyDefine.ObtainTripReply, object: nil)
    }
    
    func payForInvitationReply(notification: NSNotification) {
        let result = notification.userInfo!["result_"] as! Int
        var msg = ""
        switch result {
        case 0:
             MobClick.event(CommonDefine.BuriedPoint.payForOrderSuccess)
            msg = "预支付成功"
            SocketManager.sendData(.ObtainTripRequest, data: ["uid_": DataManager.currentUser!.uid,
                                                              "order_id_": 0,
                                                              "count_": 10])
        case -1:
            msg = "密码错误"
        case -2:
            msg = "余额不足"
            moneyIsTooLess()
            return
        default:
            break
        }
        let alert = UIAlertController.init(title: "提示", message: msg, preferredStyle: .Alert)
        let sure = UIAlertAction.init(title: "好的", style: .Cancel, handler: nil)
        alert.addAction(sure)
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func allEndRefreshing() {
        if header.state == MJRefreshState.Refreshing {
            header.endRefreshing()
        }
        if footer.state == MJRefreshState.Refreshing {
            footer.endRefreshing()
        }
        

    }
    
    func obtainTripReply(notification: NSNotification) {
        
        allEndRefreshing()
        let realm = try! Realm()
        hotometers = realm.objects(HodometerInfo.self).filter("order_id_ != 0").sorted("start_", ascending: false)
        
        let lastOrderID = notification.userInfo!["lastOrderID"] as! Int
        if lastOrderID == -1001 {
            footer.state = .NoMoreData
            footer.setTitle("多乎哉 不多矣", forState: .NoMoreData)
            return
        }
        orderID = lastOrderID
        table?.reloadData()
    }
    
    func chatMessage(notification: NSNotification?) {
//        let data = (notification?.userInfo!["data"])! as! Dictionary<String, AnyObject>
        table?.reloadData()
        
    }
    
    func pushMessageNotify(notification: NSNotification) {
        if let dict = notification.userInfo as? Dictionary<String, AnyObject> {
            if let msg = dict["data"] as? Dictionary<String, AnyObject> {
                let chatVC = ChatVC()
                chatVC.servantInfo = DataManager.getUserInfo(msg["from_uid_"] as! Int)
                navigationController?.pushViewController(chatVC, animated: true)
            }
        }
        
    }
    
    func initView() {
        let segmentBGV = UIImageView()
        segmentBGV.image = UIImage.init(named: "segment-bg")
        view.addSubview(segmentBGV)
        segmentBGV.snp_makeConstraints { (make) in
            make.top.equalTo(view)
            make.left.equalTo(view)
            make.right.equalTo(view)
            make.height.equalTo(60)
        }
        
        let segmentItems = ["消息", "行程"]
        segmentSC = UISegmentedControl(items: segmentItems)
        segmentSC!.tag = 1001
        segmentSC!.addTarget(self, action: #selector(PushMessageVC.segmentChange), forControlEvents: UIControlEvents.ValueChanged)
        segmentSC!.selectedSegmentIndex = selectedIndex
        segmentSC!.layer.masksToBounds = true
        segmentSC?.layer.cornerRadius = 5
        segmentSC?.backgroundColor = UIColor.clearColor()
        segmentSC!.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: UIControlState.Normal)
        segmentSC!.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: UIControlState.Selected)
        segmentSC?.tintColor = UIColor.init(red: 183/255.0, green: 39/255.0, blue: 43/255.0, alpha: 1)
        view.addSubview(segmentSC!)
        segmentSC!.snp_makeConstraints { (make) in
            make.center.equalTo(segmentBGV)
            make.height.equalTo(30)
            make.width.equalTo(UIScreen.mainScreen().bounds.size.width / 2.0)
        }
    
        table = UITableView(frame: CGRectZero, style: .Plain)
        table?.backgroundColor = UIColor.init(decR: 241, decG: 242, decB: 243, a: 1)
        table?.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        table?.delegate = self
        table?.dataSource = self
        table?.estimatedRowHeight = 256
        table?.rowHeight = UITableViewAutomaticDimension
        table?.separatorStyle = .None
        table?.registerClass(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        table?.registerClass(DistanceOfTravelCell.self, forCellReuseIdentifier: "DistanceOfTravelCell")
        view.addSubview(table!)
        table?.snp_makeConstraints(closure: { (make) in
            make.left.equalTo(view)
            make.top.equalTo(segmentBGV.snp_bottom)
            make.right.equalTo(view)
            make.bottom.equalTo(view)
        })
        
//        header.hidden = true
        header.setRefreshingTarget(self, refreshingAction: #selector(PushMessageVC.headerRefresh))
        table?.mj_header = header
        footer.hidden = true
        footer.setRefreshingTarget(self, refreshingAction: #selector(PushMessageVC.footerRefresh))
        table?.mj_footer = footer
        
    }
    
    func headerRefresh() {
        if segmentIndex == 0 {
            header.endRefreshing()
        } else if segmentIndex == 1 {
            SocketManager.sendData(.ObtainTripRequest, data: ["uid_": DataManager.currentUser!.uid,
                "order_id_": 0,
                "count_": 10])
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(PushMessageVC.endRefresh), userInfo: nil, repeats: false)
        /**
         加入mainloop 防止滑动计时器停止
         */
        NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
    }
    func endRefresh() {
        
        if header.state == .Refreshing {
            header.endRefreshing()
        }
        if footer.state == .Refreshing {
            footer.endRefreshing()
        }
        if timer != nil {
            
            timer?.invalidate()
            timer = nil
        }
    }
    func footerRefresh() {
        if segmentIndex == 0 {
            footer.endRefreshing()
        } else if segmentIndex == 1 {
            SocketManager.sendData(.ObtainTripRequest, data: ["uid_": DataManager.currentUser!.uid,
                "order_id_": orderID,
                "count_": 10])
        }
        
    }
    
    func segmentChange(sender: UISegmentedControl?) {
        allEndRefreshing()
        segmentIndex = (sender?.selectedSegmentIndex)!
        if segmentIndex == 0 {
            header.beginRefreshing()
            performSelector(#selector(PushMessageVC.allEndRefreshing), withObject: nil, afterDelay: 1.5)
//            header.hidden = true
            footer.hidden = true
        } else if segmentIndex == 1 {
            header.hidden = false
            footer.hidden = false
            header.beginRefreshing()
        }
        
        table?.reloadData()

    }

    // MARK: - UITableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segmentIndex == 0 ? DataManager.getMessageCount(-1) : (hotometers?.count ?? 0)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if segmentIndex == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell", forIndexPath: indexPath) as! MessageCell
            let realm = try! Realm()
            let userPushMessage = realm.objects(UserPushMessage.self).sorted("msg_time_", ascending: false)[indexPath.row]
            cell.setInfo(userPushMessage.msgList.last, unreadCnt: userPushMessage.unread)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("DistanceOfTravelCell", forIndexPath: indexPath) as! DistanceOfTravelCell
            cell.setHodometerInfo(hotometers![indexPath.row])
            return cell
        }
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if segmentIndex == 0 {
            let realm = try! Realm()
            let userPushMessage = realm.objects(UserPushMessage.self).sorted("msg_time_", ascending: false)[indexPath.row]

            let message = userPushMessage.msgList.last
            if message?.push_msg_type == 2231 {
                let uid_str_ = message?.servant_id_
                currentAppointmentId = (message?.appointment_id_)!
                if uid_str_ != nil  {
                    SocketManager.sendData(.AppointmentRecommendRequest, data: ["uid_str_": uid_str_!])
                } else {
                    XCGLogger.error("推送服务者id 为空")
                }
                DataManager.readMessage(currentAppointmentId)

                return

            }
            
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MessageCell {
                let chatVC = ChatVC()
                chatVC.servantInfo = DataManager.getUserInfo(cell.userInfo!.uid)
                navigationController?.pushViewController(chatVC, animated: true)
                
            }
        } else if segmentIndex == 1 {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? DistanceOfTravelCell {
                let status = cell.curHodometerInfo?.status_
                if cell.curHodometerInfo?.status_ == HodometerStatus.InvoiceMaking.rawValue ||
                    cell.curHodometerInfo?.status_ == HodometerStatus.InvoiceMaked.rawValue ||
                    cell.curHodometerInfo?.status_ == HodometerStatus.Completed.rawValue {
                    let identDetailVC = IdentDetailVC()
                    identDetailVC.hodometerInfo = cell.curHodometerInfo!
                    navigationController?.pushViewController(identDetailVC, animated: true)
                } else if status == HodometerStatus.WaittingPay.rawValue {
                    SocketManager.sendData(.CheckUserCash, data: ["uid_":DataManager.currentUser!.uid])
                    payForInvitationRequest(cell.curHodometerInfo)
                }
                
            }
        }
        
    }
    
    /**
     跳转到设置支付密码界面
     */
    func jumpToPayPasswdVC() {
        let payPasswdVC = PayPasswdVC()
        payPasswdVC.payPasswdStatus = PayPasswdStatus(rawValue: (DataManager.currentUser?.has_passwd_)!)!
        navigationController?.pushViewController(payPasswdVC, animated: true)
    }
    
    func payForInvitationRequest(info: HodometerInfo?) {
         MobClick.event(CommonDefine.BuriedPoint.payForOrder)
        if DataManager.currentUser?.has_passwd_ == -1 {
            let alert = UIAlertController.init(title: "提示", message: "您尚未设置支付密码", preferredStyle: .Alert)
            weak var weakSelf = self
            let gotoSetup = UIAlertAction.init(title: "前往设置", style: .Default, handler: { (action) in
                weakSelf?.jumpToPayPasswdVC()
            })
            let cancel = UIAlertAction.init(title: "取消", style: .Default, handler: nil)
            alert.addAction(gotoSetup)
            alert.addAction(cancel)
            presentViewController(alert, animated: true, completion: nil)
            return
        }
        guard info != nil else {return}
//        weak var weakSelf = self
        let payVc = PayVC()
        payVc.price = info?.order_price_
        payVc.orderId = info?.order_id_
        payVc.segmentIndex = segmentSC!.selectedSegmentIndex
        self.navigationController?.pushViewController(payVc, animated: true)
        
//        let msg = "\n您即将预支付人民币:\(Double((info?.order_price_)!) / 100)元"
//        let alert = UIAlertController.init(title: "付款确认", message: msg, preferredStyle: .Alert)
//        
//        alert.addTextFieldWithConfigurationHandler({ (textField) in
//            textField.placeholder = "请输入支付密码"
//            textField.secureTextEntry = true
//        })
//        
//        let ok = UIAlertAction.init(title: "确认付款", style: .Default, handler: { (action) in
//            var errMsg = ""
//            let passwd = alert.textFields?.first?.text
//            if passwd?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 0 {
//                errMsg = "请输入支付密码"
//            }
//            if errMsg.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
//                let warningAlert = UIAlertController.init(title: "提示", message: errMsg, preferredStyle: .Alert)
//                let sure = UIAlertAction.init(title: "好的", style: .Cancel, handler: { (action) in
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.15)), dispatch_get_main_queue(), { () in
//                        weakSelf!.payForInvitationRequest(info)
//                    })
//                })
//                warningAlert.addAction(sure)
//                weakSelf!.presentViewController(warningAlert, animated: true, completion: nil)
//            } else {
//                if DataManager.currentUser?.cash < info?.order_price_ {
//                    weakSelf!.moneyIsTooLess()
//                } else {
//                    let dict:[String: AnyObject] = ["uid_": (DataManager.currentUser?.uid)!,
//                        "order_id_": (info?.order_id_)!,
//                        "passwd_": passwd!]
//                    SocketManager.sendData(.PayForInvitationRequest, data: dict)
//                }
//                
//            }
//            
//        })
//        
//        let cancel = UIAlertAction.init(title: "取消", style: .Cancel, handler: nil)
//        
//        alert.addAction(ok)
//        alert.addAction(cancel)
//        
//        presentViewController(alert, animated: true, completion: nil)
    }
    
    func moneyIsTooLess() {
        MobClick.event(CommonDefine.BuriedPoint.payForOrderFail)

        let alert = UIAlertController.init(title: "余额不足", message: "\n请前往充值", preferredStyle: .Alert)
        
        let ok = UIAlertAction.init(title: "前往充值", style: .Default, handler: { (action: UIAlertAction) in
            let rechargeVC = RechargeVC()
            self.navigationController?.pushViewController(rechargeVC, animated: true)
        })
        
        let cancel = UIAlertAction.init(title: "取消", style: .Cancel, handler: nil)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}


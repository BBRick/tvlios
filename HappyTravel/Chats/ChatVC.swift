//
//  ChatVC.swift
//  HappyTravel
//
//  Created by 陈奕涛 on 16/8/3.
//  Copyright © 2016年 陈奕涛. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import MJRefresh

public class ChatVC : UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, ServiceSheetDelegate, FaceKeyboardViewDelegate{
    var daysAlertController:UIAlertController?
    
    var dateFormatter = NSDateFormatter()
    var messages:Array<Message> = []
    var chatTable:UITableView?
    var toolBar: UIToolbar!
    var textView: UITextView!
    var sendButton: UIButton!
    var faceButton: UIButton!
    
    var locationButton: UIButton!
    
    var rotating = false
    var invitaionVC = InvitationVC()
    var alertController:UIAlertController?
    
    var servantInfo:UserInfoModel?
    var servantDetail:ServantDetailModel?
    
    var msgList:List<MessageModel>?
    
    
    let header:MJRefreshStateHeader = MJRefreshStateHeader()
    
    var selectedServcie:ServiceModel?
    
    var faceKeyBoard:FaceKeyboardView = {
        
        let keyboardView = NSBundle.mainBundle().loadNibNamed("FaceKeyboardView", owner: nil, options: nil).first as! FaceKeyboardView
        
        return keyboardView
        
    }()
    
    override public var inputAccessoryView: UIView! {
        get {
            if toolBar == nil {
                toolBar = UIToolbar(frame: CGRectZero)
                toolBar.autoresizingMask = .FlexibleHeight
                toolBar.backgroundColor = colorWithHexString("#f2f2f2")
                
                locationButton = UIButton(type: .Custom)
                locationButton.setBackgroundImage(UIImage.init(named: "chat_navigation"), forState: .Normal)
                locationButton.addTarget(self, action: #selector(ChatVC.pushToSelectLocationPage), forControlEvents: UIControlEvents.TouchUpInside)
                toolBar.addSubview(locationButton)
                locationButton.translatesAutoresizingMaskIntoConstraints = false
                locationButton.snp_makeConstraints(closure: { (make) in
                    make.height.equalTo(32)
                    make.left.equalTo(toolBar).offset(5)
                    make.bottom.equalTo(toolBar).offset(-5)
                    make.width.equalTo(32)
                })

                sendButton = UIButton(type: .System)
                sendButton.enabled = false
                sendButton.titleLabel?.font = UIFont.systemFontOfSize(S18)
                sendButton.layer.cornerRadius = 5
                sendButton.layer.masksToBounds = true
                sendButton.backgroundColor = UIColor.init(red: 20/255, green: 31/255, blue: 49/255, alpha: 1)
                sendButton.setTitle("发送", forState: .Normal)
                sendButton.setTitleColor(UIColor.grayColor(), forState: .Disabled)
                sendButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                sendButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
                sendButton.addTarget(self, action: #selector(ChatVC.sendMessageAction), forControlEvents: UIControlEvents.TouchUpInside)
                toolBar.addSubview(sendButton)
                sendButton.translatesAutoresizingMaskIntoConstraints = false
                sendButton.snp_makeConstraints(closure: { (make) in
                    make.bottom.equalTo(toolBar).offset(-5)
                    make.right.equalTo(toolBar).offset(-5)
                    make.height.equalTo(30)
                    make.width.equalTo(80)
                })
                
                faceButton = UIButton(type: .Custom)
                faceButton.setBackgroundImage(UIImage.init(named: "face-btn"), forState: .Normal)
                faceButton.addTarget(self, action: #selector(ChatVC.faceKeyboardShowOrHide), forControlEvents: UIControlEvents.TouchUpInside)
                toolBar.addSubview(faceButton)
                faceButton.translatesAutoresizingMaskIntoConstraints = false
                faceButton.snp_makeConstraints(closure: { (make) in
                    make.height.equalTo(32)
                    make.bottom.equalTo(toolBar).offset(-5)
                    make.width.equalTo(32)
                    make.right.equalTo(sendButton.snp_left)
                })
                textView = InputTextView(frame: CGRectZero)
                textView.backgroundColor = UIColor(white: 250/255, alpha: 1)
                textView.delegate = self
                textView.font = UIFont.systemFontOfSize(S18)
                textView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 205/255, alpha:1).CGColor
                textView.layer.borderWidth = 0.5
                textView.layer.cornerRadius = 5
                textView.scrollsToTop = false
                textView.textContainerInset = UIEdgeInsetsMake(4, 3, 3, 3)
                textView.scrollRangeToVisible(NSMakeRange(0, 0))
                textView.scrollEnabled = false
                toolBar.addSubview(textView)
                textView.translatesAutoresizingMaskIntoConstraints = false
                textView.snp_makeConstraints(closure: { (make) in
                    make.left.equalTo(locationButton.snp_right).offset(5)
                    make.right.equalTo(faceButton.snp_left).offset(-5)
                    make.bottom.equalTo(toolBar).offset(-5)
                    make.top.equalTo(toolBar).offset(5)
                    
                })
            }
            let height = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat(MAXFLOAT))).height
            if height < 120 {
                textView.snp_remakeConstraints(closure: { (make) in
                    make.left.equalTo(locationButton.snp_right).offset(5)
                    make.right.equalTo(faceButton.snp_left).offset(-5)
                    make.bottom.equalTo(toolBar).offset(-5)
                    make.top.equalTo(toolBar).offset(5)
                    make.height.equalTo(height)
                })
            }
            return toolBar
        }
    }
    
    //MARK: - UITextViewDelegate
    public func textViewDidChange(textView: UITextView) {
        sendButton.enabled = textView.hasText()
        let oldHeight = textView.frame.size.height
        let newHeight = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat(MAXFLOAT))).height
        let height = abs(Int(newHeight) - Int(oldHeight))
        if height > 18 && newHeight <= 120 {
            inputAccessoryView.reloadInputViews()
        }
        textView.scrollEnabled = newHeight > 120
    }
    
    override public func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = servantInfo?.nickname_
        view.backgroundColor = UIColor.init(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        
        if servantInfo == nil {
            navigationController?.popViewControllerAnimated(true)
            return
        }
        
        msgList = DataManager.getData(ChatSessionModel.self)?.filter("uid_ = \(servantInfo!.uid_)").first?.msgList
        ChatMessageHelper.shared.delegate = self
        initView()
        
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerNotify()
        
        //如果是客服聊天则直接return
//        guard servantInfo?.uid > -1 && servantInfo?.uid != 50 else {return} // uid:50 客服临时账号
        guard servantInfo?.uid_ > -1 else {return} // uid:50 客服临时账号
        if navigationItem.rightBarButtonItem == nil {
            let msgItem = UIBarButtonItem.init(title: "立即邀约", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ChatVC.invitationAction(_:)))
            navigationItem.rightBarButtonItem = msgItem
        }
        
        if servantDetail == nil {
            let servant = UserBaseModel()
            servant.uid_ = servantInfo!.uid_
            APIHelper.servantAPI().servantDetail(servant, complete: { (response) in
                if let model = response as? ServantDetailModel {
                    DataManager.insertData(model)
                }
                }, error: nil)
        }
        
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if msgList != nil {
            chatTable!.scrollToRowAtIndexPath(NSIndexPath.init(forRow: msgList!.count-1, inSection: 0), atScrollPosition: .Bottom, animated: false)
        }
        let unreadCntBefore = DataManager.getUnreadMsgCnt(-1)
        DataManager.readMessage(servantInfo!.uid_)
        let unreadCntLater = DataManager.getUnreadMsgCnt(-1)
        var readCnt = unreadCntBefore - unreadCntLater
        if readCnt == unreadCntBefore {
            readCnt = -1
        }
        
        let req = ReadCountRequestModel()
        req.uid_ = servantInfo!.uid_
        req.count_ = readCnt
        APIHelper.chatAPI().feedbackReadCount(req, complete: nil, error: nil)
        UIApplication.sharedApplication().applicationIconBadgeNumber = unreadCntLater
        
        //如果是客服聊天则直接return
        guard servantInfo?.uid_ > -1 else {return}
        
        if servantDetail?.service_list_.count == 0 {
            let servant = UserBaseModel()
            servant.uid_ = servantInfo!.uid_
            APIHelper.servantAPI().servantDetail(servant, complete: { (response) in
                if let model = response as? ServantDetailModel {
                    DataManager.insertData(model)
                }
            }, error: nil)
        }
        
    }
    
    func registerNotify() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(menuControllerWillHide(_:)), name: UIMenuControllerWillHideMenuNotification, object: nil)
        
    }
    
    func invitationAction(sender: UIButton?) {
        invitation()
    }
    
    func invitation() {
        //邀约服务选择
        textView.resignFirstResponder()
        if alertController == nil {
            alertController = UIAlertController.init(title: "", message: nil, preferredStyle: .ActionSheet)
            let sheet = ServiceSheet()
            sheet.servantInfo = DataManager.getData(UserInfoModel.self, filter: "uid_ = \(servantInfo!.uid_)")?.first
            sheet.servantDetail = DataManager.getData(ServantDetailModel.self, filter: "uid_ = \(servantInfo!.uid_)")?.first
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
    
    
    func sureAction(service: ServiceModel?, daysCount: Int?) {
//        确定服务选择
        unowned let weakSelf = self
        
        selectedServcie = service
        
        alertController?.dismissViewControllerAnimated(true, completion: {
            //移除天数选择,默认一天
            weakSelf.daysSureAction(nil, targetDays: 1)
            //弹出保险页面
//            let insuranceVc = InsuranceVC()
//            insuranceVc.order_price = Int64(service!.service_price_)
//            insuranceVc.servantInfoDict = ["from_uid_": CurrentUser.uid_,
//                                            "to_uid_": self.servantInfo!.uid,
//                                            "service_id_": self.selectedServcie!.service_id_,
//                                            "day_count_":daysCount!]
//            self.navigationController?.pushViewController(insuranceVc, animated: true)
            
            //            weakSelf.performSelector(#selector(ServantPersonalVC.inviteAction), withObject: nil, afterDelay: 0.2)
            
            
        })
        
    }
    
    func inviteAction() {
        if daysAlertController == nil {
            daysAlertController = UIAlertController.init(title: "", message: nil, preferredStyle: .ActionSheet)
            let sheet = CitysSelectorSheet()
            let days = [1, 2, 3, 4, 5, 6, 7]
            sheet.daysList = days
            sheet.delegate = self
            daysAlertController!.view.addSubview(sheet)
            sheet.snp_makeConstraints { (make) in
                make.left.equalTo(daysAlertController!.view).offset(-10)
                make.right.equalTo(daysAlertController!.view).offset(10)
                make.bottom.equalTo(daysAlertController!.view).offset(10)
                make.top.equalTo(daysAlertController!.view)
            }
        }
        
        presentViewController(daysAlertController!, animated: true, completion: nil)
    }
    
    func initView() {
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        faceKeyBoard.faceDelegate = self
        let rect = view.bounds
        chatTable = UITableView(frame: rect, style: .Plain)
        chatTable!.tag = 1001
        chatTable?.backgroundColor = UIColor.clearColor()
        chatTable!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        chatTable!.dataSource = self
        chatTable!.delegate = self
        chatTable!.keyboardDismissMode = .Interactive
        chatTable!.estimatedRowHeight = 44
        chatTable!.separatorStyle = .None
        chatTable!.registerClass(ChatDateCell.self, forCellReuseIdentifier: "ChatDateCell")
        chatTable!.registerClass(ChatBubbleCell.self, forCellReuseIdentifier: "ChatBubbleCell")
        chatTable?.registerClass(ChatLocationAnotherCell.self, forCellReuseIdentifier: "ChatLocationAnother")
        chatTable?.registerClass(ChatLocationMeCell.self, forCellReuseIdentifier: "ChatLocationMe")
        view.addSubview(chatTable!)
        
//        header.setRefreshingTarget(self, refreshingAction: #selector(ChatVC.headerRefresh))
//        chatTable?.mj_header = header
    }
    
    func headerRefresh() {
        
        
        performSelector(#selector(ChatVC.endRefresh), withObject: nil, afterDelay: 5)
    }
    
    func endRefresh() {
        header.endRefreshing()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo as NSDictionary!
        let frameNew = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let insetNewBottom = chatTable!.convertRect(frameNew, fromView: nil).height
        let insetOld = chatTable!.contentInset
        let insetChange = insetNewBottom - insetOld.bottom
        let overflow = chatTable!.contentSize.height - (chatTable!.frame.height-insetOld.top-insetOld.bottom)
        
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let animations: (() -> Void) = {
            if !(self.chatTable!.tracking || self.chatTable!.decelerating) {
                // Move content with keyboard
                if overflow > 0 {                   // scrollable before
                    self.chatTable!.contentOffset.y += insetChange
                    if self.chatTable!.contentOffset.y < -insetOld.top {
                        self.chatTable!.contentOffset.y = -insetOld.top
                    }
                } else if insetChange > -overflow { // scrollable after
                    self.chatTable!.contentOffset.y += insetChange + overflow
                }
            }
        }
        if duration > 0 {
            let options = UIViewAnimationOptions(rawValue: UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16)) // http://stackoverflow.com/a/18873820/242933
            UIView.animateWithDuration(duration, delay: 0, options: options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }
    
    func keyboardDidShow(notification: NSNotification) {
        let userInfo = notification.userInfo as NSDictionary!
        let frameNew = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let insetNewBottom = chatTable!.convertRect(frameNew, fromView: nil).height
        
        // Inset `tableView` with keyboard
        let contentOffsetY = chatTable!.contentOffset.y
        chatTable!.contentInset.bottom = insetNewBottom
        chatTable!.scrollIndicatorInsets.bottom = insetNewBottom
        // Prevents jump after keyboard dismissal
        if chatTable!.tracking || chatTable!.decelerating {
            chatTable!.contentOffset.y = contentOffsetY
        }
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return msgList?.count ?? 0
    }
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let message = msgList![indexPath.row]
        
        if message.msg_type_ == PushMessage.MessageType.Location.rawValue  {
            
            let vc = ShowLocationDetailViewController()
            vc.poiModel = stringToModel(message.content_!)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    

    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let message = msgList![indexPath.row]
        
        if message.msg_type_ == PushMessage.MessageType.Location.rawValue  {
            return 110
        }
        
        return  UITableViewAutomaticDimension
    }
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let message = msgList![indexPath.row]
   
        if message.msg_type_ == PushMessage.MessageType.Location.rawValue  {
        
            if message.to_uid_ == CurrentUser.uid_ {
                let cell = tableView.dequeueReusableCellWithIdentifier("ChatLocationAnother", forIndexPath: indexPath) as! ChatLocationAnotherCell
                cell.setupDataWithContent(message.content_)
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("ChatLocationMe", forIndexPath: indexPath) as! ChatLocationMeCell
                cell.setupDataWithContent(message.content_)
                return cell
            }
        }
        
        if message.msg_type_ == PushMessage.MessageType.Date.rawValue {
            let cell = tableView.dequeueReusableCellWithIdentifier("ChatDateCell", forIndexPath: indexPath) as! ChatDateCell
            cell.sentDateLabel.text = dateFormatter.stringFromDate(NSDate(timeIntervalSince1970: NSNumber.init(longLong: message.msg_time_).doubleValue))
            return cell
        } else  {
            let cell = tableView.dequeueReusableCellWithIdentifier("ChatBubbleCell", forIndexPath: indexPath) as! ChatBubbleCell
            let msgData = Message(incoming: (message.from_uid_ == CurrentUser.uid_) ? false : true, text: message.content_!, sentDate: NSDate(timeIntervalSince1970: NSNumber.init(longLong: message.msg_time_).doubleValue))
            cell.configureWithMessage(msgData)
            return cell
        }
    }
    func pushToSelectLocationPage() {
        
        let getLocationVC = GetLocationInfoViewController()
        getLocationVC.delegate = self
        navigationController?.pushViewController(getLocationVC, animated: true)
        
    }
    
    func faceKeyboardShowOrHide() {
        
        if faceButton.selected {
            textView.inputView = nil
            
        }
        let isSelected = faceButton.selected
        UIView.animateWithDuration(0.2) {
            self.textView.resignFirstResponder()
        }
        
        
        faceButton.selected = !isSelected
        
        if faceButton.selected {
            textView.inputView = faceKeyBoard
        }
        
        
        UIView.animateWithDuration(0.2) {
            self.textView.becomeFirstResponder()
        }
        
        
    }
    
    func sendMessageAction() {
        sendMessageWithText(textView.text)
    }
    
    func sendMessageWithText(msg:String, type:Int = 0) {
        let msgData = Message(incoming: false, text: msg, sentDate: NSDate(timeIntervalSinceNow: 0))
        messages.append(msgData)
        
        let data:Dictionary<String, AnyObject> = ["from_uid_": CurrentUser.uid_,
                                                  "to_uid_": servantInfo!.uid_,
                                                  "msg_time_": NSNumber.init(longLong: Int64(NSDate().timeIntervalSince1970)),
                                                  "content_": msg,
                                                  "msg_type_":type]
        //base64编码
        //        let utf8str = textView.text.dataUsingEncoding(NSUTF8StringEncoding)
        //        let msg_base64 = utf8str?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        //        let data_base:Dictionary<String, AnyObject> = ["from_uid_": CurrentUser.uid_,
        //                                                  "to_uid_": servantInfo!.uid,
        //                                                  "msg_time_": NSNumber.init(longLong: Int64(NSDate().timeIntervalSince1970)),
        //                                                  "content_": msg_base64!]
        //        SocketManager.sendData(.SendChatMessage, data: data_base)
        
        
        let model = ChatModel(value: data)
        let messageModel = MessageModel(value: data)
//        ChatMessageHelper.shared.reveicedMessage(messageModel)
        DataManager.insertData(messageModel)
        APIHelper.chatAPI().chat(model, complete: { (response) in
            }) { (error) in
                
        }
        reloadTable()
        textView.text = ""
        inputAccessoryView.reloadInputViews()
    }
    func reloadTable() {
        let numberOfRows = chatTable?.numberOfRowsInSection(0)
        if numberOfRows! == 0 {
            msgList = DataManager.getData(ChatSessionModel.self)?.filter("uid_ = \(servantInfo!.uid_)").first?.msgList
            chatTable?.reloadData()
        } else {
            chatTable?.beginUpdates()
            chatTable?.insertRowsAtIndexPaths([NSIndexPath.init(forRow: numberOfRows!, inSection: 0), NSIndexPath.init(forRow: numberOfRows!, inSection: 0)], withRowAnimation: .None)
            chatTable?.endUpdates()
            chatTable?.scrollToRowAtIndexPath(NSIndexPath.init(forRow: numberOfRows!, inSection: 0), atScrollPosition: .Top, animated: true)
        }
    }
    
    func menuControllerWillHide(notification: NSNotification) {
        if let selectedIndexPath = chatTable!.indexPathForSelectedRow {
            chatTable!.deselectRowAtIndexPath(selectedIndexPath, animated: false)
        }
    }
    
    
    func messageCopyTextAction(menuController: UIMenuController) {
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func faceKeyboardView(faceKeyboardView: FaceKeyboardView, didKeyCode keyCode: String) {
        
        if keyCode.characters.count > 0{
            textView.insertText(keyCode)
        }else {
            
            textView.deleteBackward()
        }
        
    }
    
}



extension ChatVC:CitysSelectorSheetDelegate, SendLocationMessageDelegate, ReceivedChatDelegate{
    
    func receivedChatMessgae(message: MessageModel) {
        
        guard message.from_uid_ == servantInfo!.uid_ else {return}
        reloadTable()
    }

    func sendLocation(poiModel: POIInfoModel?) {
        
        sendMessageWithText(modelToString(poiModel!), type: PushMessage.MessageType.Location.rawValue)
        
    }
    
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

        let req = InvitationRequestModel()
        req.to_uid_ = servantInfo!.uid_
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
    }
    
    func daysCancelAction(sender: UIButton?) {
        
        daysAlertController?.dismissViewControllerAnimated(true, completion: nil)
    }
}


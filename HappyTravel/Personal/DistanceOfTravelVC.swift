//
//  DistanceOfTravelVC.swift
//  HappyTravel
//
//  Created by 陈奕涛 on 16/8/24.
//  Copyright © 2016年 陈奕涛. All rights reserved.
//

import Foundation
import RealmSwift
import MJRefresh
import XCGLogger
import SVProgressHUD


enum OrderType : Int {
    case InviteOrder = 0
    case AppointmentOrder = 1
    case CenturionCardOrder = 2
}

class DistanceOfTravelVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var segmentSC:UISegmentedControl?
    var table:UITableView?
    var messageInfo:Array<UserInfo>? = []
    var segmentIndex = 0
    var timer:NSTimer?
    var servantsArray:Array<UserInfoModel>? = []

    var hotometers:Results<HodometerInfo>?
    var currentApponitmentID = 0
    
    var consumes:Results<CenturionCardConsumedInfo>?
    var records:Results<AppointmentInfo>?
    let header:MJRefreshStateHeader = MJRefreshStateHeader()
    let footer:MJRefreshAutoStateFooter = MJRefreshAutoStateFooter()
    
    var selectedHodometerInfo:HodometerInfoModel?
    var selectedAppointmentInfo:AppointmentInfoModel?
    
    var orderID = 0
    var lastRecordId = 0
    var consumedOrderID = 0
    
    /***
     新
     \***/
    var inviteList:Results<HodometerInfoModel>?
    var appointmentList:Results<AppointmentInfoModel>?
    var centurionRecordList:Results<CenturionCardRecordModel>?
    var requestCount = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.init(decR: 242, decG: 242, decB: 242, a: 1)
        navigationItem.title = "我的消费"
        
        initView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
//        registerNotify()
        header.performSelector(#selector(MJRefreshHeader.beginRefreshing), withObject: nil, afterDelay: 0.5)

    }
    
    func appearheaderRefresh() {
        header.beginRefreshing()
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        
        let segmentItems = ["商务游", "预约"] // , "黑卡消费"
        segmentSC = UISegmentedControl(items: segmentItems)
        segmentSC!.tag = 1001
        segmentSC!.addTarget(self, action: #selector(DistanceOfTravelVC.segmentChange), forControlEvents: UIControlEvents.ValueChanged)
        segmentSC!.selectedSegmentIndex = segmentIndex
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
            make.width.equalTo(UIScreen.mainScreen().bounds.size.width / 2.0 + 20)
        }
        
        table = UITableView(frame: CGRectZero, style: .Plain)
        table?.backgroundColor = UIColor.init(decR: 241, decG: 242, decB: 243, a: 1)
        table?.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        table?.delegate = self
        table?.dataSource = self
        table?.estimatedRowHeight = 256
        table?.rowHeight = UITableViewAutomaticDimension
        table?.separatorStyle = .None
        table?.registerClass(DistanceOfTravelCell.self, forCellReuseIdentifier: "DistanceOfTravelCell")
        table?.registerClass(CentrionCardConsumedCell.self, forCellReuseIdentifier: "CentrionCardConsumedCell")
        table?.registerClass(AppointmentRecordCell.self, forCellReuseIdentifier: "AppointmentRecordCell")
        view.addSubview(table!)
        table?.snp_makeConstraints(closure: { (make) in
            make.left.equalTo(view)
            make.top.equalTo(segmentBGV.snp_bottom)
            make.right.equalTo(view)
            make.bottom.equalTo(view).offset(-5)
        })
        header.setRefreshingTarget(self, refreshingAction: #selector(DistanceOfTravelVC.headerRefresh))
        table?.mj_header = header
        footer.setRefreshingTarget(self, refreshingAction: #selector(DistanceOfTravelVC.footerRefresh))
        table?.mj_footer = footer

    }
    func footerRefresh() {
        refreshAction(false)
    }
    
    func headerRefresh() {
        refreshAction(true)
    }
    
    func refreshAction(isRefresh:Bool) {
        footer.state = .Idle
        switch segmentIndex {
        case 0:
            handleInviteOrderRequest(isRefresh)
        case 1:
            handleAppointmentRequest(isRefresh)
        case 2:
            handleCenturionCardRequest(isRefresh)
            break
        default:
            break
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(DistanceOfTravelVC.endRefresh), userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
    }
    
    func handleCenturionCardRequest(isRefresh:Bool) {
        footer.state = .NoMoreData
        footer.setTitle("没有更多信息", forState: .NoMoreData)
        APIHelper.consumeAPI().requsetCenturionCardRecordList(CenturionCardRecordRequestModel(), complete: { (response) in
            self.endRefresh()
            }) { (error) in
                
        }
    }
    func handleInviteOrderRequest(isRefresh:Bool) {
        let model = HodometerRequestModel()
        model.order_id_ = isRefresh ? 0 : orderID
        APIHelper.consumeAPI().requestInviteOrderLsit(model, complete: { [weak self](response) in
            if let models = response as? [HodometerInfoModel] {
                if model.order_id_ == 0 {
                    DataManager.removeData(HodometerInfoModel.self)
                    self?.refreshData()
                }
                DataManager.insertDatas(models)
                self?.orderID = models.last!.order_id_
                self?.endRefresh()
            } else {
                self?.noMoreData()
            }
        }) { [weak self](error) in
            self?.noMoreData()
        }
    }
    
    func handleAppointmentRequest(isRefresh:Bool) {
        let model = AppointmentRequestModel()
        model.last_id_ = isRefresh ? 0 : lastRecordId
        APIHelper.consumeAPI().requestAppointmentList(model, complete: { [weak self](response) in
            if let models = response as? [AppointmentInfoModel] {
                if model.last_id_ == 0 {
                    DataManager.removeData(AppointmentInfoModel.self)
                    self?.refreshData()
                }
                DataManager.insertDatas(models)
                self?.lastRecordId = models.last!.appointment_id_
                self?.endRefresh()
            } else {
                self?.noMoreData()
            }
        }) { [weak self](error) in
            self?.noMoreData()
        }
    }

    func requestRecommendListWithUidStr(uid_str_:String) {
        requestCount = 0
        let model = AppointmentRecommendRequestModel()
        model.uid_str_ = uid_str_
        APIHelper.consumeAPI().requestAppointmentRecommendList(model, complete: { (response) in
            let list = response as? Array<UserInfoModel>
            var uid_str = ""
            self.servantsArray?.removeAll()
            guard list?.count > 0 else {return}
            for servant in list! {
                self.servantsArray?.append(servant)
                uid_str += "\(servant.uid_),"
                self.requestDetaiInfo(servant.uid_)
            }
        }) { (error) in
        }
    }
    func requestDetaiInfo(uid:Int) {
        
        let model = UserBaseModel()
        model.uid_ = uid
        APIHelper.servantAPI().servantDetail(model, complete: { (response) in
            self.requestCount += 1
            if self.requestCount == self.servantsArray?.count {
                let recommendVC = RecommendServantsVC()
                recommendVC.isNormal = false
                recommendVC.appointment_id_ = self.currentApponitmentID
                recommendVC.servantsInfo = self.servantsArray
                self.navigationController?.pushViewController(recommendVC, animated: true)
            }
            let info = response as? ServantDetailModel
            guard info != nil else {return}
            DataManager.insertData(info!)
            }) { (error) in
                
        }
        
    }
    
    func requestUserInfoByIDStr(uid_str_:String) {
        
        let model = UserInfoIDStrRequestModel()
        model.uid_str_ = uid_str_
        APIHelper.servantAPI().getUserInfoByString(model, complete: { (response) in
            let infosArray = response as? Array<UserInfoModel>
            guard infosArray?.count > 0 else{return}
            for userInfo in infosArray! {
                DataManager.insertData(userInfo)
            }
            }) { (error) in
                
        }
        
    }
    
    // MARK: - UITableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var cnt = 0
        if segmentIndex == 0 {
            cnt = inviteList?.count ?? 0
        } else if (segmentIndex == 1){
            cnt = appointmentList?.count ?? 0
        } else {
            cnt = centurionRecordList?.count ?? 0
        }
        footer.hidden = cnt < 10 ? true : false
        return cnt
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch segmentIndex {
        case 0://商务游(和消息中心的行程一样)
            let cell = tableView.dequeueReusableCellWithIdentifier("DistanceOfTravelCell", forIndexPath: indexPath) as! DistanceOfTravelCell
            if inviteList?.count > 0 && indexPath.row < inviteList?.count {
                cell.setHodometerInfo(inviteList![indexPath.row])
            }
            
            return cell

        case 1://预约
            let cell = tableView.dequeueReusableCellWithIdentifier("AppointmentRecordCell", forIndexPath: indexPath) as! AppointmentRecordCell
            if appointmentList?.count > 0 && indexPath.row < appointmentList?.count {
                cell.setRecordInfo(appointmentList![indexPath.row])
            }
            
            return cell

        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("CentrionCardConsumedCell", forIndexPath: indexPath) as! CentrionCardConsumedCell
            if centurionRecordList?.count > 0 && indexPath.row < centurionRecordList?.count {
                cell.setCenturionCardConsumedInfo(centurionRecordList![indexPath.row])
            }
            
            return cell
            
        default:
            break
        }
        
        return UITableViewCell()
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        switch segmentIndex {
        case 0:
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? DistanceOfTravelCell {
                if  cell.curHodometerInfo?.status_ == HodometerStatus.InvoiceMaking.rawValue ||
                    cell.curHodometerInfo?.status_ == HodometerStatus.InvoiceMaked.rawValue ||
                    cell.curHodometerInfo?.status_ == HodometerStatus.Completed.rawValue{
                    
                    let identDetailVC = IdentDetailVC()
                    identDetailVC.hodometerInfo = cell.curHodometerInfo!
                    navigationController?.pushViewController(identDetailVC, animated: true)
                    /**
                     *  未支付状态去支付
                     */
                } else if cell.curHodometerInfo?.status_ == HodometerStatus.WaittingPay.rawValue {
                    getCash()
                    selectedHodometerInfo = cell.curHodometerInfo
                    payForInvitationRequest()
                }
            }
            break
        case 1:
            guard  appointmentList?.count > 0 else {return}
            let object = appointmentList![indexPath.row]
            guard object.status_ > 1  else {
                if object.recommend_uid_ != nil {
                    requestRecommendListWithUidStr(object.recommend_uid_!)
                } else {
                    SVProgressHUD.showWainningMessage(WainningMessage: "此预约尚未确定服务者", ForDuration: 1.5, completion: nil)
                }
                return
            }
            if  object.status_ == HodometerStatus.InvoiceMaking.rawValue ||
                object.status_ == HodometerStatus.InvoiceMaked.rawValue ||
                object.status_ == HodometerStatus.Completed.rawValue {
                let detailVC = AppointmentDetailVC()
                detailVC.appointmentInfo = appointmentList![indexPath.row]
                navigationController?.pushViewController(detailVC, animated: true)
                /**
                 *  未支付状态去支付
                 */
            } else if object.status_ == HodometerStatus.WaittingPay.rawValue {
                getCash()
                selectedAppointmentInfo = appointmentList![indexPath.row]
                payForInvitationRequest()
            }
    
            break
        case 2:
            break
        default:
            break
        }
    }

    func getCash() {
        APIHelper.userAPI().cash({ (response) in
            if let dict = response as? [String: AnyObject] {
                if let cash = dict["user_cash_"] as? Int {
                    CurrentUser.user_cash_ = cash
                }
                if let hasPasswd = dict["has_passwd_"] as? Int {
                    CurrentUser.has_passwd_ = hasPasswd
                }
            }
            }, error: nil)
    }
    
    func segmentChange(sender: AnyObject?) {
        segmentIndex = (sender?.selectedSegmentIndex)!
        if header.state == .Idle && (footer.state == .Idle || footer.state == .NoMoreData){
            header.beginRefreshing()
        }

    }
    
    func noMoreData() {
        endRefresh()
        footer.state = .NoMoreData
        footer.setTitle("没有更多信息", forState: .NoMoreData)
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
        refreshData()
    }
    
    func refreshData() {
        switch segmentIndex {
        case 0:
            inviteList = DataManager.getData(HodometerInfoModel.self)
        case 1:
            appointmentList = DataManager.getData(AppointmentInfoModel.self)
        case 2:
            centurionRecordList = DataManager.getData(CenturionCardRecordModel.self)
        default:
            break
        }
        table?.reloadData()
    }
    /**
     支付操作
     */
    func payForInvitationRequest() {
         MobClick.event(CommonDefine.BuriedPoint.payForOrder)
        if CurrentUser.has_passwd_ == -1 {
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
        guard segmentIndex != 2 else { return }
        var price = 0
        var order_id_ = 0
        if segmentIndex == 1 {
            price = (selectedAppointmentInfo?.order_price_)!
            order_id_ = (selectedAppointmentInfo?.order_id_)!
        } else {
            price =  (selectedHodometerInfo?.order_price_)!
            order_id_ = (selectedHodometerInfo?.order_id_)!
        }
        guard price>0 else{return}
        let payVc = PayVC()
        payVc.price = price
        payVc.orderId = order_id_
        payVc.segmentIndex = segmentSC!.selectedSegmentIndex
        self.navigationController?.pushViewController(payVc, animated: true)
    }
    
    /**
     跳转到设置支付密码界面
     */
    func jumpToPayPasswdVC() {
        let payPasswdVC = PayPasswdVC()
        payPasswdVC.payPasswdStatus = PayPasswdStatus(rawValue: CurrentUser.has_passwd_)!
        navigationController?.pushViewController(payPasswdVC, animated: true)
    }
    
    deinit {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
}

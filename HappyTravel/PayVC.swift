//
//  PayVC.swift
//  HappyTravel
//
//  Created by 司留梦 on 16/12/28.
//  Copyright © 2016年 陈奕涛. All rights reserved.
//

import UIKit

class PayVC: UIViewController, UITextFieldDelegate {

    var payLab:UILabel?
    var passwdTF:UITextField?
    var price:Int?
    var orderId:Int?
    var segmentIndex:Int?
    var sureInsurancePrice:Int?//保险金额
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.init(decR: 242, decG: 242, decB: 242, a: 1)
        navigationItem.title = "支付"
        //支付结果返回
        initView()
    }
    
    func initView() {
        let descLab = UILabel()
        descLab.text = "您即将支付人民币:"
        descLab.textAlignment = .Center
        descLab.font = UIFont.systemFontOfSize(14.0)
        descLab.textColor = UIColor.blackColor()
        self.view.addSubview(descLab)
        descLab.snp_makeConstraints { (make) in
            make.top.equalTo(self.view).offset(20)
            make.height.equalTo(15)
            make.left.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-20)
        }

        payLab = UILabel()
        payLab!.text = "￥\(Double(price!)/100)"
        payLab!.textAlignment = .Center
        payLab!.font = UIFont.systemFontOfSize(25.0)
        payLab!.textColor = UIColor.blackColor()
        self.view.addSubview(payLab!)
        payLab?.snp_makeConstraints(closure: { (make) in
            make.top.equalTo(descLab.snp_bottom).offset(20)
            make.height.equalTo(30)
            make.left.equalTo(descLab.snp_left)
            make.right.equalTo(descLab.snp_right)
        })
        
        passwdTF = UITextField()
        passwdTF!.borderStyle = .RoundedRect
        passwdTF!.placeholder = "请输入密码"
        passwdTF!.textAlignment = .Left
        passwdTF!.contentVerticalAlignment = .Center
        passwdTF!.keyboardType = .Default
        passwdTF!.clearButtonMode = .Always
        passwdTF!.secureTextEntry = true
        passwdTF!.delegate = self
        passwdTF!.becomeFirstResponder()
        passwdTF!.resignFirstResponder()
        self.view.addSubview(passwdTF!)
        passwdTF!.snp_makeConstraints { (make) in
            make.left.equalTo(descLab.snp_left)
            make.right.equalTo(descLab.snp_right)
            make.height.equalTo(30)
            make.top.equalTo(payLab!.snp_bottom).offset(20)
        }

//        let insuranceBtn = UIButton()
//        insuranceBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 100)
//        insuranceBtn.setImage(UIImage(named: "pay-unselect"), forState: .Normal)
//        insuranceBtn.setImage(UIImage(named: "pay-selected"), forState: .Selected)
//        insuranceBtn.setTitle("同意购买商务保险,", forState: .Normal)
//        insuranceBtn.titleLabel?.font = UIFont.systemFontOfSize(11.0)
//        insuranceBtn.setTitleColor(UIColor.grayColor(), forState: .Normal)
//        insuranceBtn.contentHorizontalAlignment = .Left
//        insuranceBtn.addTarget(self, action: #selector(sureInsuranceActure(_:)), forControlEvents: .TouchUpInside)
//        self.view.addSubview(insuranceBtn)
//        insuranceBtn.snp_makeConstraints { (make) in
//            make.top.equalTo(passwdTF!.snp_bottom).offset(20)
//            make.width.equalTo(115)
//            make.height.equalTo(15)
//            make.left.equalTo(self.view).offset(20)
//        }
//        
//        let webBtn = UIButton()
//        webBtn.setTitle("《保险说明》", forState: .Normal)
//        webBtn.tag = 99
//        webBtn.setTitleColor(UIColor.init(decR: 17, decG: 30, decB: 46, a: 1), forState: .Normal)
//        webBtn.titleLabel?.font = UIFont.systemFontOfSize(11.0)
//        webBtn.contentHorizontalAlignment = .Left
////        let attrs = [
////            NSFontAttributeName : UIFont.systemFontOfSize(12.0),
////            NSForegroundColorAttributeName : UIColor.init(decR: 3, decG: 168, decB: 236, a: 1),
////            NSUnderlineStyleAttributeName : 1]
////        let attributedString = NSMutableAttributedString(string:"") //3 168 236
////        let buttonTitleStr = NSMutableAttributedString(string:"《保险说明》", attributes:attrs)
////        attributedString.appendAttributedString(buttonTitleStr)
////        webBtn.setAttributedTitle(attributedString, forState: .Normal)
//        webBtn.addTarget(self, action: #selector(webView(_:)), forControlEvents: .TouchUpInside)
//        self.view.addSubview(webBtn)
//        webBtn.snp_makeConstraints { (make) in
//            make.top.equalTo(passwdTF!.snp_bottom).offset(20)
//            make.width.equalTo(70)
//            make.height.equalTo(15)
//            make.left.equalTo(insuranceBtn.snp_right)
//        }
//        
        
        let sureBtn = UIButton()
        sureBtn.setTitle("确认支付", forState: .Normal)
        sureBtn.layer.cornerRadius = 10
        sureBtn.layer.borderWidth = 1
        sureBtn.layer.masksToBounds = true
        sureBtn.layer.borderColor = UIColor.init(decR: 242, decG: 242, decB: 242, a: 1).CGColor
        sureBtn.setBackgroundImage(UIImage(named: "bottom-selector-bg"), forState: .Normal)
        sureBtn.addTarget(self, action: #selector(surePay(_:)), forControlEvents: .TouchUpInside)
        self.view.addSubview(sureBtn)
        sureBtn.snp_makeConstraints { (make) in
            make.left.equalTo(descLab.snp_left)
            make.right.equalTo(descLab.snp_right)
            make.top.equalTo(passwdTF!.snp_bottom).offset(10)
            make.height.equalTo(40)
        }

    }
    
    func surePay(sender: UIButton) {
        var errMsg = ""
        let passwd = passwdTF!.text
        if passwd?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 0 {
            errMsg = "请输入支付密码"
        }
        if errMsg.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            let warningAlert = UIAlertController.init(title: "提示", message: errMsg, preferredStyle: .Alert)
            let sure = UIAlertAction.init(title: "好的", style: .Cancel, handler: nil)
            warningAlert.addAction(sure)
            self.presentViewController(warningAlert, animated: true, completion: nil)
        } else {
            if CurrentUser.user_cash_ < price {
                self.moneyIsTooLess()
            } else {
                let req = PayForInvitationRequestModel()
                req.uid_ = CurrentUser.uid_
                req.order_id_ = orderId!
                req.passwd_ = passwd!
                APIHelper.consumeAPI().payForInvitation(req, complete: { [weak self](response) in
                    if let model = response as? PayForInvitationModel {
                        self!.payForInvitationRsp(model)
                    }
                    }, error: { (err) in
                
                })
            }
        }
    }
    
    func payForInvitationRsp(model: PayForInvitationModel) {
        var msg = ""
        switch model.result_ {
        case 0:
            MobClick.event(CommonDefine.BuriedPoint.payForOrderSuccess)
            msg = "预支付成功"
        case -1:
            msg = "密码错误"
        case -2:
            MobClick.event(CommonDefine.BuriedPoint.payForOrderFail)
            msg = "余额不足"
            moneyIsTooLess()
            return
        default:
            break
        }
        let alert = UIAlertController.init(title: "提示", message: msg, preferredStyle: .Alert)
        let sure = UIAlertAction.init(title: "好的", style: .Cancel, handler: {(action) in
            if model.result_ == 0{
                self.navigationController?.popViewControllerAnimated(true)
            }
        })
        alert.addAction(sure)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        //收起键盘
        textField.resignFirstResponder()
        return true
    }
    
    func sureInsuranceActure(sender:UIButton) {
        let isSelected = sender.selected
        sender.selected = !isSelected
        let num = isSelected ? 0 : sureInsurancePrice
        let money = price! + num!*100
        payLab!.text = "￥\(Double(money)/100)"
        
    }
    func webView(sender:UIButton) {
        let webVc = CommonWebVC.init(title: "保险须知", url: "http://www.yundiantrip.com")
        self.navigationController?.pushViewController(webVc, animated: true)
        
    }

    /**
     余额不足操作
     */
    func moneyIsTooLess() {
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

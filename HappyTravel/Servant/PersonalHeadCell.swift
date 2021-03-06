//
//  PersonalHeadCell.swift
//  HappyTravel
//
//  Created by 陈奕涛 on 16/8/4.
//  Copyright © 2016年 陈奕涛. All rights reserved.
//

import Foundation

protocol PersonalHeadCellDelegate: NSObjectProtocol {
    
    func followAction()
    func wenXin()
}

class PersonalHeadCell : UITableViewCell {
    
    weak var delegate:PersonalHeadCellDelegate?
    static var PI:Double = 3.1415926535898
    static var EARTH_R:Double = 6371.393000
    
    let tags = ["view": 1001,
                "personalView": 1002,
                "headImageView": 1003,
                "starLevelView": 1004,
                "officialAuth": 1005,
                "zhimaAuth": 1006,
                "authTips": 1007,
                "limitLab": 1008,
                "limitIcon": 1009,
                "followBtn": 1010,
                "wenXin": 1012,
                "followCntBtn": 1011]
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .None
        contentView.backgroundColor = UIColor.clearColor()
        userInteractionEnabled = true
        contentView.userInteractionEnabled = true
        
        let width = UIScreen.mainScreen().bounds.size.width
        
        var view = contentView.viewWithTag(tags["view"]!)
        if view == nil {
            view = UIView()
            view!.tag = tags["view"]!
            contentView.addSubview(view!)
            view?.snp_makeConstraints(closure: { (make) in
                make.left.equalTo(contentView)
                make.top.equalTo(contentView)
                make.right.equalTo(contentView)
                make.bottom.equalTo(contentView)
            })
        }
        
        var personalView = view?.viewWithTag(tags["personalView"]!) as? UIImageView
        if personalView == nil {
            personalView = UIImageView()
            personalView!.tag = tags["personalView"]!
            personalView!.backgroundColor = UIColor.redColor()
            personalView!.userInteractionEnabled = true
            view!.addSubview(personalView!)
            personalView!.snp_makeConstraints { (make) in
                make.top.equalTo(view!)
                make.left.equalTo(view!)
                make.width.equalTo(width)
                make.height.equalTo(AtapteWidthValue(width) / 3.0 * 2.0)
                make.bottom.equalTo(view!)
            }
            personalView?.image = UIImage.init(named: "defaultBg1")
        }
        
        var headImageView = personalView?.viewWithTag(tags["headImageView"]!) as? UIImageView
        if headImageView == nil {
            headImageView = UIImageView()
            headImageView!.tag = tags["headImageView"]!
            headImageView?.layer.cornerRadius = AtapteWidthValue(100) / 2
            headImageView?.layer.masksToBounds = true
            headImageView?.layer.borderWidth = 1
            headImageView?.layer.borderColor = UIColor.init(red: 183/255.0, green: 39/255.0, blue: 43/255.0, alpha: 1).CGColor
            headImageView!.userInteractionEnabled = true
            headImageView!.backgroundColor = UIColor.clearColor()
            personalView!.addSubview(headImageView!)
            headImageView!.snp_makeConstraints { (make) in
                make.left.equalTo(personalView!).offset(AtapteWidthValue(25))
                make.centerY.equalTo(personalView!)
                make.height.equalTo(AtapteWidthValue(100))
                make.width.equalTo(AtapteWidthValue(100))
            }
        }
        
        var starLevelView = personalView?.viewWithTag(tags["starLevelView"]!)
        if starLevelView == nil {
            starLevelView = UIView()
            starLevelView!.tag = tags["starLevelView"]!
            starLevelView?.backgroundColor = UIColor.clearColor()
            personalView!.addSubview(starLevelView!)
            starLevelView?.snp_makeConstraints(closure: { (make) in
                make.bottom.equalTo(personalView!).offset(AtapteWidthValue(-20))
                make.centerX.equalTo(headImageView!).offset(AtapteWidthValue(10))
                make.width.equalTo(AtapteWidthValue(width) / 3.0 + AtapteWidthValue(20))
                make.height.equalTo(AtapteHeightValue(20))
            })
            for i in 0...4 {
                var star = starLevelView?.viewWithTag(starLevelView!.tag * 10 + i) as? UIImageView
                if star == nil {
                    star = UIImageView()
                    star?.tag = starLevelView!.tag * 10 + i
                    star?.backgroundColor = UIColor.clearColor()
                    starLevelView?.addSubview(star!)
                    star?.snp_makeConstraints(closure: { (make) in
                        make.left.equalTo(starLevelView!.snp_left).offset(((width / 3.0 + 20) / 5.0) * CGFloat(i))
                        make.centerY.equalTo(starLevelView!)
                        make.width.equalTo(AtapteWidthValue(20))
                        make.height.equalTo(AtapteHeightValue(20))
                        
                    })
                    star?.image = UIImage.init(named: i > 3 ? "guide-star-hollow": "guide-star-fill")
                }
            }
        }
        
        var officialAuth = personalView?.viewWithTag(tags["officialAuth"]!) as? UIImageView
        if officialAuth == nil {
            officialAuth = UIImageView()
            officialAuth?.tag = tags["officialAuth"]!
            officialAuth?.backgroundColor = UIColor.clearColor()
            officialAuth?.contentMode = .ScaleAspectFit
            personalView?.addSubview(officialAuth!)
            officialAuth?.snp_makeConstraints(closure: { (make) in
                make.left.equalTo(personalView!).offset(AtapteWidthValue(20))
                make.top.equalTo(personalView!).offset(AtapteHeightValue(20))
                make.width.equalTo(AtapteWidthValue(20))
                make.height.equalTo(AtapteHeightValue(20))
            })
        }
        officialAuth?.image = UIImage.init(named: "renzheng")
        
        var zhimaAuth = personalView?.viewWithTag(tags["zhimaAuth"]!) as? UIImageView
        if zhimaAuth == nil {
            zhimaAuth = UIImageView()
            zhimaAuth?.tag = tags["zhimaAuth"]!
            zhimaAuth?.backgroundColor = UIColor.clearColor()
            zhimaAuth?.contentMode = .ScaleAspectFit
            personalView?.addSubview(zhimaAuth!)
            zhimaAuth?.snp_makeConstraints(closure: { (make) in
                make.left.equalTo(officialAuth!.snp_right).offset(AtapteWidthValue(10))
                make.top.equalTo(personalView!).offset(AtapteHeightValue(20))
                make.width.equalTo(AtapteWidthValue(20))
                make.height.equalTo(AtapteHeightValue(20))
            })
        }
        zhimaAuth?.image = UIImage.init(named: "guide-zhima-auth")
        zhimaAuth?.hidden = true
        
        var authTips = personalView?.viewWithTag(tags["authTips"]!) as? UILabel
        if authTips == nil {
            authTips = UILabel()
            authTips?.tag = tags["authTips"]!
            authTips?.backgroundColor = UIColor.clearColor()
            authTips?.textAlignment = .Right
            authTips?.textColor = UIColor.init(red: 240/255.0, green: 140/255.0, blue: 30/255.0, alpha: 1)
            authTips?.font = UIFont.boldSystemFontOfSize(AtapteWidthValue(S15))
            personalView?.addSubview(authTips!)
            authTips?.snp_makeConstraints(closure: { (make) in
                make.right.equalTo(personalView!).offset(AtapteWidthValue(-20))
                make.top.equalTo(personalView!).offset(AtapteHeightValue(20))
                make.height.equalTo(AtapteHeightValue(20))
            })
        }
        authTips?.text = "照片已认证"
        
        var limitLab = personalView?.viewWithTag(tags["limitLab"]!) as? UILabel
        if limitLab == nil {
            limitLab = UILabel()
            limitLab?.tag = tags["limitLab"]!
            limitLab?.backgroundColor = UIColor.clearColor()
            limitLab?.textAlignment = .Right
            limitLab?.textColor = .whiteColor()
            limitLab?.font = UIFont.boldSystemFontOfSize(AtapteWidthValue(S15))
            personalView?.addSubview(limitLab!)
            limitLab?.snp_makeConstraints(closure: { (make) in
                make.right.equalTo(personalView!).offset(AtapteWidthValue(-20))
                make.bottom.equalTo(personalView!).offset(AtapteHeightValue(-20))
                make.height.equalTo(AtapteHeightValue(20))
            })
        }
        limitLab?.text = "0 Km"
        
        var limitIcon = personalView?.viewWithTag(tags["limitIcon"]!) as? UIImageView
        if limitIcon == nil {
            limitIcon = UIImageView()
            limitIcon?.tag = tags["limitIcon"]!
            limitIcon?.backgroundColor = UIColor.clearColor()
            limitIcon?.contentMode = .ScaleAspectFit
            personalView?.addSubview(limitIcon!)
            limitIcon?.snp_makeConstraints(closure: { (make) in
                make.right.equalTo(limitLab!.snp_left).offset(AtapteWidthValue(-5))
                make.bottom.equalTo(limitLab!)
                make.width.equalTo(AtapteWidthValue(20))
                make.height.equalTo(AtapteHeightValue(20))
            })
            limitIcon?.image = UIImage.init(named: "limit")
        }

        var followBtn = personalView?.viewWithTag(tags["followBtn"]!) as? UIButton
        if followBtn == nil {
            followBtn = UIButton()
            followBtn?.tag = tags["followBtn"]!
            followBtn?.setTitle("+关注", forState: .Normal)
            followBtn?.setTitle("已关注", forState: .Selected)
            followBtn?.backgroundColor = UIColor.redColor()
            followBtn?.setTitleColor(UIColor.blackColor(), forState: .Normal)
            followBtn?.addTarget(self, action: #selector(follow), forControlEvents: .TouchUpInside)
            personalView?.addSubview(followBtn!)
            followBtn?.snp_makeConstraints(closure: { (make) in
                make.left.equalTo(limitIcon!)
                make.bottom.equalTo(limitIcon!.snp_top).offset(-10)
                make.width.equalTo(65)
                make.height.equalTo(30)
            })
        }
        followBtn?.selected = false
        
        var followCntBtn = personalView?.viewWithTag(tags["followCntBtn"]!) as? UIButton
        if followCntBtn == nil {
            followCntBtn = UIButton()
            followCntBtn?.tag = tags["followCntBtn"]!
            followCntBtn?.setTitle("0", forState: .Normal)
            followCntBtn?.backgroundColor = UIColor.greenColor()
            followCntBtn?.setTitleColor(UIColor.blackColor(), forState: .Normal)
            personalView?.addSubview(followCntBtn!)
            followCntBtn?.snp_makeConstraints(closure: { (make) in
                make.left.equalTo(followBtn!)
                make.bottom.equalTo(followBtn!.snp_top).offset(-10)
                make.width.equalTo(65)
                make.height.equalTo(30)
            })
        }
            

        var wenXinBtn = personalView?.viewWithTag(tags["wenXin"]!) as? UIButton
        if wenXinBtn == nil {
            wenXinBtn = UIButton()
            wenXinBtn?.tag = tags["wenXin"]!
            wenXinBtn?.setTitle("微信", forState: .Normal)
//            followBtn?.setTitle("已关注", forState: .Selected)
            wenXinBtn?.backgroundColor = UIColor.redColor()
            wenXinBtn?.setTitleColor(UIColor.blackColor(), forState: .Normal)
            wenXinBtn?.addTarget(self, action: #selector(wenXin), forControlEvents: .TouchUpInside)
            personalView?.addSubview(wenXinBtn!)
            wenXinBtn?.snp_makeConstraints(closure: { (make) in
                make.left.equalTo(followBtn!)
                make.bottom.equalTo(followCntBtn!.snp_top).offset(-10)
                make.width.equalTo(65)
                make.height.equalTo(30)
            })
        }
    }

    func follow(sender: UIButton) {
        delegate?.followAction()
    }
    func wenXin(sender: UIButton){
        delegate?.wenXin()
    }
    
    func setInfo(userInfo: UserInfoModel?, servantDetail: ServantDetailModel?, detailInfo: Dictionary<String, AnyObject>?, follow: Bool, followCnt: Int) {
        let view = contentView.viewWithTag(tags["view"]!)
        
        if let personalView = view!.viewWithTag(tags["personalView"]!) as? UIImageView {
//            if userInfo?.bigBGPhotoUrl != nil {                
//                let photoUrl = NSURL(string: (userInfo?.bigBGPhotoUrl!)!)
//                personalView.kf_setImageWithURL(photoUrl, placeholderImage: UIImage(named: "default-big-photo"), optionsInfo: nil, progressBlock: nil) { (image, error, cacheType, imageURL) in
//                    
//                }
//            }
            
            if let headImageView = personalView.viewWithTag(tags["headImageView"]!) as? UIImageView {
                if userInfo?.head_url_ != nil {
                    let headUrl = NSURL(string: userInfo!.head_url_!)
                    headImageView.kf_setImageWithURL(headUrl, placeholderImage: UIImage(named: "default-head"), optionsInfo: nil, progressBlock: nil) { (image, error, cacheType, imageURL) in
                        
                    }
                }
            }
            
            if let starLevelView = personalView.viewWithTag(tags["starLevelView"]!) {
                let level = userInfo?.praise_lv_
                for i in 0...4 {
                    if let star = starLevelView.viewWithTag(starLevelView.tag * 10 + i) as? UIImageView {
                        star.image = UIImage.init(named: (level! / Int(i+1) >= 1) ? "guide-star-fill" : "guide-star-hollow")
                    }
                }
            }
            
            if let officialAuth = personalView.viewWithTag(tags["officialAuth"]!) as? UIImageView {
                officialAuth.hidden = servantDetail!.is_certification_ == 1
            }
            
            if let limitLab = personalView.viewWithTag(tags["limitLab"]!) as? UILabel {
                let myLongitude = DataManager.curLocation?.coordinate.longitude ?? 0
                let myLatitude = DataManager.curLocation?.coordinate.latitude ?? 0
                let servantLongitude = userInfo?.longitude_
                let servantLatitude = userInfo?.latitude_
                limitLab.text = "\(String(format: "%.2f", CalcDistance(myLongitude, lat1: myLatitude, lon2: servantLongitude!, lat2: servantLatitude!))) Km"
            }
            
            if let followBtn = personalView.viewWithTag(tags["followBtn"]!) as? UIButton {
                followBtn.selected = follow
            }
            
            if let followCntBtn = personalView.viewWithTag(tags["followCntBtn"]!) as? UIButton {
                followCntBtn.setTitle("\(followCnt)", forState: .Normal)
            }
        }
        
    }
    
    func Angle2Radian(angle: Double) ->Double {
        return angle * PersonalHeadCell.PI / 180.0;
    }
    
    func CalcDistance(lon1: Double, lat1: Double, lon2: Double, lat2: Double) ->Double {
        let lat_a:Double = Angle2Radian(lat1)
        let lon_a:Double = Angle2Radian(lon1)
        let lat_b:Double = Angle2Radian(lat2)
        let lon_b:Double = Angle2Radian(lon2)
        return acos(sin(lat_a) * sin(lat_b) + cos(lat_a) * cos(lat_b) * cos(lon_a - lon_b)) * PersonalHeadCell.EARTH_R;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

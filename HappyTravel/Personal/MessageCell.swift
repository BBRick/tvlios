//
//  MessageCell.swift
//  HappyTravel
//
//  Created by 陈奕涛 on 16/8/25.
//  Copyright © 2016年 陈奕涛. All rights reserved.
//

import Foundation

class MessageCell: UITableViewCell {
    
    var userInfo:UserInfoModel?
    
    var msgInfo:MessageModel?
    var showDetailInfo:UIImageView = {
       let imageView = UIImageView()
        imageView.image = UIImage(named: "appointment-detail")
        return imageView
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .None
        contentView.backgroundColor = UIColor.clearColor()
        backgroundColor = UIColor.clearColor()
        
        var view = contentView.viewWithTag(101)
        if view == nil {
            view = UIView()
            view!.tag = 101
            view?.backgroundColor = UIColor.whiteColor()
            view?.layer.cornerRadius = 5
            view?.layer.masksToBounds = true
            contentView.addSubview(view!)
            view?.snp_makeConstraints(closure: { (make) in
                make.left.equalTo(contentView).offset(10)
                make.top.equalTo(contentView).offset(10)
                make.right.equalTo(contentView).offset(-10)
                make.bottom.equalTo(contentView)
            })
        }
        
        var headImageView = view?.viewWithTag(1001) as? UIImageView
        if headImageView == nil {
            headImageView = UIImageView()
            headImageView!.tag = 1001
            headImageView?.layer.cornerRadius = 45 / 2.0
            headImageView?.layer.masksToBounds = true
            headImageView?.layer.borderWidth = 1
            headImageView?.layer.borderColor = UIColor.init(red: 183/255.0, green: 39/255.0, blue: 43/255.0, alpha: 1).CGColor
            headImageView!.userInteractionEnabled = true
            headImageView!.backgroundColor = UIColor.clearColor()
            view!.addSubview(headImageView!)
            headImageView!.snp_makeConstraints { (make) in
                make.left.equalTo(view!).offset(14)
                make.top.equalTo(view!).offset(13)
                make.height.equalTo(45)
                make.width.equalTo(45)
            }
        }
        
        var nickNameLab = view?.viewWithTag(1002) as? UILabel
        if nickNameLab == nil {
            nickNameLab = UILabel()
            nickNameLab?.tag = 1002
            nickNameLab?.backgroundColor = UIColor.clearColor()
            nickNameLab?.textAlignment = .Left
            nickNameLab?.font = UIFont.systemFontOfSize(S15)
            view?.addSubview(nickNameLab!)
            nickNameLab?.snp_makeConstraints(closure: { (make) in
                make.left.equalTo(headImageView!.snp_right).offset(10)
                make.top.equalTo(view!).offset(16)
            })
        }
        
        var timeLab = view?.viewWithTag(1003) as? UILabel
        if timeLab == nil {
            timeLab = UILabel()
            timeLab?.tag = 1003
            timeLab?.backgroundColor = UIColor.clearColor()
            timeLab?.textAlignment = .Left
            timeLab?.textColor = UIColor.grayColor()
            timeLab?.font = UIFont.systemFontOfSize(S13)
            view?.addSubview(timeLab!)
            timeLab?.snp_makeConstraints(closure: { (make) in
                make.right.equalTo(view!).offset(-14)
                make.bottom.equalTo(nickNameLab!)
            })
        }
        
        var unreadCntLab = view?.viewWithTag(1103) as? UILabel
        if unreadCntLab == nil {
            unreadCntLab = UILabel()
            unreadCntLab?.tag = 1103
            unreadCntLab?.backgroundColor = UIColor.redColor()
            unreadCntLab?.textAlignment = .Center
            unreadCntLab?.textColor = UIColor.whiteColor()
            unreadCntLab?.font = UIFont.systemFontOfSize(S10)
            unreadCntLab?.layer.cornerRadius = 18 / 2.0
            unreadCntLab?.layer.masksToBounds = true
            view?.addSubview(unreadCntLab!)
            unreadCntLab?.snp_makeConstraints(closure: { (make) in
                make.right.equalTo((timeLab?.snp_right)!).offset(-20)
                make.top.equalTo(timeLab!.snp_bottom).offset(10)
                make.width.equalTo(18)
                make.height.equalTo(18)
            })
            unreadCntLab?.hidden = true
        }
        
        var msgLab = view?.viewWithTag(1004) as? UILabel
        if msgLab == nil {
            msgLab = UILabel()
            msgLab?.tag = 1004
            msgLab?.backgroundColor = UIColor.clearColor()
            msgLab?.textAlignment = .Left
            msgLab?.font = UIFont.systemFontOfSize(S13)
            msgLab?.textColor = UIColor.grayColor()
//            msgLab?.numberOfLines = 0
            msgLab?.numberOfLines = 2
            view?.addSubview(msgLab!)
            msgLab?.snp_makeConstraints(closure: { (make) in
                make.left.equalTo(nickNameLab!)
                make.top.equalTo(nickNameLab!.snp_bottom).offset(12)
                make.right.equalTo((unreadCntLab?.snp_left)!)
                make.bottom.equalTo(view!).offset(-13)
            })
        }
        
        view?.addSubview(showDetailInfo)
        showDetailInfo.snp_makeConstraints { (make) in
            make.top.equalTo((timeLab?.snp_bottom)!).offset(10)
            make.right.equalTo(timeLab!)
        }
    }

    
    func setInfo(message: MessageModel?, unreadCnt: Int) {
        msgInfo = message

        if msgInfo?.msg_type_ == PushMessage.MessageType.Appointment.rawValue {
            
            showDetailInfo.hidden = false
            setAppointmentInfo(message, unreadCnt: unreadCnt)
        } else if msgInfo?.msg_type_ ==  PushMessage.MessageType.Location.rawValue {
            showDetailInfo.hidden = true
            setLocationInfo(message, unreadCnt: unreadCnt)
        } else {
            showDetailInfo.hidden = true

            setNormalInfo(message, unreadCnt: unreadCnt)
        }
        
        let view = contentView.viewWithTag(101)

        if let timeLab = view!.viewWithTag(1003) as? UILabel {
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeStyle = .ShortStyle
            dateFormatter.dateStyle = .ShortStyle
            let dateStr = dateFormatter.stringFromDate(NSDate(timeIntervalSince1970: NSNumber.init(longLong: message!.msg_time_).doubleValue))
            timeLab.text = dateStr
        }
        
        if let unreadCntLab = view!.viewWithTag(1103) as? UILabel {
            
            if unreadCnt > 0 {
                unreadCntLab.hidden = false
                unreadCntLab.text = "\(unreadCnt)"
            } else {
                unreadCntLab.hidden = true
            }
        }
        
    }
    
    func setNormalInfo(message: MessageModel?, unreadCnt: Int) {
        let view = contentView.viewWithTag(101)

        if let headView = view!.viewWithTag(1001) as? UIImageView {
            var uid = 0
            if message!.from_uid_ == CurrentUser.uid_ {
                uid = message!.to_uid_
            } else {
                uid = message!.from_uid_
            }
            if let user = DataManager.getData(UserInfoModel.self, filter: "uid_ = \(uid)")?.first {
                userInfo = user
                headView.kf_setImageWithURL(NSURL(string: userInfo!.head_url_!), placeholderImage: UIImage(named: "touxiang_women"), optionsInfo: nil, progressBlock: nil) { (image, error, cacheType, imageURL) in
                    
                }
                if let nickNameLab = view!.viewWithTag(1002) as? UILabel {
                    nickNameLab.text = userInfo!.nickname_!
                }
                
                if let msgLab = view!.viewWithTag(1004) as? UILabel {
                    var nickname:String?
                    if message!.from_uid_ == CurrentUser.uid_ {
                        nickname = CurrentUser.nickname_
                    } else {
                        nickname = userInfo?.nickname_
                    }
                    msgLab.text = "\(nickname!) : \((message?.content_!)!)"
                }
            }
            
        }
    }
    
    func setLocationInfo(message: MessageModel?, unreadCnt: Int) {
        let view = contentView.viewWithTag(101)

        if let headView = view!.viewWithTag(1001) as? UIImageView {
            var uid = 0
            if message!.from_uid_ == CurrentUser.uid_ {
                uid = message!.to_uid_
            } else {
                uid = message!.from_uid_
            }
            if let user = DataManager.getData(UserInfoModel.self, filter: "uid_ = \(uid)")?.first {
                userInfo = user
                headView.kf_setImageWithURL(NSURL(string: userInfo!.head_url_!), placeholderImage: UIImage(named: "touxiang_women"), optionsInfo: nil, progressBlock: nil) { (image, error, cacheType, imageURL) in

                }
                if let nickNameLab = view!.viewWithTag(1002) as? UILabel {
                    nickNameLab.text = userInfo!.nickname_!
                }
                
                if let msgLab = view!.viewWithTag(1004) as? UILabel {
                    var nickname:String?
                    if message!.from_uid_ == CurrentUser.uid_ {
                        nickname = CurrentUser.nickname_
                    } else {
                        nickname = userInfo?.nickname_
                    }
                    msgLab.text = "\(nickname!) : \("[位置分享]")"
                }
            }
            
        }
        
    }
    
    func setAppointmentInfo(message: MessageModel?, unreadCnt: Int) {
        
        let view = contentView.viewWithTag(101)
        if let headView = view!.viewWithTag(1001) as? UIImageView {
            headView.image = UIImage(named: "touxiang_women")
                if let nickNameLab = view!.viewWithTag(1002) as? UILabel {
                    nickNameLab.text = "预约推荐"
                }
                if let msgLab = view!.viewWithTag(1004) as? UILabel {
                    msgLab.text = message?.content_

                }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

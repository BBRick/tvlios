//
//  CenturionCardModels.swift
//  HappyTravel
//
//  Created by 陈奕涛 on 17/1/3.
//  Copyright © 2017年 陈奕涛. All rights reserved.
//

import Foundation
import RealmSwift


class CenturionCardBaseInfoModel: Object {
    
    dynamic var privilege_bg_:String?
    
    dynamic var privilege_details_:String?
    
    dynamic var privilege_id_:Int = 0
    
    dynamic var privilege_lv_:Int = 0
    
    dynamic var privilege_name_:String?
    
    dynamic var privilege_pic_no_:String?
    
    dynamic var privilege_pic_yes_:String?
    
    dynamic var privilege_summary_:String?
    
}

class CenturionCardBaseInfosModel: Object {
    
    let privilege_list_ = List<CenturionCardBaseInfoModel>()
    
}

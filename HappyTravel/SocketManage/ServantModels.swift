//
//  ServantModels.swift
//  HappyTravel
//
//  Created by 陈奕涛 on 17/1/9.
//  Copyright © 2017年 陈奕涛. All rights reserved.
//

import Foundation
import RealmSwift


class ServiceModel: Object {
    
    dynamic var service_id_ = -1
    
    dynamic var service_name_:String?
    
    dynamic var service_price_ = 0
    
    dynamic var service_type_ = 0
    
    dynamic var service_start_ = 0
    
    dynamic var service_end_ = 0
}

class ServantDetailModel: Object {
 
    dynamic var uid_ = -1
    
    dynamic var is_certification_ = 0
    
    dynamic var heag_bg_url_:String?
    
    dynamic var traval_tag_:String?
    
    var tags:[String] {
        if let arrTags = traval_tag_?.componentsSeparatedByString(",") {
            return arrTags
        }
        
        return []
    }
    
    let service_list_ = List<ServiceModel>()
}

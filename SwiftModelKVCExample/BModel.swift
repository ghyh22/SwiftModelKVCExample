//
//  BModel.swift
//  ModelKVC
//
//  Created by 龚浩 on 2017/5/24.
//  Copyright © 2017年 龚浩. All rights reserved.
//

import UIKit

class BModel: AModel {
    typealias MySelf = BModel
    
    var birth = ""
    var address = ""
    override var description: String{
        return super.description + ",birth=\(birth), address=\(address)"
    }
}

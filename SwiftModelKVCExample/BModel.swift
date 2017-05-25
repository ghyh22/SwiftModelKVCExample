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
    var model:CModel = CModel()
    override var description: String{
        return "{ name=\(name), sex=\(sex), age=\(age), birth=\(birth), address=\(address), model=\(model) }"
    }
    
    override func registerClassList() -> [AnyClass] {
        return [CModel.self]
    }
}

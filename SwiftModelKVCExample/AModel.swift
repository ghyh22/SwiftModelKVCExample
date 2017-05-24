//
//  AModel.swift
//  ModelKVC
//
//  Created by 龚浩 on 2017/5/24.
//  Copyright © 2017年 龚浩. All rights reserved.
//

import UIKit

class AModel: NSObject, SwiftKVCModelProtocol {
    var name = ""
    var sex = false
    var age = 0
    
    required override init() {
        super.init()
    }
    
    static func createModel() -> Self {
        return self.init()
    }
    func registerClassList() -> [SwiftKVCModelProtocol] {
        return []
    }
    func arrayProperTypeList() -> [String : SwiftKVCModelProtocol] {
        return [:]
    }
    
    override var description: String{
        return "name=\(name), sex=\(sex), age=\(age)"
    }
}

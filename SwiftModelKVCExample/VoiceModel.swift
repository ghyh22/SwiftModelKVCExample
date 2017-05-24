//
//  TestModel.swift
//  ForModelJSON
//
//  Created by 龚浩 on 2017/5/4.
//  Copyright © 2017年 龚浩. All rights reserved.
//

import UIKit

class VoiceModel: NSObject,SwiftKVCModelProtocol {

    static func createModel() -> Self {
        return self.init()
    }
    
    func registerClassList() -> [SwiftKVCModelProtocol] {
        return [AModel.self as! SwiftKVCModelProtocol, BModel.self as! SwiftKVCModelProtocol]
    }
    
    func arrayProperTypeList() -> [String : SwiftKVCModelProtocol] {
        return ["arr":BModel.self as! SwiftKVCModelProtocol]
    }

    required override init() {
        super.init()
    }
    
    var name = "讲解"
    var jsonNullDic = ["three": 3]
    var jsonNullNum = 4
    var jsonNullStr = "eee"
    var jsonNullArr = [3,4]
    var jsonIsStringNull = 5
    var jsonBool = true
    var a = AModel()
    var arr = [BModel]()
}
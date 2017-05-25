//
//  CModel.swift
//  SwiftModelKVCExample
//
//  Created by 龚浩 on 2017/5/25.
//  Copyright © 2017年 龚浩. All rights reserved.
//

import UIKit

class CModel: NSObject,SwiftKVCModelProtocol {
    var id:Int = 0
    var name:String = ""
    
    override var description: String{
        return "{ id=\(id), name=\(name) }"
    }
    
    required override init() {
        super.init()
    }
    
    static func createModel() -> Self {
        return self.init()
    }
    
    func registerClassList() -> [AnyClass] {
        return []
    }
    
    func arrayProperTypeList() -> [String : AnyClass] {
        return [:]
    }
}

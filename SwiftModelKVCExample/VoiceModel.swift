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
    
    ///在model中的a,b属性分别是AModel,BModel类型
    ///要想SwiftKVCModel工具能正确定找到这两个类型，需要在这里获取它们
    ///为测试我没有将c属性对应的类型CModel加入,测试结果:c将不会被赋值
    func registerClassList() -> [AnyClass] {
        return [AModel.self, BModel.self]
    }
    ///在model中的arr是数组类型，并且元素是BModel
    ///要想SwiftKVCModel工具能正确生成BModel数组，需要在这里设置好它们的匹配关系
    ///为测试我没有将bArr对应的元素属性CModel加入，测试结果:bArr将不会被赋值
    func arrayProperTypeList() -> [String : AnyClass] {
        //[属性名:元素类型]
        return ["arr":BModel.self]
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
    var b = BModel()
    var c = CModel()
    var arr = [BModel]()
    var bArr = [CModel]()
    var array = [Any]()
    var dic = [String:Any]()
}

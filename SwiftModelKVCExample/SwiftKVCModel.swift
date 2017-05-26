//
//  FirstModel.swift
//  ModelKVC
//
//  Created by 龚浩 on 2017/5/11.
//  Copyright © 2017年 龚浩. All rights reserved.
//
import UIKit

//使用SwiftKVCModel的Model类必须遵循的协议
protocol SwiftKVCModelProtocol:NSObjectProtocol {
    /// 必须在没有参数的情况下，这个model能被创建
    ///
    /// - Returns:
    static func createModel()->Self
    /**
     注册model中所需要使用的其它model类的类型,model必须遵循本协议
     
     @return model类列表
     */
    func registerClassList()->[AnyClass]
    
    /**
     注册数组属性所需要的的类型,当model中有属性是数组类型时，指定数组的model类型,model必须遵循本协议
     
     @return 属性名和它对应的类型列表
     */
    func arrayProperTypeList()->[String:AnyClass]
}

class SwiftKVCModel: NSObject {
    
    @discardableResult static func kvcFor(model:SwiftKVCModelProtocol, dic:[String:Any])->SwiftKVCModel? {
        if let kvc = SwiftKVCModel(model: model) {
            kvc.dictToModel(dic: dic)
            return kvc
        }
        return nil
    }
    /// 是否显示字典中多余key的检测信息
    var showExtraKey = true
    
    /// 不检测NSObject本身公有属性
    let noContaintProp = ["hash","superclass","description","debugDescription"]
    let model:SwiftKVCModelProtocol
    var object:NSObject{
        return model as! NSObject
    }
    init?(model:SwiftKVCModelProtocol) {
        if model is NSObject {
            self.model = model
        }else{
            print("\(type(of: model))-KVC:mod没有继承NSObject.")
            return nil
        }
        super.init()
        initPTVList()
    }
    func initPTVList(){
        _ptvList = []
        _properties = []
        if var cl = (self.model as AnyObject).classForCoder {
            var len:UInt32 = 0
            var nilPropers = ""
            while cl != NSObject.self {
                let props = class_copyPropertyList(cl, &len)
                for tmp in 0..<len {
                    let char = property_getName(props?.advanced(by: Int(tmp)).pointee)
                    if let prop = NSString(utf8String: char!) as String? {
                        if noContaintProp.index(of: prop) == nil {
                            if let modelValue = self.object.value(forKey: prop) {
                                let ptv = PTV(name: prop, value: modelValue)
                                _ptvList.append(ptv)
                            }else{
                                nilPropers += prop + ","
                            }
                            _properties.append(prop)
                        }
                    }
                }
                free(props)
                cl = class_getSuperclass(cl)
            }
            
            if nilPropers.characters.count > 0 {
                print("\(type(of: self.model))model中有未被初始化的属性:\(nilPropers),将不会被KVC赋值")
            }
        }
    }
    
    fileprivate var _ptvList:[PTV]!
    fileprivate var _properties:[String] = []
    var ptvList:[PTV]{
        return _ptvList
    }
    func findPTV(key:String) -> PTV? {
        for tmp in ptvList {
            if tmp.name == key {
                return tmp
            }
        }
        return nil
    }
    
    func dictToModel(dic:[String:Any]) {
        var propers = _properties
        dicExtraKeys = []
        for (k,v) in dic {
            if setKeyValue(v, forKey: k) {
                if let index = propers.index(of: k) {
                    propers.remove(at: index)
                }
            }
        }
        if propers.count > 0 {
            var str = "\(type(of: self.model))-KVC:model中有的属性，而字典中没有出现的key: "
            for tmp in propers {
                str += tmp + ","
            }
            print(str)
        }
        if dicExtraKeys.count > 0{
            var str = "\(type(of: self.model))-KVC:字典中有key，而model中没有找到对应的属性:"
            for tmp in dicExtraKeys {
                str += tmp + ","
            }
            print(str)
        }
    }
    
    /// 返回list中的值时，代表空值
    /// 比如：key值为"<null>"时，代表这个key值为空
    ///
    /// - Returns:
    //    func getNilList() -> [Any] {
    //        return ["<null>"]
    //    }
    
    /// 获取model已注册的对应类,
    ///
    /// - Parameter kvc:必须遵循了SwiftKVCModelProtocol协议的对象
    /// - Returns:
    func getClass(kvc:SwiftKVCModelProtocol)->SwiftKVCModelProtocol.Type?{
        let classList = model.registerClassList()
        for cl in classList {
            if let kvcClass = cl as? SwiftKVCModelProtocol.Type{
                if type(of:kvc) == kvcClass {
                    return kvcClass
                }
            }
        }
        return nil
    }
    
    /// 字典中有而model中没有的key(属性)
    var dicExtraKeys:[String] = [];
    /// KVC处理
    /// 使用要求:model中所有属性要求有非空的初始值
    ///
    /// - Parameters:
    ///   - value:
    ///   - key:
    func setKeyValue(_ value: Any?, forKey key: String)->Bool {
        if let ptv = findPTV(key: key) {
            //处理key值为空的情况
            if value == nil || value is NSNull {
                return handleValueIsNil(forKey: key, ptv: ptv)
            }
            if let tmp = value as? String {
                //将字符串"<null>"视为空值处理
                if tmp == "<null>" {
                    return handleValueIsNullStr(forKey: key, ptv: ptv)
                }
            }
            if let value = value {
                let valuePTV = PTV(name: key, value: value)
                if ptv.type == .other {
                    if let kvc = ptv.valueObject as? SwiftKVCModelProtocol {
                        //处理其它类型，并且key值为字典的情况
                        if let dic = value as? [String:Any] {
                            //如果能在model的已注册的类型列表(registerClassList)中找到对应的类型,那就用字典生成model赋值为属性
                            if let classType = getClass(kvc: kvc) {
                                if !self.model.isKind(of: classType) {//防止model包含自身类型的属性产生死循环
                                    let tmp = classType.createModel()
                                    SwiftKVCModel.kvcFor(model: tmp , dic: dic)
                                    self.object.setValue(tmp, forKey: key)
                                    return true
                                }
                            }
                        }
                    }
                //未知类型不进行赋值
                }else if ptv.type == .unknown {
                    print("\(type(of: self.model))-KVC:mod中的属性:\(key)类型未知，取消赋值")
                    return true
                }
                // 处理同类型赋值
                if valuePTV.type == ptv.type {
                    //处理都为数组时
                    if ptv.type == .array && valuePTV.type == .array {
                        //处理数组是字典数组的情况
                        if let arr = value as? [[String:Any]] {
                            if arr.count > 0 {
                                return handleArray(forKey: key, ptv: ptv, value: arr)
                            }else{
                                self.object.setValue([], forKey: key)
                                return true
                            }
                        }
                    }
                    
                    self.object.setValue(value, forKey: key)
                    return true
                }
                //处理属性为number属性,key为string类型时，将字符串化为数值赋值
                if ptv.type == .number && valuePTV.type == .string {
                    if let n = (value as? NSString)?.floatValue {
                        self.object.setValue(n, forKey: key)
                    }else{
                        self.object.setValue(0, forKey: key)
                    }
                    if let resutl = self.object.value(forKey: key) {
                        print("\(type(of: self.model))-KVC:字典中key:\(key)类型为string与mod对应的属性:\(key)类型number不同，最终属性值被赋值成了number类型值\(resutl)")
                    }
                    return true
                }
                //处理属性为string属性,key为number类型时，将数值转化为字符串赋值
                if ptv.type == .string && valuePTV.type == .number {
                    if let n = (value as? NSNumber) {
                        self.object.setValue("\(n)", forKey: key)
                        
                        if let resutl = self.object.value(forKey: key) {
                            print("\(type(of: self.model))-KVC:字典中key:\(key)类型为number与mod对应的属性:\(key)类型string不同，最终属性值被赋值成了string类型值\(resutl)")
                        }
                        return true
                    }
                }
                //处理当属性为Bool类型时，如果key是string类型并且值="false"或"true"时进行转化赋值
                if ptv.type == .bool && valuePTV.type == .string {
                    if let str = value as? String {
                        if str == "false" {
                            self.object.setValue(false, forKey: key)
                            print("\(type(of: self.model))-KVC:字典中key:\(key)类型为string值false与mod对应的属性:\(key)类型bool不同，最终属性值被赋值成了bool类型值false")
                            return true
                        }else if str == "true" {
                            self.object.setValue(true, forKey: key)
                            print("\(type(of: self.model))-KVC:字典中key:\(key)类型为string值true与mod对应的属性:\(key)类型bool不同，最终属性值被赋值成了bool类型值true")
                            return true
                        }
                    }
                }
                
                print("\(type(of: self.model))-KVC:字典中key:\(key)类型为\(valuePTV.type)与model对应的属性:\(key)类型\(ptv.type)不兼容,取消赋值")
                return true
            }
        }else{
            if showExtraKey {
//                print("\(type(of: self.model))-KVC:model中没有找到对应的key:\(key)")
                dicExtraKeys.append(key)
            }
        }
        return false
    }
    
    /// 处理值为空的情况,如果model中有key对应的属性,做如下处理:
    /// 如果属性是数值类型赋值为0
    /// 是字符串类型赋值为""
    /// 是字典类型赋一个空的字典(不是空值)
    /// 是数组类型赋一个空的数组(不是空值)
    /// - Parameters:
    ///   - value:
    ///   - key:
    fileprivate func handleValueIsNil(forKey key: String, ptv:PTV) -> Bool{
        switch ptv.type {
        case .number:
            self.object.setValue(0, forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为空(null)，对应属性类型为\(ptv.type)值为\(ptv.valueObject),重新赋值为0")
            return true
        case .array:
            self.object.setValue([], forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为空(null)，对应属性类型为\(ptv.type)值为\(ptv.valueObject),重新赋值为空的数组[](不是空值)")
            return true
        case .bool:
            self.object.setValue(false, forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为空(null)，对应属性类型为\(ptv.type)值为\(ptv.valueObject),重新赋值为false")
            return true
        case .dictionary:
            self.object.setValue([:], forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为空(null)，对应属性类型为\(ptv.type)值为\(ptv.valueObject),重新赋值为空的字典[:](不是空值)")
            return true
        case .string:
            self.object.setValue("", forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为空(null)，对应属性类型为\(ptv.type)值为\(ptv.valueObject),重新赋值为空串\"\"(不是空值)")
            return true
        case .unknown:
            self.object.setValue(nil, forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为空(null)，对应属性类型为\(ptv.type)值为\(ptv.valueObject),没有进行重新赋值")
            return true
        case .other:
            self.object.setValue(nil, forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为空(null)，对应属性类型为\(ptv.type)值为\(ptv.valueObject),没有进行重新赋值")
            return true
        }
    }
    /// 处理值为<null>字符串的情况,如果model中有key对应的属性,做如下处理:
    /// 如果属性是数值类型赋值为0
    /// 是字符串类型赋值为""
    /// 是字典类型赋一个空的字典(不是空值)
    /// 是数组类型赋一个空的数组(不是空值)
    /// - Parameters:
    ///   - value:
    ///   - key:
    fileprivate func handleValueIsNullStr(forKey key: String, ptv:PTV) -> Bool{
        let rc = ptv.type
        let modelValue = ptv.valueObject
        switch ptv.type {
        case .number:
            self.object.setValue(0, forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为'<null>'字符串，对应属性类型为\(rc)值为\(modelValue),重新赋值为0")
            return true
        case .array:
            self.object.setValue([], forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为'<null>'字符串，对应属性类型为\(rc)值为\(modelValue),重新赋值为空的数组[](不是空值)")
            return true
        case .bool:
            self.object.setValue(false, forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为'<null>'字符串，对应属性类型为\(ptv.type)值为\(ptv.valueObject),重新赋值为false")
            return true
        case .dictionary:
            self.object.setValue([:], forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为'<null>'字符串，对应属性类型为\(rc)值为\(modelValue),重新赋值为空的字典[:](不是空值)")
            return true
        case .string:
            self.object.setValue("", forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为'<null>'字符串，对应属性类型为\(rc)值为\(modelValue),重新赋值为空串\"\"(不是空值)")
            return true
        case .unknown:
            self.object.setValue(nil, forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为'<null>'字符串，对应属性类型为\(ptv.type)值为\(ptv.valueObject),没有进行重新赋值")
            return true
        case .other:
            self.object.setValue(nil, forKey: key)
            print("\(type(of: self.model))-KVC:字典中key:\(key)的值为'<null>'字符串，对应属性类型为\(ptv.type)值为\(ptv.valueObject),没有进行重新赋值")
            return true
        }
    }
    
    fileprivate func handleArray(forKey key: String, ptv:PTV, value:[[String:Any]]) -> Bool{
        let arrayTypeList = model.arrayProperTypeList()
        if let type = arrayTypeList[key] {
            if let t = type as? SwiftKVCModelProtocol.Type {
                var modelArr = [SwiftKVCModelProtocol]()
                for object in value {
                    let model = t.createModel()
                    SwiftKVCModel.kvcFor(model: model, dic: object)
                    modelArr.append(model)
                }
                self.object.setValue(modelArr, forKey: key)
                return true
            }else{
                print("\(type(of: self.model))-KVC:对应属性:\(key)的类型为array,但arrayProperTypeList与它匹配的类型没有遵循SwiftKVCModelProtocol协议，取消赋值.")
                return true
            }
        }else{
            print("\(type(of: self.model))-KVC:对应属性:\(key)的类型为array,但arrayProperTypeList没有与它匹配的类型，取消赋值.")
            return true
        }
    }
}

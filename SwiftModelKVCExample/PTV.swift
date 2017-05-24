//
//  PTV.swift
//  ModelKVC
//
//  Created by 龚浩 on 2017/5/8.
//  Copyright © 2017年 龚浩. All rights reserved.
//

import UIKit

/// 属性，类型，值
class PTV: NSObject {
    let name:String
    var type:PTVType = .unknown
    var classType:AnyClass{
        return type(of:valueObject) as! AnyClass
    }
    fileprivate var rawNumber:NSNumber = 0
    fileprivate var rawString:String = ""
    fileprivate var rawBool:Bool = true
    fileprivate var rawArray:[Any] = [Any]()
    fileprivate var rawDictionary:[String:Any] = [String:Any]()
    fileprivate var rawOther:SwiftKVCModelProtocol!
    var error:String?
    var valueObject:Any{
        set{
            error = nil
            switch newValue {
            case let number as NSNumber:
                if number.isBool {
                    type = .bool
                    rawBool = number.boolValue
                }else{
                    type = .number
                    rawNumber = number
                }
            case let str as String:
                type = .string
                rawString = str
            case let arr as [Any]:
                type = .array
                rawArray = arr
            case let dic as [String:Any]:
                type = .dictionary
                rawDictionary = dic
            default:
                if let kvc = newValue as? SwiftKVCModelProtocol {
                    rawOther = kvc
                    type = .other
                    return
                }
                type = .unknown
            }
        }
        get{
            switch type {
            case .number:
                return rawNumber
            case .string:
                return rawString
            case .bool:
                return rawBool
            case .array:
                return rawArray
            case .dictionary:
                return rawDictionary
            default:
                return rawOther
            }
        }
    }
    
    init(name:String, value:Any) {
        self.name = name
        super.init()
        self.valueObject = value
    }
    
    override var description: String {
        return "属性:\(name)-类型:\(type)-值:\(valueObject)"
    }
}

///
///
/// - string:
/// - number:
/// - bool:
/// - array:
/// - dictionary:
/// - other: 在KVCModel中已注册的类型
/// - unknown: 不在以上范围内的未知类型
enum PTVType{
    case string,number,bool,array,dictionary,other,unknown
}

//处理bool值
private let trueNumber = NSNumber(value: true)
private let falseNumber = NSNumber(value: false)
private let trueObjCType = String(cString: trueNumber.objCType)
private let falseObjCType = String(cString: falseNumber.objCType)

// MARK: - NSNumber: Comparable

extension NSNumber {
    var isBool: Bool {
        let objCType = String(cString: self.objCType)
        if (self.compare(trueNumber) == .orderedSame && objCType == trueObjCType) || (self.compare(falseNumber) == .orderedSame && objCType == falseObjCType) {
            return true
        } else {
            return false
        }
    }
}

//
//  ViewController.swift
//  SwiftModelKVCExample
//
//  Created by 龚浩 on 2017/5/24.
//  Copyright © 2017年 龚浩. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        testSwiftKVCModel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func testSwiftKVCModel() {
        let model = VoiceModel()
        let path = Bundle(for: type(of:self)).path(forResource: "data", ofType: "json")
        do{
            let str = try String(contentsOfFile: path!, encoding: .utf8)
            if let dic = try JSONSerialization.jsonObject(with: str.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:Any] {
                SwiftKVCModel.kvcFor(model: model, dic: dic)
            }
        }catch let error {
            print(error)
        }
        
        showProps(voice: model)
    }

    func showProps(voice:NSObject) {
        print("-------------所有属性和对应值-----------------")
        var len:UInt32 = 0
        if let cl = (voice as AnyObject).classForCoder {
            let props = class_copyPropertyList(cl, &len)
            for tmp in 0..<len {
                let char = property_getName(props?.advanced(by: Int(tmp)).pointee)
                if let prop = NSString(utf8String: char!) as String? {
                    if let result = voice.value(forKey: prop) {
                        print(prop, result)
                    }else{
                        print(prop, "nil")
                    }
                }
            }
            free(props)
        }
    }
}


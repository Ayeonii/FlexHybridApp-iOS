//
//  FlexAction.swift
//  FlexHybridApp
//
//  Created by dvkyun on 2020/09/01.
//  Copyright © 2020 dvkyun. All rights reserved.
//

import Foundation

public class FlexAction {
    
    private let funcName: String
    private let mComponent: FlexComponent
    private var isCall = false
    
    internal init (_ name: String, _ component: FlexComponent) {
        funcName = name
        mComponent = component
    }
    
    private func pRetrun(_ response: Any?) {
        if isCall {
            FlexMsg.err(FlexString.ERROR7)
            return
        }
        isCall = true
        if response is BrowserException {
            let reason = (response as! BrowserException).reason == nil ? "null" : "\"\((response as! BrowserException).reason!)\""
            mComponent.evalJS("$flex.flex.\(funcName)(false, \(reason))")
        } else if response == nil || response is Void {
            mComponent.evalJS("$flex.flex.\(funcName)(true)")
        } else {
            do {
                mComponent.evalJS("$flex.flex.\(funcName)(true, null, \(try FlexFunc.convertValue(response!)))")
            } catch FlexError.UnuseableTypeCameIn {
                FlexMsg.err(FlexString.ERROR3)
                mComponent.evalJS("$flex.flex.\(funcName)(false, \"\(FlexString.ERROR3)\")")
            } catch {
                FlexMsg.err(error)
                mComponent.evalJS("$flex.flex.\(funcName)(false, \"\(error.localizedDescription)\")")
            }
        }
    }
    
    public func promiseReturn(_ response: Void) {
        pRetrun(response)
    }
       
    public func promiseReturn(_ response: String) {
        pRetrun(response)
    }
    
    public func promiseReturn(_ response: Int) {
        pRetrun(response)
    }
    
    public func promiseReturn(_ response: Float) {
        pRetrun(response)
    }
    
    public func promiseReturn(_ response: Double) {
        pRetrun(response)
    }
    
    public func promiseReturn(_ response: Character) {
        pRetrun(response)
    }
    
    public func promiseReturn(_ response: Bool) {
        pRetrun(response)
    }
    
    public func promiseReturn(_ response: Array<Any?>) {
        pRetrun(response)
    }
    
    public func promiseReturn(_ response: Dictionary<String,Any?>) {
        pRetrun(response)
    }
    
    public func promiseReturn(_ response: BrowserException) {
        pRetrun(response)
    }
    
    public func promiseReturn() {
        pRetrun(nil)
    }
    
    public func resolveVoid() {
        if isCall {
            FlexMsg.err(FlexString.ERROR7)
            return
        }
        isCall = true
        mComponent.evalJS("$flex.flex.\(funcName)(true)")
    }
    
    public func reject(reason: BrowserException) {
        if isCall {
            FlexMsg.err(FlexString.ERROR7)
            return
        }
        isCall = true
        let rejectReson = reason.reason == nil ? "null" : "\"\(reason.reason!)\""
        mComponent.evalJS("$flex.flex.\(funcName)(false, \(rejectReson))")
    }
    
    public func reject(reason: String) {
        if isCall {
            FlexMsg.err(FlexString.ERROR7)
            return
        }
        isCall = true
        mComponent.evalJS("$flex.flex.\(funcName)(false, \"\(reason)\")")
    }
    
    public func reject() {
        if isCall {
            FlexMsg.err(FlexString.ERROR7)
            return
        }
        isCall = true
        mComponent.evalJS("$flex.flex.\(funcName)(false)")
    }
    
}

//
//  EventBus.swift
//  GenialTone
//
//  Created by 五月 on 2017/7/13.
//  Copyright © 2017年 Kent. All rights reserved.
//

import Foundation

class Action {
    let subscriberId: Int
    let eventName: String
    let eventType: Any
    let action: Any

    init(subscriberId: Int, eventName: String, eventType: Any, action: Any) {
        self.subscriberId = subscriberId
        self.eventName = eventName
        self.eventType = eventType
        self.action = action
    }
}

class WeakObject<T: AnyObject> {
    weak var object: T?

    init(_ object: T?) {
        self.object = object
    }

    func hasValue() -> Bool {
        return object != nil
    }

    var value: T {
        get {
            return object!
        }
    }
}

/// 事件总线，提供各模块之间的事件发布和订阅，方便模块之间通讯和交互
/// 为了使用便捷性，这里定义了两个角色，订阅者（subscriber）和事件处理器（action）
/// 每个订阅者可以有多个事件处理器，引入订阅者在取消订阅时可以方便一次取消订阅者的所有事件处理器

class EventBus: NSObject {
    private static let defaultInstance = EventBus()
    private static var instanceList: [WeakObject<EventBus>] = []

    //事件处理器表，每个事件可以有多个处理器
    private var actionMap: [String: [Action]] = [:]
    //订阅者表，记录每个订阅者所有事件处理器，这里和actionMap为冗余数据，方便代码处理
    private var subscriberMap: [Int: [Action]] = [:]
    //必达消息表，必达消息会保证最后一条消息一定会送达订阅者，即使消息产生是在订阅者订阅之前也会保证订阅者收到最后一条消息
    private var stickyEventMap: [String: Any] = [:]
    //业务线程队列，所有的业务操作都会在该线程中执行
    private let queue = OperationQueue()

    override init() {
        super.init()

        EventBus.instanceList.append(WeakObject(self))
        //为了避免线程通过采用单线程
        queue.maxConcurrentOperationCount = 1
    }

    static func getDefault() -> EventBus {
        return defaultInstance
    }

    /// 订阅事件、每个订阅者可以有多个事件处理器，引入subscriber在取消订阅时可以方便一次取消订阅者的所有事件处理器
    /// 订阅事件会根据事件类型（T）来匹配，比如可以订阅String类型的消息等
    /// 注意：虽然subscribe方法不会引用subscriber对象，但是block中可能会引用self，所以一定要注意循环引用问题，在适当的时机调用unsubscribe释放block引用
    func subscribe<T>(_ subscriber: AnyObject, _ action: @escaping(_ event: T) -> Void) {
        let id = self.getSubscriberId(subscriber)
        let eventName = self.getEventName(T.self)
        let actionData = Action(subscriberId: id, eventName: eventName, eventType: T.self, action: action)
        queue.addOperation {
            if (self.actionMap[eventName] == nil) {
                self.actionMap[eventName] = []
            }
            self.actionMap[eventName]!.append(actionData)
            if (self.subscriberMap[id] == nil) {
                self.subscriberMap[id] = []
            }
            self.subscriberMap[id]!.append(actionData)

            //如果有必达消息，那么发送必达消息
            if let event: T = self.getStickyEvent() {
                self.dispatchEvent(event: event, action: action)
            }
        }
    }

    /// 取消订阅当前对象的所有事件，该方法会释放内部持有的相关block
    func unsubscribe(_ subscriber: AnyObject) {
        let id = self.getSubscriberId(subscriber)
        queue.addOperation {
            for action1: Action in self.subscriberMap[id] ?? [] {
                if (self.actionMap[action1.eventName] == nil) {
                    continue
                }
                let count = self.actionMap[action1.eventName]!.count
                for i in 0..<count {
                    let action2 = self.actionMap[action1.eventName]![i]
                    if (action1 === action2) {
                        self.actionMap[action1.eventName]!.remove(at: i)
                        break
                    }
                }
                if (self.actionMap[action1.eventName]!.count < 1) {
                    self.actionMap.removeValue(forKey: action1.eventName)
                }
            }
            self.subscriberMap.removeValue(forKey: id)
        }
    }

    /// 取消订阅当前对象的所有事件，该方法会释放当前对象在所有EventBus实例中所订阅的事件
    static func unsubscribe(_ subscriber: AnyObject) {
        for eventBus in EventBus.instanceList {
            if (eventBus.hasValue()) {
                eventBus.value.unsubscribe(subscriber)
            }
        }
    }

    /// 发布事件，已经订阅过该事件的订阅者会收到事件通知
    func post<T>(event: T) {
        let name = self.getEventName(T.self)
        queue.addOperation {
            if let actionList: [Action] = self.actionMap[name] {
                for action: Action in actionList {
                    self.dispatchEvent(event: event, action: action.action as! (T) -> Void)
                }
            }
        }
    }

    /// 发布事件，已经订阅过该事件的订阅者会收到事件通知，没有订阅该事件的订阅者在订阅该事件之后会收到最后一条事件通知
    func postSticky<T>(event: T) {
        let name = self.getEventName(T.self)
        queue.addOperation {
            self.stickyEventMap[name] = event
            self.post(event: event)
        }
    }

    /// 移除必达消息
    func removeStickyEvent<T>(event: T) {
        let name = self.getEventName(T.self)
        queue.addOperation {
            self.stickyEventMap.removeValue(forKey: name)
        }
    }

    private func getStickyEvent<T>() -> T? {
        let name = getEventName(T.self)
        if stickyEventMap[name] == nil {
            return nil
        }
        return stickyEventMap[name] as? T
    }

    private func dispatchEvent<T>(event: T, action: @escaping(_ event: T) -> Void) {
        OperationQueue.main.addOperation {
            action(event)
        }
    }

    private func getEventName(_ event: Any) -> String {
        return String(describing: event)
    }

    private func getSubscriberId(_ subscriber: AnyObject) -> Int {
        let id = Unmanaged.passUnretained(subscriber).toOpaque().hashValue
        return id
    }
}

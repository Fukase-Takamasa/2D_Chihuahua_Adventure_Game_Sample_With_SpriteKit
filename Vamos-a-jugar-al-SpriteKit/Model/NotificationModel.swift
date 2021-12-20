//
//  NotificationModel.swift
//  AquaVSTaimei
//
//  Created by 深瀬 貴将 on 2021/02/06.
//

import Foundation

extension Notification.Name {
    static let arsagaMapNotifyFromScene = Notification.Name("arsagaMapNotifyFromScene")
    static let arsagaMapNotifyFromVC = Notification.Name("arsagaMapNotifyFromVC")
    
    static let sideMenuNotify = Notification.Name("sideMenuNotify")
}

enum ArsagaMapNotifyFromSceneType {
    case introduction
    case firstEvent
}
enum ArsagaMapNotifyFromVCType {
    case didEndFirstEvent
}

enum NotifyType {
    case changeEvent
}

class NotificationModel {
    static func changeEvent(to event: ArsagaMapNotifyFromSceneType) {
        NotificationCenter.default.post(name: .sideMenuNotify, object: nil, userInfo: ["type": NotifyType.changeEvent, "event": event])
    }
}

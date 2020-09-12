//
//  NotificationsManager.swift
//  RXd
//
//  Created by Andrew Finke on 8/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa
import UserNotifications
import os.log

class NotificationsManager: NSObject, UNUserNotificationCenterDelegate {
    
    // MARK: - Properties -
    
    private let center = UNUserNotificationCenter.current()
    private let log = OSLog(subsystem: "com.andrewfinke.RX", category: "RXd notifications")
    private var isSetup = false
    
    // MARK: - Initialization -
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - Helpers -
    
    func auth() {
        os_log("Auth triggered", log: log, type: .info)
        center.requestAuthorization(options: [.alert]) { _, _ in
            self.isSetup = true
        }
//        center.removeAllDeliveredNotifications()
    }
    
    func show(title: String, text: String?) {
        os_log("Showing: %{public}s - %{public}s", log: log, type: .info, title, "N/A")
        let content = UNMutableNotificationContent()
        content.title = title
        if let body = text {
            content.body = body
        }
        
        func deliverIfSetup() {
            if isSetup {
                let dateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                center.add(request)
            } else {
                DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                    deliverIfSetup()
                }
            }
        }
        deliverIfSetup()
    }
    
    // MARK: - UNUserNotificationCenterDelegate -
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        defer {
            completionHandler()
        }
        
        os_log("Clicked notification", log: log, type: .info)
        
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier &&
                response.notification.request.content.title.contains("Not Configured") else {
            return
        }
        
        os_log("Opening RX Prefs app", log: log, type: .info)
        NSWorkspace.shared.launchApplication("RX Preferences")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }
}

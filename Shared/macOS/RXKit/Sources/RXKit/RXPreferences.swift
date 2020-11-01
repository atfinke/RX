//
//  RXPreferences.swift
//  RXKit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Combine
import Foundation
import os.log

/// Main object for storing preferences
public final class RXPreferences: ObservableObject, Codable {

    // MARK: - Types -

    private enum CodingKeys: CodingKey {
        case hardware, customApps, defaultApps
    }
    
    /// When this (is delete enabled) property is part of RXPreferences, due to @Published, the whole app table/list  is refreshed when the value is changed.
    /// This is not desired because refreshing removes the user's selection on refresh.
    /// To workaround this, I have the InterfaceHack seperate class wtih the property, that only the delete button observes.
    public class InterfaceHack: ObservableObject {
        @Published public var isDeleteEnabled = false
    }

    // MARK: - Properties -
    
    /// Hardware to connect to
    public let hardware: RXHardware
    
    /// All the user's set apps
    @Published public var customApps: [RXApp]
    
    /// The default/required apps set by me. For now, this is just the literal 'Default" app, which is what is active when something other than a custom app is frontmost.
    /// Note: default in this case has no relation to user defaults.
    @Published public var defaultApps: [RXApp]

    /// Combine observers to retain
    private var cancellables = Set<AnyCancellable>()

    private static let versionKey = "RXPreferencesVersionKey"
    private static let heartbeatKey = "RXdHeartbeatKey"
    
    private static let defaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: RXDeveloperConfig.appGroup) else {
            fatalError("Check app group in RXDeveloperConfig")
        }
        return defaults
    }()
    
    public var interfaceHack = InterfaceHack()

    private let log = OSLog(subsystem: "com.andrewfinke.RX", category: "RX Prefs Object")

    // MARK: - Initalization -

    init(hardware: RXHardware) {
        self.hardware = hardware
        customApps = []
        defaultApps = [RXApp.defaultApp(rxButtons: hardware.edition.buttons)]
    }

    static public func loadFromDisk(writingEnabled: Bool) throws -> RXPreferences {
        let hardware = try RXHardware.loadFromDisk()

        let loadedFromDisk: Bool
        let preferences: RXPreferences
        if let data = try? Data(contentsOf: RXURL.appData()), let object = try? JSONDecoder().decode(RXPreferences.self, from: data) {
            preferences = object
            loadedFromDisk = true
            os_log("Found existing prefs on disk", log: preferences.log, type: .info)
        } else {
            preferences = RXPreferences(hardware: hardware)
            loadedFromDisk = false
            os_log("Creating new prefs", log: preferences.log, type: .info)
        }

        // Only the RX Preferences app needs to make changes
        if writingEnabled {
            preferences.enableWritingToDisk()
            if !loadedFromDisk {
                RXNotifier.local.updated()
            }
        } else {
            // RXd should periodically tell the preferences app it is running.
            // This defaults approach is due to inconsistent results from runningApplicationsWithBundleIdentifier (which would be the preferred way to do this) when RXd is launched as a login item.
            func heartbeat() {  RXPreferences.defaults.set(Date(), forKey: RXPreferences.heartbeatKey) }
            heartbeat()
            Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                heartbeat()
            }
        }
        return preferences
    }

    // MARK: - Codable -

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hardware = try container.decode(RXHardware.self, forKey: .hardware)
        customApps = try container.decode([RXApp].self, forKey: .customApps)
        defaultApps = try container.decode([RXApp].self, forKey: .defaultApps)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hardware, forKey: .hardware)
        try container.encode(customApps, forKey: .customApps)
        try container.encode(defaultApps, forKey: .defaultApps)
    }

    // MARK: - Saving Changes -

    func enableWritingToDisk() {
        RXNotifier.local.onUpdate
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main) // debounce to reduce writes to disk when changing colors
            .sink(receiveValue: { _ in
                guard let data = try? JSONEncoder().encode(self) else { fatalError() }
                try? data.write(to: RXURL.appData())
                os_log("triggerRXdUpdate called", log: self.log, type: .info)
                RXPreferences.triggerRXdUpdate()
            }).store(in: &cancellables)

        RXNotifier.local.onRemove
            .sink(receiveValue: { app in
                self.customApps = self.customApps.filter { $0.bundleID != app.bundleID }
                self.interfaceHack.isDeleteEnabled = false
            }).store(in: &cancellables)
        
        RXNotifier.local.onSelect
            .sink(receiveValue: { app in
                // Show delete button for custom/user added apps
                self.interfaceHack.isDeleteEnabled = self.customApps.map({ $0.bundleID }).contains(app.bundleID)
            }).store(in: &cancellables)
    }

    public static func triggerRXdUpdate() {
        let version = RXPreferences.defaults.integer(forKey: RXPreferences.versionKey)
        RXPreferences.defaults.set(version + 1, forKey: RXPreferences.versionKey)
    }
    
    /// Check if RXd is still posting heartbeats
    public static func isRXdAlive() -> Bool {
        if let date = RXPreferences.defaults.object(forKey: RXPreferences.heartbeatKey) as? Date, -date.timeIntervalSinceNow < 32 {
            return true
        } else {
            return false
        }
    }

    // MARK: - App Group Notifications -

    /// Observing changes to the version key (an int that RX Prefs app increments on every change)
    private static var observer: VersionObserver?
    private class VersionObserver: NSObject {
        let callback: (Int) -> Void
        init(callback: @escaping (Int) -> Void) {
            self.callback = callback
        }
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            guard keyPath == RXPreferences.versionKey, let newVersion = change?[NSKeyValueChangeKey.newKey] as? Int else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                return
            }
            callback(newVersion)
        }
    }

    public static func registerForUpdates(onUpdate: @escaping  () -> Void) {
        var version = defaults.integer(forKey: RXPreferences.versionKey)
        let observer = VersionObserver { newVersion in
            if version != newVersion {
                version = newVersion
                onUpdate()
            }
        }
        defaults.addObserver(observer,
                             forKeyPath: RXPreferences.versionKey,
                             options: .new,
                             context: nil)
        RXPreferences.observer = observer
    }

}

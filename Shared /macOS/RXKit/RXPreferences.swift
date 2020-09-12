//
//  RXPreferences.swift
//  RXKit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa
import Combine
import os.log

/// Main object for storing preferences
public final class RXPreferences: ObservableObject, Codable {

    // MARK: - Types -

    private enum CodingKeys: CodingKey {
        case hardware, customApps, defaultApps
    }
    
    enum RXPreferencesError: Error {
        case initalSetupNeeded
    }

    // MARK: - Properties -

    public let hardware: RXHardware
    @Published public var customApps: [RXApp]
    @Published public var defaultApps: [RXApp]

    private var onUpdateCancellable: AnyCancellable?
    
    private static let versionKey = "RXPreferencesVersionKey"
    private static let defaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: RXDeveloperConfig.appGroup) else {
            fatalError("Check app group in RXDeveloperConfig")
        }
        return defaults
    }()
    
    private let log = OSLog(subsystem: "com.andrewfinke.RX", category: "RX Prefs Object")
    
    // MARK: - Initalization -
    
    init(hardware: RXHardware) {
        self.hardware = hardware
        customApps = []
        defaultApps = [RXApp.defaultApp(rxButtons: hardware.edition.buttons)]
    }
    
    static public func loadFromDisk(writingEnabled: Bool) throws -> RXPreferences {
        let hardware = try RXHardware.loadFromDisk()
   
        let preferences: RXPreferences
        if let data = try? Data(contentsOf: RXURL.appData()), let object = try? JSONDecoder().decode(RXPreferences.self, from: data) {
            preferences = object
            os_log("Found existing prefs on disk", log: preferences.log, type: .info)
        } else {
            preferences = RXPreferences(hardware: hardware)
            os_log("Creating new prefs", log: preferences.log, type: .info)
        }
        
        if writingEnabled {
            preferences.enableWritingToDisk()
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
        if onUpdateCancellable != nil {
            fatalError()
        }
        
        onUpdateCancellable = RXNotifier.local.onUpdate
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .sink(receiveValue: { _ in
                guard let data = try? JSONEncoder().encode(self) else { fatalError() }
                try? data.write(to: RXURL.appData())
                os_log("triggerRXdUpdate called", log: self.log, type: .info)
                RXPreferences.triggerRXdUpdate()
        })

        RXNotifier.local.onRemove = { app in
            self.customApps = self.customApps.filter { $0.bundleID != app.bundleID }
        }
    }
    
    public static func triggerRXdUpdate() {
        let version = RXPreferences.defaults.integer(forKey: RXPreferences.versionKey)
        RXPreferences.defaults.set(version + 1, forKey: RXPreferences.versionKey)
    }

    // MARK: - App Group Notifications -
    
    private static var observer: VersionObserver?
    private class VersionObserver: NSObject {
        let callback: (Int) -> Void
        init(callback: @escaping (Int) -> Void) {
            self.callback = callback
        }
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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

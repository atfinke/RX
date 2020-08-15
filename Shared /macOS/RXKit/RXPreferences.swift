//
//  RXPreferences.swift
//  RXKit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa
import Combine

/// Main object for storing preferences
public final class RXPreferences: ObservableObject, Codable {

    // MARK: - Types -

    private enum CodingKeys: CodingKey {
        case customApps, defaultApps
    }

    // MARK: - Properties -

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
    
    // MARK: - Initalization -

    public init(writingEnabled: Bool = true, rxButtons: Int) {
        if let data = try? Data(contentsOf: RXURL.appData()), let object = try? JSONDecoder().decode(RXPreferences.self, from: data) {
            customApps = object.customApps
            defaultApps = object.defaultApps
        } else {
            customApps = []
            defaultApps = [RXApp.defaultApp(rxButtons: rxButtons)]
        }

        guard writingEnabled else { return }
        onUpdateCancellable = RXNotifier.local.onUpdate
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink(receiveValue: { _ in
            print("Notifier.shared.onUpdate")
                self.save()
        })

        RXNotifier.local.onRemove = { app in
            self.customApps = self.customApps.filter { $0.name != app }
        }
    }

    // MARK: - Codable -
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        customApps = try container.decode([RXApp].self, forKey: .customApps)
        defaultApps = try container.decode([RXApp].self, forKey: .defaultApps)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(customApps, forKey: .customApps)
        try container.encode(defaultApps, forKey: .defaultApps)
    }

    // MARK: - Notifications -
    
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
    
    
    // MARK: - Other -
    
    private func save() {
        guard let data = try? JSONEncoder().encode(self) else { fatalError() }
        try? data.write(to: RXURL.appData())
        let version = RXPreferences.defaults.integer(forKey: RXPreferences.versionKey)
        RXPreferences.defaults.set(version + 1, forKey: RXPreferences.versionKey)
    }
    
}

//
//  R1Preferences.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa
import Combine

public final class R1Preferences: ObservableObject, Codable {
    
    // MARK: - Types -

    private enum CodingKeys: CodingKey {
        case customApps, defaultApps
    }

    // MARK: - Properties -
    
    @Published public var customApps: [R1App]
    @Published public var defaultApps: [R1App]
    
    private var onUpdateCancellable: AnyCancellable?
    
    // MARK: - Initalization -
    
    public init(writingEnabled: Bool = true, rxButtons: Int) {
        if let data = try? Data(contentsOf: R1URL.appData()), let object = try? JSONDecoder().decode(R1Preferences.self, from: data) {
            customApps = object.customApps
            defaultApps = object.defaultApps
        } else {
            customApps = []
            defaultApps = [R1App.defaultApp(rxButtons: rxButtons)]
        }
            
        guard writingEnabled else { return }
        onUpdateCancellable = R1Notifier.local.onUpdate
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink(receiveValue: { _ in
            print("Notifier.shared.onUpdate")
                self.save()
        })
            
        R1Notifier.local.onRemove = { app in
            self.customApps = self.customApps.filter { $0.name != app }
        }
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        customApps = try container.decode([R1App].self, forKey: .customApps)
        defaultApps = try container.decode([R1App].self, forKey: .defaultApps)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(customApps, forKey: .customApps)
        try container.encode(defaultApps, forKey: .defaultApps)
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(self) else { fatalError() }
        try? data.write(to: R1URL.appData())
    }
}

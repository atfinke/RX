//
//  R1Config.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Combine
import Foundation

public final class R1Settings: ObservableObject, Codable {

    // MARK: - Types -

    private enum CodingKeys: CodingKey {
        case customAppConfigs, defaultAppConfigs
    }

    // MARK: - Properties -

    @Published public var customAppConfigs: [R1AppConfig]
    @Published public var defaultAppConfigs: [R1AppConfig]

    private var onUpdateCancellable: AnyCancellable?

    // MARK: - Initalization -

    public init() {
        customAppConfigs = [_messages]
        defaultAppConfigs = []

        onUpdateCancellable = R1Notifier.local.onUpdate
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink(receiveValue: { _ in
            print("Notifier.shared.onUpdate")
        })

        R1Notifier.local.onRemove = { app in
            self.customAppConfigs = self.customAppConfigs.filter { $0.name != app }
        }
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        customAppConfigs = try container.decode([R1AppConfig].self, forKey: .customAppConfigs)
        defaultAppConfigs = try container.decode([R1AppConfig].self, forKey: .defaultAppConfigs)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(customAppConfigs, forKey: .customAppConfigs)
        try container.encode(defaultAppConfigs, forKey: .defaultAppConfigs)
    }
}

private let _messages = R1AppConfig(
    name: "Messages",
    open: .init(
        firstColor: R1Color(.green),
        secondColor: R1Color(.green),
        thirdColor: R1Color(.green),
        fourthColor: R1Color(.green)
    ),
    resting: .init(
        firstColor: R1Color(.green),
        secondColor: R1Color(.green),
        thirdColor: R1Color(.green),
        fourthColor: R1Color(.green)
    ),
    pressed: .init(
        firstColor: R1Color(.red),
        secondColor: R1Color(.red),
        thirdColor: R1Color(.red),
        fourthColor: R1Color(.red)
    ),
    firstScript: .init(name: "New Message", path: URL(string: "http://www.apple.com")!),
    secondScript: nil,
    thirdScript: nil,
    fourthScript: nil
)

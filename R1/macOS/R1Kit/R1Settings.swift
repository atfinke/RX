//
//  R1Config.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa
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
    
    public init(writingEnabled: Bool = true) {
        if let data = try? Data(contentsOf: R1URL.configData()), let object = try? JSONDecoder().decode(R1Settings.self, from: data) {
            customAppConfigs = object.customAppConfigs
            defaultAppConfigs = object.defaultAppConfigs
        } else {
            customAppConfigs = []
            defaultAppConfigs = [_default]
        }
        
//        customAppConfigs = []
//        defaultAppConfigs = [_default]
        
//        customAppConfigs = [_messages, _xcode]
//        customAppConfigs = []
//        defaultAppConfigs = []
            
        guard writingEnabled else { return }
        onUpdateCancellable = R1Notifier.local.onUpdate
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink(receiveValue: { _ in
            print("Notifier.shared.onUpdate")
                self.save()
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
    
    private func save() {
        guard let data = try? JSONEncoder().encode(self) else { fatalError() }
        try? data.write(to: R1URL.configData())
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
        firstColor: R1Color(.green),
        secondColor: R1Color(.green),
        thirdColor: R1Color(.green),
        fourthColor: R1Color(.green)
    ),
    firstScript: nil,
    secondScript: nil,
    thirdScript: nil,
    fourthScript: nil
)

private let _xcode = R1AppConfig(
    name: "Xcode",
    open: .init(
        firstColor: R1Color(.blue),
        secondColor: R1Color(.blue),
        thirdColor: R1Color(.blue),
        fourthColor: R1Color(.blue)
    ),
    resting: .init(
        firstColor: R1Color(.blue),
        secondColor: R1Color(.blue),
        thirdColor: R1Color(.blue),
        fourthColor: R1Color(.blue)
    ),
    pressed: .init(
        firstColor: R1Color(.blue),
        secondColor: R1Color(.red),
        thirdColor: R1Color(.red),
        fourthColor: R1Color(.red)
    ),
    firstScript: nil,
    secondScript: nil,
    thirdScript: nil,
    fourthScript: nil
)

private let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1)

private let _default = R1AppConfig(
    name: "Default",
    open: .init(
        firstColor: R1Color(.purple),
        secondColor: R1Color(.red),
        thirdColor: R1Color(.green),
        fourthColor: R1Color(.blue)
    ),
    resting: .init(
        firstColor: R1Color(white),
        secondColor: R1Color(white),
        thirdColor: R1Color(white),
        fourthColor: R1Color(white)
    ),
    pressed: .init(
        firstColor: R1Color(white),
        secondColor: R1Color(white),
        thirdColor: R1Color(white),
        fourthColor: R1Color(white)
    ),
    firstScript: nil,
    secondScript: nil,
    thirdScript: nil,
    fourthScript: nil
)

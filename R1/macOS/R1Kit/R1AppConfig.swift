//
//  R1AppConfig.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public class R1AppConfig: ObservableObject, Codable, Equatable, Hashable, Identifiable {
    
    // MARK: - Types -
    
    private enum CodingKeys: CodingKey {
        case name
        case open, resting, pressed
        case firstScript, secondScript, thirdScript, fourthScript
    }
    
    // MARK: - Properties -
    
    public let name: String
    
    // MARK: - Colors -
    
    @Published public var open: R1ColorCollection { didSet { didUpdate(colors: open) } }
    @Published public var resting: R1ColorCollection { didSet { didUpdate(colors: resting) } }
    @Published public var pressed: R1ColorCollection { didSet { didUpdate(colors: pressed) } }
    
    // MARK: - R1Script -
    
    @Published public var firstScript: R1Script? { didSet { didUpdate() } }
    @Published public var secondScript: R1Script? { didSet { didUpdate() } }
    @Published public var thirdScript: R1Script? { didSet { didUpdate() } }
    @Published public var fourthScript: R1Script? { didSet { didUpdate() } }
    
    // MARK: - Other -
    
    public static var `default`: R1AppConfig {
        return R1AppConfig(
            name: "Default",
            open: .init(
                firstColor: R1Color(.red),
                secondColor: R1Color(.green),
                thirdColor: R1Color(.blue),
                fourthColor: R1Color(.green)
            ),
            resting: .init(
                firstColor: R1Color(.yellow),
                secondColor: R1Color(.orange),
                thirdColor: R1Color(.green),
                fourthColor: R1Color(.purple)
            ),
            pressed: .init(
                firstColor: R1Color(.blue),
                secondColor: R1Color(.yellow),
                thirdColor: R1Color(.red),
                fourthColor: R1Color(.red)
            ))
    }
    
    // MARK: - Initalization -
    
    public init(
        name: String,
        open: R1ColorCollection = .init(color: .blue),
        resting: R1ColorCollection = .init(color: .blue),
        pressed: R1ColorCollection = .init(color: .blue),
        firstScript: R1Script? = nil,
        secondScript: R1Script? = nil,
        thirdScript: R1Script? = nil,
        fourthScript: R1Script? = nil) {
        self.name = name
        self.open = open
        self.resting = resting
        self.pressed = pressed
        self.firstScript = firstScript
        self.secondScript = secondScript
        self.thirdScript = thirdScript
        self.fourthScript = fourthScript
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        
        open = try container.decode(R1ColorCollection.self, forKey: .open)
        resting = try container.decode(R1ColorCollection.self, forKey: .resting)
        pressed = try container.decode(R1ColorCollection.self, forKey: .pressed)
        
        firstScript = try? container.decode(R1Script.self, forKey: .firstScript)
        secondScript = try? container.decode(R1Script.self, forKey: .secondScript)
        thirdScript = try? container.decode(R1Script.self, forKey: .thirdScript)
        fourthScript = try? container.decode(R1Script.self, forKey: .fourthScript)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        
        try container.encode(open, forKey: .open)
        try container.encode(resting, forKey: .resting)
        try container.encode(pressed, forKey: .pressed)
        
        try? container.encode(firstScript, forKey: .firstScript)
        try? container.encode(secondScript, forKey: .secondScript)
        try? container.encode(thirdScript, forKey: .thirdScript)
        try? container.encode(fourthScript, forKey: .fourthScript)
    }
    
    // MARK: - Equatable -
    
    public static func == (lhs: R1AppConfig, rhs: R1AppConfig) -> Bool {
        return lhs.name == rhs.name &&
            lhs.name == rhs.name &&
            lhs.open == rhs.open &&
            lhs.resting == rhs.resting &&
            lhs.pressed == rhs.pressed &&
            lhs.firstScript == rhs.firstScript &&
            lhs.secondScript == rhs.secondScript &&
            lhs.thirdScript == rhs.thirdScript &&
            lhs.fourthScript == rhs.fourthScript
    }
    
    // MARK: - Hashable -
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(open)
        hasher.combine(resting)
        hasher.combine(pressed)
        hasher.combine(firstScript)
        hasher.combine(secondScript)
        hasher.combine(thirdScript)
        hasher.combine(fourthScript)
    }
    
    // MARK: - Helpers -
    
    func didUpdate() {
        R1Notifier.local.updated()
    }
    
    func didUpdate(colors: R1ColorCollection) {
        didUpdate()
    }
}

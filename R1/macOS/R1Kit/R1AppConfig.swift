//
//  R1AppConfig.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public struct R1AppButtonColors: Codable, Equatable, Hashable {
    public var open: R1Color
    public var resting: R1Color
    public var pressed: R1Color
}




public struct R1AppButton: Codable, Equatable, Hashable, Identifiable {
   
    // MARK: - Properties -
    
    public var id: Int
    public var colors: R1AppButtonColors
    public var action: R1Script?
    
    // MARK: - Initalization -
    
    public init(number: Int) {
        id = number
        colors = R1AppButtonColors(open: R1Color(.blue), resting: R1Color(.blue), pressed: R1Color(.blue))
        action = nil
    }

}



public class R1AppConfig: ObservableObject, Codable, Equatable, Hashable, Identifiable {
    
    // MARK: - Types -
    
    private enum CodingKeys: CodingKey {
        case name, buttons
    }
    
    // MARK: - Properties -
    
    public let name: String
    
    // MARK: - Colors -
    
    @Published public var buttons: [R1AppButton] { didSet { didUpdate() } }
    
    // MARK: - Initalization -
    
    public init(name: String, buttonCount: Int) {
        self.name = name
        self.buttons = []
        (0..<buttonCount).forEach { index in
            let button = R1AppButton(number: index + 1)
            buttons.append(button)
        }
    }
    
    // MARK: - Helpers -
    
    static func defaultConfig(rxButtons: Int) -> R1AppConfig {
        return R1AppConfig(name: "Default", buttonCount: rxButtons)
    }
    
    // MARK: - Codable -
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        buttons = try container.decode([R1AppButton].self, forKey: .buttons)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(buttons, forKey: .buttons)
    }
    
    // MARK: - Equatable -
    
    public static func == (lhs: R1AppConfig, rhs: R1AppConfig) -> Bool {
        return lhs.name == rhs.name && lhs.buttons == rhs.buttons
    }
    
    // MARK: - Hashable -
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(buttons)
    }
    
    // MARK: - Helpers -
    
    func didUpdate() {
        print(#function)
        R1Notifier.local.updated()
    }

}

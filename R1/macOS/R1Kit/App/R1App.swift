//
//  R1App.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public class R1App: ObservableObject, Codable, Equatable, Hashable, Identifiable {
    
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
    
    static func defaultApp(rxButtons: Int) -> R1App {
        return R1App(name: "Default", buttonCount: rxButtons)
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
    
    public static func == (lhs: R1App, rhs: R1App) -> Bool {
        return lhs.name == rhs.name && lhs.buttons == rhs.buttons
    }
    
    // MARK: - Hashable -
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(buttons)
    }
    
    // MARK: - Helpers -
    
    func didUpdate() {
        R1Notifier.local.updated()
    }

}

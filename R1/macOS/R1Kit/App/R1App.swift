//
//  R1App.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa

public class R1App: ObservableObject, Codable, Equatable, Hashable, Identifiable {

    // MARK: - Types -

    private enum CodingKeys: CodingKey {
        case name, bundleID, buttons
    }

    // MARK: - Properties -

    public let name: String
    public let bundleID: String
    @Published public var buttons: [R1AppButton] { didSet { didUpdate() } }

    // MARK: - Initalization -

    public init(name: String, bundleID: String, buttonCount: Int) {
        self.name = name
        self.bundleID = bundleID
        self.buttons = []

        // Grab the prominent colors from the app icon to set as the default button colors
        let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first
        let colors = IconProcessing.run(for: app, colorCount: 1)
        (0..<buttonCount).forEach { index in
            let button = R1AppButton(number: index + 1, restingColor: colors.first ?? R1Color(.white))
            buttons.append(button)
        }
    }

    // MARK: - Helpers -

    static func defaultApp(rxButtons: Int) -> R1App {
        return R1App(name: "Default", bundleID: "", buttonCount: rxButtons)
    }

    // MARK: - Codable -

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        bundleID = try container.decode(String.self, forKey: .bundleID)
        buttons = try container.decode([R1AppButton].self, forKey: .buttons)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(bundleID, forKey: .bundleID)
        try container.encode(buttons, forKey: .buttons)
    }

    // MARK: - Equatable -

    public static func == (lhs: R1App, rhs: R1App) -> Bool {
        return lhs.name == rhs.name && lhs.bundleID == rhs.bundleID && lhs.buttons == rhs.buttons
    }

    // MARK: - Hashable -

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(bundleID)
        hasher.combine(buttons)
    }

    // MARK: - Helpers -

    func didUpdate() {
        R1Notifier.local.updated()
    }

}

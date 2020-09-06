//
//  RXAppButton.swift
//  RXKit
//
//  Created by Andrew Finke on 6/29/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public struct RXAppButton: Codable, Equatable {

    // MARK: - Properties -

    public var colors: RXAppButtonStateColors
    public var action: RXScript? {
        didSet {
            guard let url = oldValue?.fileURL else { return }
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Initalization -

    public init(restingColor: RXColor) {
        colors = RXAppButtonStateColors(resting: restingColor, pressed: RXColor(.white))
        action = nil
    }

}

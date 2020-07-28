//
//  R1AppButton.swift
//  R1Kit
//
//  Created by Andrew Finke on 6/29/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public struct R1AppButton: Codable, Equatable, Hashable, Identifiable {

    // MARK: - Properties -

    public var id: Int
    public var colors: R1AppButtonStateColors
    public var action: R1Script? {
        didSet {
            guard let url = oldValue?.fileURL else { return }
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Initalization -

    public init(number: Int, restingColor: R1Color) {
        id = number
        colors = R1AppButtonStateColors(resting: restingColor, pressed: R1Color(.white))
        action = nil
    }

}

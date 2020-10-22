//
//  ColorCollectionHeaderView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

struct ColorCollectionHeaderView: View {

     // MARK: - Properties -

    let text: String

     // MARK: - Body -

    var body: some View {
        LeftText(
            text: text,
            font: Font.system(size: 15, weight: .medium, design: .rounded)
        )
    }
}

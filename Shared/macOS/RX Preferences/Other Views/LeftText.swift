//
//  LeftText.swift
//  RX Preferences
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

struct LeftText: View {

     // MARK: - Properties -

    let text: String
    let font: Font

     // MARK: - Body -

    var body: some View {
        HStack {
            Text(text).font(font)
            Spacer()
        }
    }
}

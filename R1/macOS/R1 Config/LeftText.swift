//
//  LeftText.swift
//  R1 Config
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

struct LeftText: View {
    
    let text: String
    let font: Font
    
    var body: some View {
        HStack {
            Text(text).font(font)
            Spacer()
        }
    }
}

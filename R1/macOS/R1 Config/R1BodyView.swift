//
//  R1BodyView.swift
//  R1 Config
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import R1Kit

struct R1BodyView: View {
    
    @Binding var colors: R1ColorCollection
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.windowBackgroundColor))
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary, lineWidth: 3)
            HStack {
                R1ButtonView(color: $colors.firstColor)
                Spacer()
                R1ButtonView(color: $colors.secondColor)
                Spacer()
                R1ButtonView(color: $colors.thirdColor)
                Spacer()
                R1ButtonView(color: $colors.fourthColor)
            }.padding(12)
        }.frame(height: 20).onDrag { () -> NSItemProvider in
            return NSItemProvider(object: R1ColorCollectionProvider(self.colors))
        }.onDrop(of:  [kUTTypeData as String], isTargeted: nil) { providers -> Bool in
            guard let item = providers.first(where: { $0.hasItemConformingToTypeIdentifier(kUTTypeData as String)}) else {
                return false
            }
            _ = item.loadObject(ofClass: R1ColorCollectionProvider.self) { object, _ in
                guard let config = (object as? R1ColorCollectionProvider)?.config else { return }
                DispatchQueue.main.async {
                    self.colors = config
                }
            }
            return true
        }
    }
}


//
//  SNContentView.swift
//  RX Preferences
//
//  Created by Andrew Finke on 9/1/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//
//

import SwiftUI
import Combine
import RXKit

struct SetupView: View {

    // MARK: - Types

    // MARK: - Properties -

    @ObservedObject private var nearbyManager = RXNearbyManager()

    let onFinish: (RXHardware) -> Void
    internal init(onFinish: @escaping (RXHardware) -> Void) {
        self.onFinish = onFinish
    }

    // MARK: - Body -

    var body: some View {
        let isDisplayingHardware = nearbyManager.shouldDisplayHardware
        return VStack {
            Text(isDisplayingHardware ? "Found Nearby \(nearbyManager.queuedNearbyHardware[0].edition.rawValue)" : "Searching For Devices")
                .font(.headline)
                .padding(.top, 20)

            ZStack {
                if isDisplayingHardware {
                    Text("\(nearbyManager.queuedNearbyHardware[0].edition.rawValue) with serial number \(nearbyManager.queuedNearbyHardware[0].serialNumber) is nearby. Is this your device?")
                        .multilineTextAlignment(.center)
                } else {
                    ActivityIndicator().scaleEffect(0.75)
                }

            }
            .padding(.horizontal, 16)
            .frame(height: 60)

            HStack {
                Button("    No    ", action: {
                    self.nearbyManager.firstQueuedHardwareNotOwners()
                })
                .padding()
                Button("   Yes!   ", action: {
                    onFinish(nearbyManager.queuedNearbyHardware[0])
                })
                .padding()

            }.opacity(isDisplayingHardware ? 1 : 0)

        }.frame(width: 240, height: 180)
    }

}

struct SNContentViewPreviews: PreviewProvider {
    static var previews: some View {
        SetupView(onFinish: { _ in })
    }
}

//
//  RXNotifier.swift
//  RXKit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Combine

public class RXNotifier {

    internal let onUpdate = PassthroughSubject<Bool, Never>()
    internal let onRemove = PassthroughSubject<RXApp, Never>()
    internal let onSelect = PassthroughSubject<RXApp, Never>()
    
    internal var selectedApp: RXApp?

    public static let local = RXNotifier()

    public func selected(app: RXApp) {
        selectedApp = app
        onSelect.send(app)
    }

    public func pressedRemove() {
        guard let app = selectedApp else {
            return
        }
        onRemove.send(app)
        updated()
    }

    func updated() {
        onUpdate.send(true)
    }
}

//
//  RXNotifier.swift
//  RXKit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Combine

public class RXNotifier {
    
    internal var onRemove: ((RXApp) -> Void)?
    internal let onUpdate = PassthroughSubject<Bool, Never>()
    internal var selectedApp: RXApp?
    
    public static let local = RXNotifier()
    
    public func selected(app: RXApp) {
        selectedApp = app
    }
    
    public func pressedRemove() {
        guard let app = selectedApp else {
            return
        }
        onRemove?(app)
        onUpdate.send(true)
    }
    
    func updated() {
        onUpdate.send(true)
    }
}

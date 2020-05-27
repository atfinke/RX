//
//  R1Notifier.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Combine

public class R1Notifier {
    
    var selected = ""
    
    var onRemove: ((String) -> Void)?
    let onUpdate = PassthroughSubject<Bool, Never>()
    
    public static let local = R1Notifier()
    
    public func selected(app: String) {
        selected = app
    }
    
    public func pressedRemove() {
        onRemove?(selected)
    }
    
    func updated() {
        onUpdate.send(true)
    }
}

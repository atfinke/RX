//
//  R1ColorProvider.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/29/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public final class R1ColorProvider: NSObject, Codable, NSItemProviderWriting, NSItemProviderReading {
    
    static public let identifier = kUTTypeItem as String
    
    public let color: R1Color
    public init(_ color: R1Color) {
        self.color = color
    }
    
    public static var writableTypeIdentifiersForItemProvider: [String] = [R1ColorProvider.identifier]
    public static var readableTypeIdentifiersForItemProvider: [String] = [R1ColorProvider.identifier]
    
    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        do {
            let data = try JSONEncoder().encode(self)
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        let progress = Progress(totalUnitCount: 1)
        progress.completedUnitCount = 1
        return progress
    }
    
    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> R1ColorProvider {
        do {
            return try JSONDecoder().decode(R1ColorProvider.self, from: data)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
}

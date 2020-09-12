//
//  RXColorProvider.swift
//  RXKit
//
//  Created by Andrew Finke on 5/29/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

/// Used for drag and drop single button color in preferences app
public final class RXColorProvider: NSObject, Codable, NSItemProviderWriting, NSItemProviderReading {

    // MARK: - Properties -
    
    static public let identifier = kUTTypeItem as String
    public static var writableTypeIdentifiersForItemProvider: [String] = [RXColorProvider.identifier]
    public static var readableTypeIdentifiersForItemProvider: [String] = [RXColorProvider.identifier]

    public let color: RXColor
    
    // MARK: - Initalization -
    
    public init(_ color: RXColor) {
        self.color = color
    }

    // MARK: - NSItemProviderWriting -
    
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
    
    // MARK: - NSItemProviderReading -

    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> RXColorProvider {
        do {
            return try JSONDecoder().decode(RXColorProvider.self, from: data)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

}

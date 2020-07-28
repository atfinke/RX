//
//  R1ColorsProvider.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

/// Used for drag and drop in preferences app
public final class R1ColorsProvider: NSObject, Codable, NSItemProviderWriting, NSItemProviderReading {

    // MARK: - Properties -
    static public let identifier = kUTTypeDirectory as String
    public static var writableTypeIdentifiersForItemProvider: [String] = [R1ColorsProvider.identifier]
    public static var readableTypeIdentifiersForItemProvider: [String] = [R1ColorsProvider.identifier]

    public let colors: [R1Color]
    
    // MARK: - Initalization -
    
    public init(_ colors: [R1Color]) {
        self.colors = colors
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
    
    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> R1ColorsProvider {
        do {
            return try JSONDecoder().decode(R1ColorsProvider.self, from: data)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

}

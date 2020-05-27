//
//  R1ColorCollectionProvider.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public final class R1ColorCollectionProvider: NSObject, NSItemProviderWriting, NSItemProviderReading {
    
    public let config: R1ColorCollection
    public init(_ config: R1ColorCollection) {
        self.config = config
    }
    
    public static var writableTypeIdentifiersForItemProvider: [String] = [kUTTypeData as String]
    public static var readableTypeIdentifiersForItemProvider: [String] = [kUTTypeData as String]
    
    
    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        do {
            let data = try JSONEncoder().encode(config)
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        let progress = Progress(totalUnitCount: 1)
        progress.completedUnitCount = 1
        return progress
    }
    
    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> R1ColorCollectionProvider {
        let decoder = JSONDecoder()
        do {
            let config = try decoder.decode(R1ColorCollection.self, from: data)
            return R1ColorCollectionProvider(config)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
}

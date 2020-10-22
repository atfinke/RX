//
//  RXHardware.swift
//  RXKit
//
//  Created by Andrew Finke on 8/24/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import CoreBluetooth

public struct RXHardware: Codable, Equatable {
    
    // MARK: - Types -
    
    public enum Edition: String, Codable, CaseIterable {
        case R1
        case RD
        
        public var buttons: Int {
            switch self {
            case .R1: return 4
            case .RD: return 1
            }
        }
        
        public var maxMessageSize: Int {
            return 20
        }
        
        public var serviceCBUUID: CBUUID {
            return CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
        }
    }
    
    public enum RXHardwareError: Error {
        case invalidSerialNumber
    }
    
    // MARK: - Properties -
    
    public let serialNumber: String
    public let edition: Edition
    public let identifier: UUID
    
    // MARK: - Initalization -
    
    public init(serialNumber: String, identifier: UUID) throws {
        self.serialNumber = serialNumber
        self.identifier = identifier
        
        if let val = Int(serialNumber), val < 10 {
            edition = .R1
        } else if serialNumber.count == 2 {
            edition = .RD
        } else {
            throw RXHardwareError.invalidSerialNumber
        }
    }
    
    // MARK: - Disk -
    
    static public func loadFromDisk() throws  -> RXHardware {
        guard let hardwareData = try? Data(contentsOf: RXURL.hardwareData()),
              let hardware = try? JSONDecoder().decode(RXHardware.self, from: hardwareData) else {
            throw RXError.initalSetupNeeded
        }
        return hardware
    }
    
    public func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: RXURL.hardwareData())
    }
}

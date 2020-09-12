//
//  RXNearbyManager.swift
//  RX Preferences
//
//  Created by Andrew Finke on 9/1/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import CoreBluetooth
import RXKit
import Combine
import os.log

class RXNearbyManager: NSObject, ObservableObject, CBCentralManagerDelegate {

    // MARK: - Properties -
    
    private var manager: CBCentralManager?
    
    // MARK: - Properties -
    
    @Published var shouldDisplayHardware = false
    var seenNearbyHardware = [RXHardware]()
    var queuedNearbyHardware = [RXHardware]()
    
    private let log = OSLog(subsystem: "com.andrewfinke.RX", category: "RX Prefs Bluetooth")
    
    // MARK: - Initalization -

    override init () {
        os_log("%{public}s", log: log, type: .info, #function)
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - CBCentralManagerDelegate -

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        os_log("%{public}s: %{public}i", log: log, type: .info, #function, central.state.rawValue)
        
        switch central.state {
        case .unknown, .resetting, .unsupported:
            print("unknown")
        case .unauthorized:
            print("unauthorized")
        case .poweredOff:
            print("poweredOff")
        case .poweredOn:
            let services = RXHardware.Edition.allCases.map { $0.serviceCBUUID }
            manager?.scanForPeripherals(
                withServices: services,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )
        @unknown default:
            fatalError()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name, name.count == 5, name.prefix(3) == "RX:" else { return }
        let serialNumber = String(name.dropFirst(3))
        
        os_log("%{public}s: %{public}s", log: log, type: .info, #function, serialNumber)
        
        do {
            let hardware = try RXHardware(serialNumber: serialNumber)
            DispatchQueue.main.async {
                if !self.seenNearbyHardware.contains(hardware) && !self.queuedNearbyHardware.contains(hardware) {
                    self.queuedNearbyHardware.append(hardware)
                    self.presentHardwareIfNeeded()
                }
            }
        } catch {
            os_log("%{public}s: invalid sn %{public}s", log: log, type: .error, #function, serialNumber)
        }
    }
    
    func firstQueuedHardwareNotOwners() {
        os_log("%{public}s", log: log, type: .info, #function)
        shouldDisplayHardware = false
        let hardware = queuedNearbyHardware.removeFirst()
        seenNearbyHardware.append(hardware)
        presentHardwareIfNeeded()
    }
    
    func presentHardwareIfNeeded() {
        os_log("%{public}s", log: log, type: .info, #function)
        if !shouldDisplayHardware && !queuedNearbyHardware.isEmpty {
            os_log("%{public}s: true", log: log, type: .info, #function)
            self.shouldDisplayHardware = true
        }
    }
    
}

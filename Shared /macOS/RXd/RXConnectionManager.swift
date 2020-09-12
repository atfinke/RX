//
//  RXConnectionManager.swift
//  RXd
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import CoreBluetooth
import os.log
import RXKit

class RXConnectionManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    // MARK: - Types -

    enum ListenerUpdate {
        case connected(name: String), error(String), buttonPressed(number: Int)
    }
    
    enum RXWriteMessage {
        case disconnect, appData(RXApp), readyForName, heartbeat
        
        fileprivate func data() -> [Data] {
            var values: [String]
            switch self {
            case .readyForName:
                values = ["n"]
            case .disconnect:
                values = ["q"]
            case .heartbeat:
                values = ["h"]
            case .appData(let app):
                values = ["s"]

                func hex(r: Double, g: Double, b: Double) -> String {
                    return String(format: "%02X", Int(r * 255)) +
                        String(format: "%02X", Int(g * 255)) +
                        String(format: "%02X", Int(b * 255))
                }

                // send the colors as hex strings, first the colors for the buttons in resting state, then in pressed
                [app.buttons.map { $0.colors.resting }, app.buttons.map { $0.colors.pressed }]
                    .flatMap { $0 }
                    .map { hex(r: $0.red, g: $0.green, b: $0.blue) }
                    .forEach { values.append($0) }
            }
            return values.compactMap({ $0.data(using: .utf8) })
        }
    }
    
    private enum RXReadMessage: String {
        case name = "n:"
        case buttonPressed = "b:"
        case heartbeat = "h"
    }

    // MARK: - Properties -

    private let hardware: RXHardware
    
    private lazy var manager: CBCentralManager = {
        return CBCentralManager(delegate: self, queue: nil)
    }()
    
    private var peripheral: CBPeripheral?

    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?
    private let writeQueue = DispatchQueue(label: "com.andrewfinke.RX.write", qos: .userInitiated)

    private var bufferedMessages = [Data]()
    private var errorNotificationDelayTimer: Timer?
    private let log = OSLog(subsystem: "com.andrewfinke.RX", category: "RXd Bluetooth")

    var isScanningEnabled = true
    
    // MARK: - Callbacks -

    var onUpdate: ((ListenerUpdate) -> Void)?

    // MARK: - Initalization -

    init(hardware: RXHardware) {
        os_log("%{public}s", log: log, type: .info, #function)
        self.hardware = hardware
        super.init()
        let _ = manager
    }
    
    // MARK: - Connection -

    func startScan() {
        guard isScanningEnabled && peripheral == nil else {
            return
        }
        
        guard manager.state == .poweredOn else {
            os_log("%{public}s: not powered on yet", log: log, type: .error, #function)
            return
        }
        
        os_log("%{public}s: scanForPeripherals: %{public}s", log: log, type: .info, #function, hardware.serialNumber)
        manager.scanForPeripherals(
            withServices: [hardware.edition.serviceCBUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    // MARK: - Sending Messages -

    func send(message: RXWriteMessage) {
        writeQueue.async {
            guard let peripheral = self.peripheral else {
                return
            }

            switch message {
            case .readyForName:
                os_log("%{public}s: readyForName", log: self.log, type: .info, #function)
            case .disconnect:
                os_log("%{public}s: disconnect", log: self.log, type: .info, #function)
            case .appData(let app):
                os_log("%{public}s: Colors: %{public}s", log: self.log, type: .info, #function, app.name)
            case .heartbeat:
                os_log("%{public}s: heartbeat", log: self.log, type: .info, #function)
            }
            
            for item in message.data() {
                if let prev = self.bufferedMessages.last, prev.count + item.count < self.hardware.edition.maxMessageSize {
                    self.bufferedMessages[self.bufferedMessages.count - 1] = prev + item
                } else {
                    self.bufferedMessages.append(item)
                }
            }
            self.sendFromBuffer()
            
            if case RXWriteMessage.disconnect = message {
                self.manager.cancelPeripheralConnection(peripheral)
            }
        }
    }

    private func sendFromBuffer() {
        writeQueue.async {
            guard !self.bufferedMessages.isEmpty, let peripheral = self.peripheral, let writeCharacteristic = self.writeCharacteristic  else { return }
            let data = self.bufferedMessages.removeFirst()
            peripheral.writeValue(data, for: writeCharacteristic, type: .withResponse)
        }
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
            startScan()
        @unknown default:
            fatalError()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        os_log("%{public}s: %{public}s", log: log, type: .info, #function, peripheral.name ?? "-")
        if peripheral.name == "RX:" + hardware.serialNumber {
            os_log("%{public}s: found RX: %{public}s", log: log, type: .info, #function, peripheral.identifier.uuidString)
            self.peripheral = peripheral
            central.stopScan()
            central.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("%{public}s", log: log, type: .info, #function)
        peripheral.delegate = self
        peripheral.discoverServices([hardware.edition.serviceCBUUID])
        errorNotificationDelayTimer?.invalidate()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        os_log("%{public}s: error: %{public}s", log: log, type: .error, #function, "\(String(describing: error?.localizedDescription))")
        self.peripheral = nil
        startScan()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("%{public}s: error: %{public}s", log: log, type: .error, #function, "\(String(describing: error?.localizedDescription))")
        
        self.peripheral = nil
        peripheral.delegate = nil
        
        if error != nil && isScanningEnabled {
            // Only show if can't recover quickly
            errorNotificationDelayTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { _ in
                self.onUpdate?(.error("Disconnected"))
            })
            startScan()
        }
    }

    // MARK: - CBPeripheralDelegate -

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            os_log("%{public}s: error: %{public}s", log: log, type: .error, #function, "\(String(describing: error?.localizedDescription))")
            return
        }
        os_log("%{public}s: %{public}s", log: log, type: .debug, #function, "\(services)")
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            os_log("%{public}s: error: %{public}s", log: log, type: .error, #function, "\(String(describing: error?.localizedDescription))")
            return
        }

        os_log("%{public}s: %{public}s", log: log, type: .debug, #function, "\(characteristics)")
        for characteristic in characteristics {
            if characteristic.properties == .notify {
                peripheral.setNotifyValue(true, for: characteristic)
                readCharacteristic = characteristic
                os_log("%{public}s: found notify", log: log, type: .info, #function)
            } else if characteristic.properties == [.write, .writeWithoutResponse] {
                writeCharacteristic = characteristic
                os_log("%{public}s: found write", log: log, type: .info, #function)
            } else {
                fatalError()
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        os_log("%{public}s", log: log, type: .info, #function)
        if let error = error {
            os_log("%{public}s: error: %{public}s", log: log, type: .error, #function, "\(String(describing: error.localizedDescription))")
            return
        } else {
            os_log("%{public}s: isNotifying: %{public}s", log: log, type: .info, #function, "\(characteristic.isNotifying)")
            send(message: .readyForName)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            os_log("%{public}s: error: %{public}s", log: log, type: .error, #function, "\(String(describing: error.localizedDescription))")
            return
        }
        
        guard readCharacteristic == characteristic,
              let value = characteristic.value,
              let str = String(data: value, encoding: .utf8),
              let messageType = RXReadMessage(rawValue: String(str.prefix(2))) else {
            os_log("%{public}s: parsing error", log: log, type: .error, #function)
            return
        }
        
        let message = str.dropFirst(2)
        
        switch messageType {
        case .name:
            let name = String(message)
            os_log("%{public}s: got name: %{public}s", log: log, type: .info, #function, name)
            onUpdate?(.connected(name: name))
        case .buttonPressed:
            guard let button = Int(message) else {
                os_log("%{public}s: parsing error", log: log, type: .error, #function)
                return
            }
            os_log("%{public}s: pressed: %{public}i", log: log, type: .info, #function, button)
            onUpdate?(.buttonPressed(number: button))
        case .heartbeat:
            send(message: .heartbeat)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        os_log("%{public}s", log: log, type: .debug, #function)
        if let error = error {
            os_log("%{public}s: error: %{public}s", log: log, type: .error, #function, "\(String(describing: error.localizedDescription))")
        } else {
            sendFromBuffer()
        }
    }
    
}

//
//  R1ConnectionManager.swift
//  R1d
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import CoreBluetooth
import os.log
import R1Kit

class R1ConnectionManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Types -
    
    enum Message {
        case ledsOff, disconnect, appData(R1App)
    }
    
    enum Update {
        case connected, error(String), buttonPressed(Int)
    }
    
    // MARK: - Properties -
    
    private var manager: CBCentralManager?
    private var peripheral: CBPeripheral?
    
    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?
    
    private var buffer = [Data]()
    
    private static let serviceUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    private static let maxMessageSize = 20
    
    private let log = OSLog(subsystem: "com.andrewfinke.R1", category: "bluetooth")
    
    // MARK: - Callbacks -
    
    var onUpdate: ((Update) -> Void)?
    
    // MARK: - Initalization -
    
    override init() {
        os_log("%{public}s", log: log, type: .info, #function)
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Helpers -
    
    func send(message: Message) {
        buffer.removeAll()
        
        switch message {
        case .ledsOff:
            os_log("%{public}s: ledsOff", log: log, type: .info, #function)
            guard let data = "x".data(using: .utf8) ,
                  let peripheral = peripheral,
                  let writeCharacteristic = writeCharacteristic else { return }
            peripheral.writeValue(data, for: writeCharacteristic, type: .withResponse)
        case .disconnect:
            os_log("%{public}s: disconnect", log: log, type: .info, #function)
            guard let data = "q".data(using: .utf8) ,
                  let peripheral = peripheral,
                  let writeCharacteristic = writeCharacteristic else { return }
            peripheral.writeValue(data, for: writeCharacteristic, type: .withResponse)
        case .appData(let app):
            os_log("%{public}s: %{public}s", log: log, type: .info, #function, app.name)
            
            compile(app: app)
            sendFromBuffer()
        }
    }
    
    func startScan() {
        if let connected = manager?.retrieveConnectedPeripherals(withServices: [R1ConnectionManager.serviceUUID]), !connected.isEmpty {
            os_log("%{public}s: retrieveConnectedPeripherals", log: log, type: .info, #function)
        } else {
            os_log("%{public}s: scanForPeripherals", log: log, type: .info, #function)
            manager?.scanForPeripherals(
                withServices: [R1ConnectionManager.serviceUUID],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )
        }
    }
    
    func errorOccurred(_ error: String) {
        if let peripheral = peripheral {
            manager?.cancelPeripheralConnection(peripheral)
            self.peripheral = nil
        }
        onUpdate?(.error(error))
    }
    
    // MARK: - CBCentralManagerDelegate -
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        os_log("%{public}s: %{public}i", log: log, type: .info, #function, central.state.rawValue)
        
        switch central.state {
        case .unknown, .resetting, .unsupported:
            print("hmm")
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
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        os_log("%{public}s", log: log, type: .info, #function)
        if peripheral.name == "R1" {
            os_log("%{public}s: found R1: %{public}s", log: log, type: .info, #function, peripheral.identifier.uuidString)
            self.peripheral = peripheral
            central.stopScan()
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("%{public}s", log: log, type: .info, #function)
        peripheral.delegate = self
        peripheral.discoverServices([R1ConnectionManager.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        os_log("%{public}s: error: %{public}s", log: log, type: .error, #function, "\(String(describing: error?.localizedDescription))")
        errorOccurred("Fail to connect issue")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("%{public}s: error: %{public}s", log: log, type: .error, #function, "\(String(describing: error?.localizedDescription))")
        errorOccurred("Disconnect peripheral issue")
        startScan()
    }
    
    // MARK: - CBPeripheralDelegate -
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            os_log("%{public}s: error: %{public}s", log: log, type: .error, #function, "\(String(describing: error?.localizedDescription))")
            errorOccurred("Discover services issue")
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
            errorOccurred("Discover characteristics issue")
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
            errorOccurred("Update notification state update issue")
            return
        } else {
            os_log("%{public}s: isNotifying: %{public}s", log: log, type: .info, #function, "\(characteristic.isNotifying)")
            onUpdate?(.connected)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            os_log("%{public}s: error: %{public}s", log: log, type: .error, #function, "\(String(describing: error.localizedDescription))")
            errorOccurred("Update value issue")
            return
        }
        
        guard readCharacteristic == characteristic,
              let value = characteristic.value,
              let str = String(data: value, encoding: .utf8),
              let button = Int(str) else {
            os_log("%{public}s: parsing error", log: log, type: .error, #function)
            return
        }
        
        os_log("%{public}s: pressed: %{public}i", log: log, type: .info, #function, button)
        onUpdate?(.buttonPressed(button))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        os_log("%{public}s", log: log, type: .debug, #function)
        if let error = error {
            os_log("%{public}s: error: %{public}s", log: log, type: .error, #function, "\(String(describing: error.localizedDescription))")
            errorOccurred("Write value issue")
        } else {
            sendFromBuffer()
        }
    }
    
    // MARK: - Buffer -
    
    private func sendFromBuffer() {
        guard !buffer.isEmpty, let peripheral = peripheral, let writeCharacteristic = writeCharacteristic  else { return }
        let data = buffer.removeFirst()
        peripheral.writeValue(data, for: writeCharacteristic, type: .withResponse)
    }
    
    private func compile(app: R1App) {
        var buffer = ["s,"]
        
        func insert(r: Double, g: Double, b: Double) {
            let hex = String(format:"%02X", Int(r * 255)) +
                String(format:"%02X", Int(g * 255)) +
                String(format:"%02X", Int(b * 255)) +
                ","
            buffer.append(hex)
        }
        
        /// A little bit of a mess, but want to push over the new open colors asap.
        /// It takes R1 Proto V6 hardware 1-3 seconds for all the data to be transfered...
        /// ... and the hardware will show the open color as soon as it has it for all the buttons, even if it hasn't received the other states yet.
        let collections = [
            app.buttons.map { $0.colors.resting },
            app.buttons.map { $0.colors.pressed }
        ]
        
        collections.flatMap { $0 }
            .map { (r: $0.red, g: $0.green, b: $0.blue) }
            .forEach { insert(r: $0.r, g: $0.g, b: $0.b) }
        buffer.append("e")
        print(buffer)
        
        var temp = [Data]()
        for item in buffer.compactMap({ $0.data(using: .utf8) }) {
            if let prev = temp.last, prev.count + item.count < R1ConnectionManager.maxMessageSize {
                temp[temp.count - 1] = prev + item
            } else {
                temp.append(item)
            }
        }
        
        self.buffer = temp
    }
    
}

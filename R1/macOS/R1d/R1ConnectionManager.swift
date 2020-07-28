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

    private enum R1Command: String {
        case disconnect = "q"
        case turnOffLeds = "x"
        case ledColors = "s"
    }

    // MARK: - Properties -

    private var manager: CBCentralManager?
    private var peripheral: CBPeripheral?

    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?

    private var bufferedMessages = [Data]()

    private static let serviceUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    private static let maxMessageSize = 20

    private let log = OSLog(subsystem: "com.andrewfinke.R1", category: "bluetooth")

    var isScanningEnabled = true {
        didSet {
            if isScanningEnabled && !oldValue {
                startScan()
            }
        }
    }
    
    var isConnected: Bool {
        return peripheral != nil
    }
    
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
        bufferedMessages.removeAll()

        switch message {
        case .ledsOff:
            os_log("%{public}s: ledsOff", log: log, type: .info, #function)
            guard let data = R1Command.turnOffLeds.rawValue.data(using: .utf8) ,
                  let peripheral = peripheral,
                  let writeCharacteristic = writeCharacteristic else { return }
            peripheral.writeValue(data, for: writeCharacteristic, type: .withResponse)
        case .disconnect:
            os_log("%{public}s: disconnect", log: log, type: .info, #function)
            guard let data = R1Command.disconnect.rawValue.data(using: .utf8) ,
                  let peripheral = peripheral,
                  let writeCharacteristic = writeCharacteristic else { return }
            manager?.delegate = nil
            peripheral.delegate = nil
            peripheral.writeValue(data, for: writeCharacteristic, type: .withResponse)
            self.peripheral = nil
        case .appData(let app):
            os_log("%{public}s: %{public}s", log: log, type: .info, #function, app.name)

            compile(app: app)
            sendFromBuffer()
        }
    }

    func startScan() {
        guard isScanningEnabled else {
            return
        }
        
        os_log("%{public}s: scanForPeripherals", log: log, type: .info, #function)
        manager?.scanForPeripherals(
            withServices: [R1ConnectionManager.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func discovered(device: CBPeripheral) {
        peripheral = device
        manager?.stopScan()
        manager?.connect(device, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true])
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
        if peripheral.name == "R1" {
            os_log("%{public}s: found R1: %{public}s", log: log, type: .info, #function, peripheral.identifier.uuidString)
            discovered(device: peripheral)
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
        guard !bufferedMessages.isEmpty, let peripheral = peripheral, let writeCharacteristic = writeCharacteristic  else { return }
        let data = bufferedMessages.removeFirst()
        peripheral.writeValue(data, for: writeCharacteristic, type: .withResponse)
    }

    private func compile(app: R1App) {
        var dataToEncode = [R1Command.ledColors.rawValue]

        func hex(r: Double, g: Double, b: Double) -> String {
            return String(format: "%02X", Int(r * 255)) +
                String(format: "%02X", Int(g * 255)) +
                String(format: "%02X", Int(b * 255))
        }

        [app.buttons.map { $0.colors.resting }, app.buttons.map { $0.colors.pressed }]
            .flatMap { $0 }
            .map { hex(r: $0.red, g: $0.green, b: $0.blue) }
            .forEach { dataToEncode.append($0) }

        var messages = [Data]()
        for item in dataToEncode.compactMap({ $0.data(using: .utf8) }) {
            if let prev = messages.last, prev.count + item.count < R1ConnectionManager.maxMessageSize {
                messages[messages.count - 1] = prev + item
            } else {
                messages.append(item)
            }
        }

        self.bufferedMessages = messages
    }

}

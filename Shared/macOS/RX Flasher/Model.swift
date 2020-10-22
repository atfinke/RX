//
//  Model.swift
//  RX Flasher
//
//  Created by Andrew Finke on 9/26/20.
//

import Foundation

class Model: ObservableObject {
    
    // MARK: - Properties -
    
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var connectedDevicePath: String = ""
    
    var formFirmwarePath: String = "/Users/andrewfinke/Projects/RX/Shared/Microcontroller"
    var formDeviceType: String = "RD" {
        didSet {
            if formDeviceName.starts(with: "TBD") {
                formDeviceName = "TBD's \(formDeviceType)"
            }
        }
    }
    @Published var formDeviceName: String = "TBD's RD"
    var formDeviceSerialNumber: String = ""
    
    @Published var isDoneFlashing: Bool = false
    
    private var volumeURL: URL?
    
    // MARK: - Initalization -
    
    init() {
        checkVolumes()
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            DispatchQueue.main.async {
                self.checkVolumes()
            }
        }
    }
    
    // MARK: - Steps -
    
    func checkVolumes() {
        let volumesURL = URL(fileURLWithPath: "/Volumes")
        guard let items = try? FileManager.default.contentsOfDirectory(at: volumesURL, includingPropertiesForKeys: nil) else {
            fatalError()
        }
        let relevent = items.filter { $0.path.hasSuffix("CIRCUITPY") || $0.path.hasSuffix("R1") || $0.path.hasSuffix("RD") }
        if let item = relevent.first {
            isConnected = true
            connectedDevicePath = item.path
            volumeURL = item
        } else {
            isConnected = false
            connectedDevicePath = "-"
            volumeURL = nil
        }
    }
    
    func flash() {
        print("Checking firmware url")
        let firmwareURL = URL(fileURLWithPath: formFirmwarePath)
        guard FileManager.default.fileExists(atPath: firmwareURL.path, isDirectory: nil) else {
            fatalError()
        }
        
        print("Checking volume url")
        guard let volumeURL = volumeURL else {
            fatalError()
        }
        
        print("Deleting items on device @ \(volumeURL)")
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: volumeURL, includingPropertiesForKeys: nil)
            for url in urls {
                print(" - " + url.path)
                try? FileManager.default.removeItem(at: url)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
        
        
        print("Copying items on device from \(firmwareURL)")
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: firmwareURL, includingPropertiesForKeys: nil)
            for url in urls where !url.path.contains("DS_Store") && !url.path.contains("hardware_config") {
                let newURL = volumeURL.appendingPathComponent(url.lastPathComponent)
                print(" - " + url.path + " -> " +  newURL.path)
                try FileManager.default.copyItem(at: url, to: newURL)
            }
            let hardwareConfigURL = firmwareURL.appendingPathComponent("hardware_config <\(formDeviceType)>.py")
            let newHardwareConfigURL = volumeURL.appendingPathComponent("hardware_config.py")
            
            let file = try String(contentsOf: hardwareConfigURL)
            let newFile = file.replacingOccurrences(of: "<NAME>", with: formDeviceName)
                .replacingOccurrences(of: "<SERIAL_NUMBER>", with: formDeviceSerialNumber)
            try newFile.write(to: newHardwareConfigURL, atomically: true, encoding: .utf8)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        print("Renaming drive")
        let process = Process()
        process.launchPath = "/usr/sbin/diskutil"
        process.arguments = [
            "rename",
            volumeURL.path,
            formDeviceType
        ]
        process.launch()
        
        print("Done")
        isDoneFlashing = true
    }
}

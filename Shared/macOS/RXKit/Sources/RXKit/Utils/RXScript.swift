//
//  RXScript.swift
//  RXKit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

#if os(macOS)

import Cocoa
import os.log

// Not Codable
private let log = OSLog(subsystem: "com.andrewfinke.RX", category: "RXd Script")

public struct RXScript: Codable, Equatable {
    
    // MARK: - Properties -
    
    public let name: String
    public let fileURL: URL
    
    // MARK: - Initalization -
    
    public init(name: String, fileURL: URL) {
        self.name = name
        self.fileURL = fileURL
    }
    
    // MARK: - Running -
    
    public func run() {
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = [fileURL.path]
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        var errorOutput = ""
        errorPipe.fileHandleForReading.readabilityHandler = { pipe in
            guard let line = String(data: pipe.availableData, encoding: .utf8), !line.isEmpty else {
                return
            }
            os_log("Error Pipe: %{public}s", log: log, type: .error, line)
            errorOutput += line + "\n\n"
        }
        
        process.terminationHandler = { process in
            switch process.terminationReason {
            case .exit:
                os_log("Process: exit", log: log, type: .info)
                if errorOutput.contains("execution error:") {
                    self.displayError(output: errorOutput)
                }
            default:
                os_log("Process: uncaught signal", log: log, type: .error)
                self.displayError(output: errorOutput)
            }
        }
        process.launch()
    }
    
    private func displayError(output: String) {
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = [
            "-e",
            """
            set theDialogText to "RXd encountered an error when running your script:\n\n\(output.replacingOccurrences(of: "\"", with: "\\\""))"
            display dialog theDialogText buttons {"Show Script in Finder", "Ok"} default button "Ok" with icon stop
            """
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        var output = ""
        pipe.fileHandleForReading.readabilityHandler = { pipe in
            guard let line = String(data: pipe.availableData, encoding: .utf8), !line.isEmpty else {
                return
            }
            os_log("Display Error Pipe: %{public}s", log: log, type: .debug, line)
            output += line
        }
        process.terminationHandler = { process in
            os_log("Display Error Process: exit", log: log, type: .info)
            if output.contains("Show Script") {
                NSWorkspace.shared.selectFile(self.fileURL.path, inFileViewerRootedAtPath: "")
            }
        }
        process.launch()
    }
}

#endif

//
//  AppDelegate.swift
//  R1 Helper
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa
import R1Kit
import os.log

class Main {
    
    // MARK: - Properties -
    
    private var manager: R1ConnectionManager?
    private let log = OSLog(subsystem: "com.andrewfinke.R1", category: "main")
    
    private var settings = R1Settings(writingEnabled: false)
    private var config: R1AppConfig? {
        didSet {
            guard config?.name != oldValue?.name else { return }
            if let config = config {
                manager?.send(config: config)
            } else {
                // turn off buttons
            }
        }
    }
    
    // MARK: - Initalization -
    
    init() {
        manager = R1ConnectionManager(onConnect: {
            ScriptRunner.showNotification(title: "R1 Connected", text: "-")
            if let config = self.config {
                self.manager?.send(config: config)
            }
        }, onPress: { number in
            Helpers.pressed(button: number, for: self.config)
        }, onError: { error in
            ScriptRunner.showNotification(title: "R1 Error", text: error)
        })
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            DispatchQueue.main.async {
                self.checkActiveApp()
            }
        })
    }
    
    // MARK: - Helpers -
    
    func checkActiveApp() {
        let activeApp = Helpers.activeApp()
        
        if activeApp == "R1 Config" {
            settings = R1Settings(writingEnabled: false)
            if let def = settings.defaultAppConfigs.first(where: { $0.name == "Default" }), def != config {
                manager?.send(config: def)
            }
            return
        }
        
        let configs = settings.customAppConfigs + settings.defaultAppConfigs
        if let activeConfig = configs.first(where: { $0.name == activeApp }) {
            config = activeConfig
        } else if let def = configs.first(where: { $0.name == "Default" }) {
            config = def
        } else {
            fatalError()
        }
    }
}

let main = Main()
RunLoop.main.run()

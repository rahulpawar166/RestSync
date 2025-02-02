//
//  LaunchAtLogin.swift
//  RestSync
//
//  Created by Rahul Pawar on 1/19/25.
//

import ServiceManagement
import Foundation

class LaunchAtLogin {
    static let shared = LaunchAtLogin()
    
    private init() {}
    
    var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                    try SMAppService.mainApp.register()
                    print("Launch at login enabled successfully")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("Launch at login disabled successfully")
                }
            } catch {
                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }
    
    func toggle() {
        isEnabled = !isEnabled
    }
    
    // Helper method to verify current status
    func printStatus() {
        print("System status: \(SMAppService.mainApp.status == .enabled)")
    }
}

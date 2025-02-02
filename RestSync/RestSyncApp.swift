//
//  RestSyncApp.swift
//  RestSync
//
//  Created by Rahul Pawar on 2/2/25.
//

import SwiftUI

@main
struct RestSyncApp: App {
        // Link the AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            RestSyncView()
        }
    }
}

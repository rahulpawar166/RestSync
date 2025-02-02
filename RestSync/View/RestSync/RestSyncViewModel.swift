//
//  RestSyncViewModel.swift
//  RestSync
//
//  Created by Rahul Pawar on 1/4/25.
//

import SwiftUI

class RestSyncViewModel: ObservableObject {
    
    @Injected private var timerManager: TimerManager
    @Injected private var launchAtLogin: LaunchAtLogin
    @Injected private var eventChecker: EventChecker

    @AppStorage(LocalStorageKeys.isSubscriptionEnabled) var isSubscriptionEnabled: Bool = false
    @AppStorage(LocalStorageKeys.isBreakSyncEnabledKey) var isBreakReminderEnabled: Bool = false {
        didSet {
            if isBreakReminderEnabled {
                UserDefaults.standard.setValue(true, forKey: LocalStorageKeys.isBreakSyncEnabledKey)
            } else {
                timerManager.stopBreakSyncTimer()
                launchAtLogin.isEnabled = false
                UserDefaults.standard.removeObject(forKey: LocalStorageKeys.isBreakSyncEnabledKey)
            }
        }
    }
    @AppStorage(LocalStorageKeys.breakTimeKey) var breakReminderTimeInSeconds: Int = TimerManager.shared.breakSyncTimeLeft
    @AppStorage(LocalStorageKeys.breakDurationKey) var breakDurationTimeInSeconds: Int = 60 // Initially it is 1 min
    @AppStorage(LocalStorageKeys.isBreakSyncNotificationEnabledKey) var isBreakSyncNotificationEnabledKey: Bool = true
    
    @Published var isLaunchAtLogin: Bool = false {
        didSet {
            launchAtLogin.isEnabled = isLaunchAtLogin
        }
    }
    @Published var isPresentLaunchAtLoginAlert: Bool = false
    @Published var showLaunchAtLoginInfo: Bool = false
    @Published var isCalendarAccessGranted: Bool = false
    @Published var showCalendarAccessInfo: Bool = false
    @Published var showRestSyncInfo: Bool = false

    init() {
        isLaunchAtLogin = launchAtLogin.isEnabled
        isCalendarAccessGranted = eventChecker.isCalendarAccessGranted()
    }
    
    // Helper function to format the time in hr min format
    func formattedTime(for minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        var timeString = ""
        
        if hours > 0 {
            timeString += "\(hours) hr"
        }
        
        if remainingMinutes > 0 {
            if !timeString.isEmpty {
                timeString += " "
            }
            timeString += "\(remainingMinutes) min"
        }
        
        return timeString.isEmpty ? "0 min" : timeString
    }

}

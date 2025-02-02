//
//  TimerManager.swift
//  RestSync
//
//  Created by Rahul Pawar on 1/10/25.
//

import SwiftUI
import Combine

class TimerManager: ObservableObject {
    static let shared = TimerManager()
    
        // Break Timer Properties
    @Published var isBreakSyncTimerEnabled: Bool = UserDefaults.standard.bool(forKey: LocalStorageKeys.isBreakSyncEnabledKey)
    @Published var breakSyncTimeLeft: Int = UserDefaults.standard.integer(forKey: LocalStorageKeys.breakTimeKey) > 0 ? UserDefaults.standard.integer(forKey: LocalStorageKeys.breakTimeKey) : 1200 {
        didSet {
            if UserDefaults.standard.integer(forKey: LocalStorageKeys.breakTimeKey) == 0 {
                UserDefaults.standard
                    .set(1200, forKey: LocalStorageKeys.breakTimeKey)
            }
        }
    }
    var isBreakSyncNotificationEnabled: Bool = UserDefaults.standard.bool(forKey: LocalStorageKeys.isBreakSyncNotificationEnabledKey)
    @Published var isBreakSyncPaused: Bool = false
    @Published var didReachBreakTime: Bool = false
    @Published var didReachNotificationTime: Bool = false
    @Published var breakDurationTime: Int = UserDefaults.standard.integer(forKey: LocalStorageKeys.breakDurationKey) > 0 ? UserDefaults.standard.integer(forKey: LocalStorageKeys.breakDurationKey) : 60 {
        didSet {
            if UserDefaults.standard.integer(forKey: LocalStorageKeys.breakDurationKey) == 0 {
                UserDefaults.standard
                    .set(60, forKey: LocalStorageKeys.breakDurationKey)
            }
        }
    }
    private var breakSyncTimer: Timer?
    
        // Break Timer Methods
    func toggleBreakSyncTimer() {
        isBreakSyncTimerEnabled.toggle()
        if isBreakSyncTimerEnabled {
            startBreakSyncTimer()
        } else {
            stopBreakSyncTimer()
        }
    }
    
    func startBreakSyncTimer() {
        guard breakSyncTimer == nil, UserDefaults.standard.bool(forKey: LocalStorageKeys.isBreakSyncEnabledKey) == true else { return }
        isBreakSyncPaused = false
        breakSyncTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickBreakSyncTimer()
        }
    }
    
    func stopBreakSyncTimer() {
        breakSyncTimer?.invalidate()
        breakSyncTimer = nil
    }
    
    func resetBreakSyncTimer() {
        stopBreakSyncTimer()
        breakSyncTimeLeft = UserDefaults.standard.integer(forKey: LocalStorageKeys.breakTimeKey)
        startBreakSyncTimer()
    }
    
    func pauseBreakSyncTimer() {
        isBreakSyncPaused = true
        stopBreakSyncTimer()
    }
    
    func resumeBreakSyncTimer() {
        isBreakSyncPaused = false
        startBreakSyncTimer()
    }
    
    private func tickBreakSyncTimer() {
        if breakSyncTimeLeft > 0 {
            breakSyncTimeLeft -= 1
            if isBreakSyncNotificationEnabled, breakSyncTimeLeft <= 60 {
                didReachNotificationTime = true
            }
        } else {
            stopBreakSyncTimer()
            notifyBreakTime()
        }
    }
    
    private func notifyBreakTime() {
        didReachBreakTime = true
    }
}

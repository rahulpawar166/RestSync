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
    
    // MARK: - Published Properties
    @Published var isBreakSyncTimerEnabled: Bool = false {
        didSet {
            if isBreakSyncTimerEnabled {
                startBreakSyncTimer()
            } else {
                stopBreakSyncTimer()
            }
            // Save to UserDefaults
            UserDefaults.standard.set(isBreakSyncTimerEnabled, forKey: LocalStorageKeys.isBreakSyncEnabledKey)
        }
    }
    
    @Published var breakSyncTimeLeft: Int = 1200 { // Default 20 minutes
        didSet {
            // Save to UserDefaults when changed
            UserDefaults.standard.set(breakSyncTimeLeft, forKey: LocalStorageKeys.breakTimeKey)
        }
    }
    
    @Published var breakDurationTime: Int = 60 { // Default 1 minute
        didSet {
            // Save to UserDefaults when changed
            UserDefaults.standard.set(breakDurationTime, forKey: LocalStorageKeys.breakDurationKey)
        }
    }
    
    @Published var isBreakSyncPaused: Bool = false
    @Published var didReachBreakTime: Bool = false
    @Published var didReachNotificationTime: Bool = false
    @Published var isInBreak: Bool = false // True when break overlay is showing
    
    // MARK: - Private Properties
    private var breakSyncTimer: Timer?
    private var breakOverlayController: BreakOverlayController?
    private var originalBreakTime: Int = 1200 // Store original time for reset
    
    var isBreakSyncNotificationEnabled: Bool {
        return UserDefaults.standard.bool(forKey: LocalStorageKeys.isBreakSyncNotificationEnabledKey)
    }
    
    // MARK: - Initialization
    private init() {
        loadFromUserDefaults()
    }
    
    private func loadFromUserDefaults() {
        // Load saved values or use defaults
        isBreakSyncTimerEnabled = UserDefaults.standard.bool(forKey: LocalStorageKeys.isBreakSyncEnabledKey)
        
        let savedBreakTime = UserDefaults.standard.integer(forKey: LocalStorageKeys.breakTimeKey)
        breakSyncTimeLeft = savedBreakTime > 0 ? savedBreakTime : 1200
        originalBreakTime = breakSyncTimeLeft
        
        let savedBreakDuration = UserDefaults.standard.integer(forKey: LocalStorageKeys.breakDurationKey)
        breakDurationTime = savedBreakDuration > 0 ? savedBreakDuration : 60
        
        print("TimerManager loaded - Break time: \(breakSyncTimeLeft), Duration: \(breakDurationTime), Enabled: \(isBreakSyncTimerEnabled)")
    }
    
    // MARK: - Public Timer Methods
    func toggleBreakSyncTimer() {
        isBreakSyncTimerEnabled.toggle()
    }
    
    func startBreakSyncTimer() {
        guard breakSyncTimer == nil else {
            print("Timer already running")
            return
        }
        
        guard isBreakSyncTimerEnabled else {
            print("Timer not enabled")
            return
        }
        
        print("Starting break timer with \(breakSyncTimeLeft) seconds")
        isBreakSyncPaused = false
        
        breakSyncTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickBreakSyncTimer()
        }
    }
    
    func stopBreakSyncTimer() {
        print("Stopping break timer")
        breakSyncTimer?.invalidate()
        breakSyncTimer = nil
        isBreakSyncPaused = false
    }
    
    func resetBreakSyncTimer() {
        print("Resetting break timer")
        stopBreakSyncTimer()
        
        // Reset to original time
        breakSyncTimeLeft = originalBreakTime
        
        // Clear flags
        didReachBreakTime = false
        didReachNotificationTime = false
        isInBreak = false
        
        // Restart if enabled
        if isBreakSyncTimerEnabled {
            startBreakSyncTimer()
        }
    }
    
    func pauseBreakSyncTimer() {
        print("Pausing break timer")
        isBreakSyncPaused = true
        breakSyncTimer?.invalidate()
        breakSyncTimer = nil
    }
    
    func resumeBreakSyncTimer() {
        print("Resuming break timer")
        guard isBreakSyncPaused else { return }
        isBreakSyncPaused = false
        startBreakSyncTimer()
    }
    
    // MARK: - Timer Logic
    private func tickBreakSyncTimer() {
        if breakSyncTimeLeft > 0 {
            breakSyncTimeLeft -= 1
            
            // Check for notification (1 minute before break)
            if isBreakSyncNotificationEnabled && breakSyncTimeLeft == 60 && !didReachNotificationTime {
                print("Triggering notification - 1 minute until break")
                didReachNotificationTime = true
            }
        } else {
            print("Break time reached!")
            stopBreakSyncTimer()
            notifyBreakTime()
        }
    }
    
    private func notifyBreakTime() {
        print("Starting break with duration: \(breakDurationTime) seconds")
        didReachBreakTime = true
        isInBreak = true
        
        // Show overlay
        breakOverlayController = BreakOverlayController()
        breakOverlayController?.showOverlay(duration: breakDurationTime) { [weak self] in
            self?.endBreak()
        }
    }
    
    private func endBreak() {
        print("Ending break")
        isInBreak = false
        breakOverlayController?.dismissOverlay()
        breakOverlayController = nil
        
        // Reset timer for next break cycle
        resetBreakSyncTimer()
    }
    
    // MARK: - Public Utility Methods
    func updateBreakTime(_ newTimeInSeconds: Int) {
        print("Updating break time to: \(newTimeInSeconds) seconds")
        originalBreakTime = newTimeInSeconds
        
        // If timer is not running, update current time left as well
        if breakSyncTimer == nil {
            breakSyncTimeLeft = newTimeInSeconds
        }
    }
    
    func updateBreakDuration(_ newDurationInSeconds: Int) {
        print("Updating break duration to: \(newDurationInSeconds) seconds")
        breakDurationTime = newDurationInSeconds
    }
    
    // MARK: - Debug Methods
    func printCurrentState() {
        print("""
        TimerManager State:
        - Enabled: \(isBreakSyncTimerEnabled)
        - Time Left: \(breakSyncTimeLeft)
        - Duration: \(breakDurationTime)
        - Paused: \(isBreakSyncPaused)
        - In Break: \(isInBreak)
        - Timer Running: \(breakSyncTimer != nil)
        """)
    }
}

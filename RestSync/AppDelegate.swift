//
//  AppDelegate.swift
//  RestSync
//
//  Created by Rahul Pawar on 1/4/25.
//

import Cocoa
import SwiftUI
import UserNotifications
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var cancellables = Set<AnyCancellable>()
    private var overlayWindow: OverlayWindow?
    private let timerManager = TimerManager.shared
    
    private var breakDurationTime = TimerManager.shared.breakDurationTime
    
    var statusItem: NSStatusItem?
    
    @Injected private var eventChecker: EventChecker
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupNotificationCenter()
        observeTimerManager()
        
        // Request calendar access
        eventChecker.requestAccess { granted in
            DispatchQueue.main.async {
                if granted {
                    print("Calendar access granted.")
                } else {
                    print("Calendar access denied.")
                }
            }
        }
        
    }
    
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func observeTimerManager() {
        timerManager.$isBreakSyncTimerEnabled.sink { [weak self] isEnabled in
            if isEnabled {
                self?.updateStatusBar()
                self?.timerManager.startBreakSyncTimer()
            } else {
                self?.removeStatusBar()
                self?.hideBreakOverlay()
            }
        }.store(in: &cancellables)
        
        timerManager.$breakSyncTimeLeft.sink { [weak self] _ in
            self?.updateStatusBarTitle()
        }.store(in: &cancellables)
        
        timerManager.$isBreakSyncPaused.sink { [weak self] isPaused in
            self?.updatePauseResumeMenuItem(isPaused: isPaused)
        }.store(in: &cancellables)
        
        timerManager.$didReachBreakTime.sink { [weak self] didReachBreak in
            if didReachBreak {
                self?.showBreakOverlay()
                self?.timerManager.didReachBreakTime = false // Reset the flag
            }
        }.store(in: &cancellables)
        
        timerManager.$breakDurationTime.sink { [weak self] breakDurationTime in
            self?.breakDurationTime = breakDurationTime
        }.store(in: &cancellables)
        
        timerManager.$didReachNotificationTime.sink { [weak self] didReachNotificationTime in
            self?.showReminderNotification()
        }.store(in: &cancellables)
    }
    
    private func updateStatusBar() {
        if statusItem == nil {
            print("Creating status item...") // Debug log
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "hourglass.circle", accessibilityDescription: "Timer Icon")
            button.image?.isTemplate = true
            updateStatusBarTitle()
        }
        
        // Debug log
        print("Status item button initialized: \(statusItem?.button != nil)")
        
        // Set up the menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Skip Break", action: #selector(skipBreak), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Pause Timer", action: #selector(togglePauseResume), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open RestSync", action: #selector(openApp), keyEquivalent: "")) // Add this line
        menu.addItem(NSMenuItem.separator()) // Add a separator
        menu.addItem(NSMenuItem(title: "Quit RestSync", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    @objc private func openApp() {
        // If your app's main window is hidden, this will show it
        NSApp.activate(ignoringOtherApps: true)
        
        // Get the main window or create it if it doesn't exist
        if let window = NSApp.windows.first(where: { $0.title == "RestSync" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Create and show your main window if it doesn't exist
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 720),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            // Replace MainView() with your actual main SwiftUI view
            let contentView = NSHostingView(rootView: RestSyncView())
            window.contentView = contentView
            window.makeKeyAndOrderFront(nil)
//            window.title = "RestSync"
//            window.titleVisibility = .hidden
//            window.appearance = NSAppearance(named: .darkAqua) // Match your app theme
        }
    }

    private func removeStatusBar() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }
    
    private func updateStatusBarTitle() {
        if let button = statusItem?.button {
            let minutes = timerManager.breakSyncTimeLeft / 60
            let seconds = timerManager.breakSyncTimeLeft % 60
            button.title = String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func updatePauseResumeMenuItem(isPaused: Bool) {
        statusItem?.menu?.item(withTitle: "Pause Timer")?.title = isPaused ? "Resume Timer" : "Pause Timer"
    }
    
    @objc private func skipBreak() {
        timerManager.resetBreakSyncTimer()
    }
    
    @objc private func togglePauseResume() {
        if timerManager.isBreakSyncPaused {
            timerManager.resumeBreakSyncTimer()
        } else {
            timerManager.pauseBreakSyncTimer()
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func showBreakOverlay() {
        guard overlayWindow == nil else { return }
        
        guard let mainScreen = NSScreen.main else { return }
        overlayWindow = OverlayWindow(contentRect: mainScreen.frame)
        
        let overlayView = BreakOverlayView(
            breakStartTitle: getBreakOverlayTitleAndSubtitle().title,
            breakStartMessage: getBreakOverlayTitleAndSubtitle().subtitle,
            breakDuration: breakDurationTime,
            onCancel: { [weak self] in self?.hideBreakOverlay() }
        )
        overlayWindow?.level = .screenSaver
        overlayWindow?.contentView = NSHostingView(rootView: overlayView)
        overlayWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    private func hideBreakOverlay() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        timerManager.resetBreakSyncTimer()
    }
    
    private func showReminderNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Break Reminder"
        content.body = "Your break starts in 1 minute. Do you want to skip your upcoming break?"
        content.sound = .default
        
        let skipAction = UNNotificationAction(identifier: "SKIP_BREAK", title: "Skip Break", options: [])
        let category = UNNotificationCategory(identifier: "BREAK_REMINDER",
                                              actions: [skipAction],
                                              intentIdentifiers: [],
                                              options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "BREAK_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "BREAK_REMINDER_NOTIFICATION", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
            case "SKIP_BREAK":
                timerManager.resetBreakSyncTimer()
            default:
                break
        }
        completionHandler()
    }
    
    private func getBreakOverlayTitleAndSubtitle() -> (title: String, subtitle: String) {
        // Break start titles
        let breakStartTitles = [
            "Time for a Break!",
            "Break Time!",
            "Take a Breather!",
            "Let's Pause!",
            "Rest Time!",
            "Time to Recharge!",
            "Step Away!",
            "Quick Break Now!",
            "Pause Moment!",
            "Time to Reset!",
            "Break Alert!",
            "Take Five!",
            "Rest Period!",
            "Time Out!",
            "Breather Time!",
            "Pause Point!",
            "Refresh Break!",
            "Break Check!",
            "Rest Stop!",
            "Unwind Time!",
            "Take a Moment!"
        ]
        
        // Break start messages
        let breakStartMessages = [
            "Time to rest those eyes and refresh your mind.",
            "Great work! Now take a moment to recharge.",
            "You deserve a break - take time to reset.",
            "Pause and reset - you've earned this break.",
            "Step away briefly and come back refreshed.",
            "Take a moment to recharge your energy.",
            "Nice work session - time for a quick breather.",
            "A short rest will help you stay focused.",
            "Productive session! Give yourself a break.",
            "Take a brief pause to maintain your momentum.",
            "Rest your mind and recharge.",
            "Time for a quick reset - you've been focused.",
            "Give yourself a moment to refresh.",
            "Break time - you've been productive.",
            "Take a short pause to stay energized.",
            "A quick rest will help you stay sharp.",
            "Step back for a moment - you're doing great.",
            "Time to recharge after focused work.",
            "Take a breather - you've been crushing it.",
            "Quick pause to keep your energy up."
        ]
        
        func getRandomMessage(from array: [String]) -> String {
            array.randomElement() ?? array[0]
        }
        
        return (getRandomMessage(from: breakStartTitles), getRandomMessage(from: breakStartMessages))
    }
}

//
//  BreakOverlayView.swift
//  RestSync
//
//  Created by Rahul Pawar on 1/7/25.
//

import SwiftUI

class BreakOverlayController {
    private var overlayWindows: [NSWindow] = []
    
    func showOverlay(duration: Int, onCancel: @escaping () -> Void) {
        guard overlayWindows.isEmpty else { return }
        
        // Force exit full-screen mode for the active application
        forceExitFullScreen()
        
        // Small delay to ensure full-screen exit completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.createOverlayWindows(duration: duration, onCancel: onCancel)
        }
    }
    
    private func createOverlayWindows(duration: Int, onCancel: @escaping () -> Void) {
        for screen in NSScreen.screens {
            let contentView = BreakOverlayView(breakDuration: duration) {
                self.dismissOverlay()
                onCancel()
            }
            
            let hostingView = NSHostingView(rootView: contentView)
            let window = OverlayWindow(contentRect: screen.frame)
            window.contentView = hostingView
            window.setFrame(screen.frame, display: true)
            
            // Additional window configuration for better full-screen handling
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            
            // Force the window to be visible and active
            NSApp.activate(ignoringOtherApps: true)
            
            overlayWindows.append(window)
        }
    }
    
    private func forceExitFullScreen() {
        // Get the currently active application
        let workspace = NSWorkspace.shared
        guard let activeApp = workspace.frontmostApplication else { return }
        
        // Send CMD+Control+F to exit full-screen (standard macOS shortcut)
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Create key down events for CMD+Control+F
        let cmdControlFDown = CGEvent(keyboardEventSource: source, virtualKey: 0x03, keyDown: true) // F key
        cmdControlFDown?.flags = [.maskCommand, .maskControl]
        
        let cmdControlFUp = CGEvent(keyboardEventSource: source, virtualKey: 0x03, keyDown: false)
        cmdControlFUp?.flags = [.maskCommand, .maskControl]
        
        // Post the events
        cmdControlFDown?.postToPid(activeApp.processIdentifier)
        cmdControlFUp?.postToPid(activeApp.processIdentifier)
    }
    
    func dismissOverlay() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }
}

// Custom window class to handle the overlay with full-screen support
class OverlayWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Maximum window level to appear above everything, including full-screen apps
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.maximumWindow)) + 1)
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        
        // Enhanced collection behavior for full-screen compatibility
        self.collectionBehavior = [
            .canJoinAllSpaces,          // Appears in all spaces
            .fullScreenAuxiliary,       // Can appear over full-screen apps
            .fullScreenDisallowsTiling, // Prevents tiling behavior
            .stationary                 // Stays in place during space transitions
        ]
        
        // Additional properties for better visibility
        self.hidesOnDeactivate = false  // Don't hide when app loses focus
        self.canHide = false            // Prevent hiding
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    override func orderFrontRegardless() {
        super.orderFrontRegardless()
        // Force the window to stay on top
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.maximumWindow)) + 1)
    }
}

// SwiftUI view for the break overlay
struct BreakOverlayView: View {
    
    var breakStartTitle: String = "Time to Recharge!"
    var breakStartMessage: String = "Take a short pause to stay energized."
    @State private var timeRemaining: Int
    @State private var wasPlayingBeforeBreak: Bool = false
    let onCancel: () -> Void
    
    // Computed property to format timeRemaining as MM:SS
    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    init(breakStartTitle: String = "Time to Recharge!",
         breakStartMessage: String = "Take a short pause to stay energized.",
         breakDuration: Int,
         onCancel: @escaping () -> Void) {
        self.breakStartTitle = breakStartTitle
        self.breakStartMessage = breakStartMessage
        self._timeRemaining = State(initialValue: breakDuration)
        self.onCancel = onCancel
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text(breakStartTitle)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(breakStartMessage)
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("\(formattedTime)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(.primary)
                
                Button(action: handleSkipBreak) {
                    Text("Skip Break")
                        .font(.headline)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(40)
        }
        .onAppear {
            handleBreakStart()
        }
    }
    
    private func handleBreakStart() {
        startBreakTimer()
    }
    
    private func handleSkipBreak() {
        onCancel()
    }
    
    private func startBreakTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                onCancel()
            }
        }
    }
}


#Preview {
    BreakOverlayView(breakDuration: 20, onCancel: {
        print("Hello, I am done")
    })
}

//
//  BreakOverlayView.swift
//  RestSync
//
//  Created by Rahul Pawar on 1/7/25.
//

import SwiftUI

// Custom window class to handle the overlay
class OverlayWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.level = .screenSaver
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
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

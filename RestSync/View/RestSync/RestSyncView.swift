//
//  RestSyncView.swift
//  RestSync
//
//  Created by Rahul Pawar on 1/4/25.
//

import SwiftUI

struct RestSyncView: View {
    @StateObject private var vm: RestSyncViewModel = .init()
    @StateObject private var timerManager: TimerManager = .shared
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                Image("restSync_Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("RestSync")
                        .font(.title)
                    
                    Text("Stay Productive, Stay Balanced")
                        .font(.callout)
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer()
                
                Button {
                    print("Subscription tapped")
                    vm.isSubscriptionEnabled.toggle()
                } label: {
                    Text(vm.isSubscriptionEnabled ? "Subscribed" : "Not Subscribed")
                        .font(.callout)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .foregroundStyle(vm.isSubscriptionEnabled ? Color("goldColor") : .secondary)
                        .background(content: {
                            Color.primary.opacity(0.2)
                        })
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            ScrollView {
                VStack(spacing: 16) {
                    BreakReminderView(vm: vm)
                }
                .scrollIndicators(.hidden)
            }
            
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: vm.isBreakReminderEnabled) { _ , isBreakReminderEnabled in
            timerManager.isBreakSyncTimerEnabled = isBreakReminderEnabled
        }
        .onChange(of: vm.breakReminderTimeInSeconds, { _, newBreakTime in
            timerManager.breakSyncTimeLeft = newBreakTime
        })
        .onChange(of: vm.breakDurationTimeInSeconds, { _, newBreakTime in
            timerManager.breakDurationTime = newBreakTime
        })
        .onAppear {
            timerManager.isBreakSyncTimerEnabled = vm.isBreakReminderEnabled
        }
    }
}

struct BreakReminderView: View {
    @ObservedObject var vm: RestSyncViewModel
    @ObservedObject var timerManager: TimerManager = .shared
    @State var showSubscriptionRequiredAlertForBreakTime: Bool = false
    
    @Injected private var launchAtLogin: LaunchAtLogin
    @Injected private var eventChecker: EventChecker
    
    private var hours: Int {
        timerManager.breakSyncTimeLeft / 3600
    }
    
    private var minutes: Int {
        (timerManager.breakSyncTimeLeft % 3600) / 60
    }
    
    private var seconds: Int {
        timerManager.breakSyncTimeLeft % 60
    }
    // Available times in minutes with a 10-minute interval (10, 20, 30, ..., 480 minutes)
    private var availableTimesInMinutesForBreakTime: [Int] {
        if vm.isSubscriptionEnabled {
            return Array(stride(from: 10, through: 480, by: 10))
        }
        return [20]
    }
    
    @State private var availableTimesInMinutesForBreakDuration: [Int] = []
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Taking a break from your screen helps reduce eye strain and improve focus. Step away, relax, and let your eyes rest—it’s a small pause that can make a big difference to your health and productivity!")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if vm.isBreakReminderEnabled {
                withAnimation(.easeInOut) {
                    HStack {
                        Spacer()
                        // Time Display
                        ForEach(getTimeUnits(), id: \.unit) { timeUnit in
                            if timeUnit.value > 0 {
                                TimeUnitView(value: timeUnit.value, unit: timeUnit.unit)
                            }
                        }
                        Spacer()
                        
                        HStack {
                            Button {
                                timerManager.resetBreakSyncTimer()
                            } label: {
                                Text("Skip")
                                    .font(.system(size: 15))
                            }
                            
                            Button {
                                timerManager.isBreakSyncPaused.toggle()
                                if timerManager.isBreakSyncPaused {
                                    timerManager.pauseBreakSyncTimer()
                                } else {
                                    timerManager.resumeBreakSyncTimer()
                                }
                            } label: {
                                Text(timerManager.isBreakSyncPaused ? "Resume" : "Pause")
                                    .font(.system(size: 15))
                            }
                        }
                        
                    }
                    .padding(.horizontal, 32)
                }
            }
            
            VStack(spacing: 16) {
                HStack {
                    Text("\(vm.isBreakReminderEnabled ? "Disable" : "Enable") RestSync")
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                    
                    Button {
                        // Show info alert
                        vm.showRestSyncInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $vm.showRestSyncInfo) {
                        VStack(spacing: 16) {
                            
                            Text("RestSync is your smart productivity companion, designed to enhance focus and well-being. It delivers timely break reminders, and ensures you maintain a healthy rhythm. With intelligent scheduling, RestSync integrates with your calendar to avoid interruptions during meetings, keeping you in sync with your commitments while prioritizing your health. Stay balanced, stay efficient with RestSync.")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(16)
                        .frame(width: 400)
                    }
                    
                    Spacer()
                    
                    Toggle(isOn: $vm.isBreakReminderEnabled) {
                        EmptyView()
                    }
                    .toggleStyle(SwitchToggleStyle())
                }
                .onChange(of: vm.isBreakReminderEnabled) { _, isEnabled in
                    if isEnabled {
                        vm.isPresentLaunchAtLoginAlert.toggle()
                    } else {
                        vm.isLaunchAtLogin = false
                    }
                }
                
                if vm.isBreakReminderEnabled {
                    HStack {
                        Text("Start RestSync when you log in")
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                        
                        Button {
                            // Show info alert
                            vm.showLaunchAtLoginInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Learn more about launch at login") // Hover tooltip
                        .popover(isPresented: $vm.showLaunchAtLoginInfo) {
                            VStack(spacing: 16) {
                                Text("About Launch at Login")
                                    .font(.system(size: 15))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Text("When enabled, RestSync will automatically start in the background when you log in to your Mac. This ensures you'll receive break reminders throughout your work day without having to manually start the app.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(16)
                            .frame(width: 400)
                        }
                        
                        Spacer()
                        
                        Toggle(isOn: $vm.isLaunchAtLogin) {
                            EmptyView()
                        }
                        .toggleStyle(SwitchToggleStyle())
                    }
                }
                
                HStack {
                    Text("Select Break Reminder Time")
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if vm.isSubscriptionEnabled {
                        Picker("", selection: $vm.breakReminderTimeInSeconds) {
                            ForEach(availableTimesInMinutesForBreakTime, id: \.self) { time in
                                Text(vm.formattedTime(for: time)) // Display time in hr min format
                                    .tag(time * 60) // Convert minutes to seconds
                                    .font(.system(size: 15))
                                    .foregroundStyle(.primary)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150, alignment: .trailing)
                        .onChange(of: vm.breakReminderTimeInSeconds) {_, newTime in
                            // Update available break durations based on the new break time
                            updateAvailableBreakDuration(newTime: newTime)
                            
                            // Ensure break duration doesn't exceed break reminder time
                            if vm.breakDurationTimeInSeconds > newTime {
                                vm.breakDurationTimeInSeconds = newTime - 1
                            }
                        }
                    } else {
                        Button {
                            showSubscriptionRequiredAlertForBreakTime.toggle()
                        } label: {
                            HStack {
                                Text("20 min")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.primary)
                                    .frame(width: 50, alignment: .leading)
                                    .padding(.trailing, 16)
                                
                                Image(systemName: "chevron.up.chevron.down.square.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .accent)
                            }
                        }
                    }
                }
                
                HStack {
                    Text("Select Break Duration Time")
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if vm.isSubscriptionEnabled {
                        Picker("", selection: $vm.breakDurationTimeInSeconds) {
                            ForEach(availableTimesInMinutesForBreakDuration, id: \.self) { time in
                                Text(vm.formattedTime(for: time)) // Display time in min format
                                    .tag(time * 60) // Convert minutes to seconds
                                    .font(.system(size: 15))
                                    .foregroundStyle(.primary)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150, alignment: .trailing)
                        .onChange(of: vm.breakDurationTimeInSeconds) {_, newDuration in
                            // Ensure break duration doesn't exceed break reminder time
                            if newDuration > vm.breakReminderTimeInSeconds {
                                vm.breakDurationTimeInSeconds = vm.breakReminderTimeInSeconds
                            }
                        }
                    } else {
                        Button {
                            showSubscriptionRequiredAlertForBreakTime.toggle()
                        } label: {
                            HStack {
                                Text("1 min")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.primary)
                                    .frame(width: 50, alignment: .leading)
                                    .padding(.trailing, 16)
                                
                                Image(systemName: "chevron.up.chevron.down.square.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .accent)
                            }
                        }
                    }
                }
                
                if vm.isBreakReminderEnabled {
                    Toggle(isOn: $vm.isBreakSyncNotificationEnabledKey) {
                        Text("Notify me before the break starts?")
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        Button {
                            if !vm.isCalendarAccessGranted {
                                eventChecker.openCalendarSettings()
                            }
                        } label: {
                            Toggle(isOn: $vm.isCalendarAccessGranted) {
                                Text("Allow Calendar access")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.primary)
                                    .frame(alignment: .leading)
                            }
                            .onChange(of: vm.isCalendarAccessGranted) { _ , newValue in
                                if newValue, !eventChecker.isCalendarAccessGranted() {
                                    vm.isCalendarAccessGranted = false
                                    eventChecker.openCalendarSettings()
                                }
                            }
                            
                        }
                        .buttonStyle(.plain)

                        
                        Button {
                            // Show info alert
                            vm.showCalendarAccessInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $vm.showCalendarAccessInfo) {
                            VStack(spacing: 16) {
                                
                                Text("We require calendar access to avoid showing break overlays during your important events, ensuring uninterrupted focus when it matters most.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(16)
                            .frame(width: 400)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .alert("Subscribe to Unlock Custom Time", isPresented: $showSubscriptionRequiredAlertForBreakTime) {
                Button {
                    print("")
                } label: {
                    Text("Subscribe")
                }
                
                Button {
                    showSubscriptionRequiredAlertForBreakTime.toggle()
                } label: {
                    Text("Later")
                }
            } message: {
                Text("To set a custom time, please subscribe to our premium plan.")
            }
            .alert("Start RestSync on Login?", isPresented: $vm.isPresentLaunchAtLoginAlert) {
                Button {
                    vm.isLaunchAtLogin.toggle()
                } label: {
                    Text("Start on Login")
                }
                
                Button {
                    print("LaunchAtLogin later!")
                } label: {
                    Text("Not Now")
                }
            } message: {
                Text("Would you like RestSync to automatically start when you log in to your Mac? This ensures you won't miss your regular break reminders.")
            }
        }
        .navigationTitle("RestSync")
        .onAppear {
            // Initialize available break duration times based on initial break time
            updateAvailableBreakDuration(newTime: vm.breakReminderTimeInSeconds)
        }
    }
    
    func getTimeUnits() -> [(value: Int, unit: String)] {
        return [
            (hours, "H"),
            (minutes, "M"),
            (seconds, "S")
        ]
    }
    
    // Function to update available break durations based on break reminder time
    private func updateAvailableBreakDuration(newTime: Int) {
        let maxDurationInMinutes = min(newTime / 60, 60) // Limit max duration to 60 minutes
        availableTimesInMinutesForBreakDuration = Array(stride(from: 1, to: maxDurationInMinutes, by: 1))
        
        // Ensure break duration is set to a valid value from available options
        if !availableTimesInMinutesForBreakDuration.contains(vm.breakDurationTimeInSeconds / 60) {
            vm.breakDurationTimeInSeconds = availableTimesInMinutesForBreakDuration.first ?? 1 * 60
        }
    }
}

fileprivate struct TimeUnitView: View {
    let value: Int
    let unit: String
    
    var body: some View {
        HStack {
            Text("\(value)")
                .font(.title)
                .foregroundStyle(.primary)
                .padding(4)
                .background(Color.secondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(unit)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    RestSyncView()
}

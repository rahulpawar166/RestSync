//
//  EventChecker.swift
//  RestSync
//
//  Created by Rahul Pawar on 1/20/25.
//

import EventKit
import AppKit

class EventChecker {
    
    static var shared = EventChecker()
    
    private let eventStore = EKEventStore()
    
    // Request calendar access
    func requestAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestFullAccessToEvents { granted, error in
            if let error = error {
                print("Error requesting calendar access: \(error.localizedDescription)")
                completion(false)
                return
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // Check if calendar access is granted
    func isCalendarAccessGranted() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        return status == .fullAccess
    }
    
    // Open System Calendar settings
    func openCalendarSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else {
            print("Unable to create URL for System Preferences")
            return
        }
        NSWorkspace.shared.open(url)
    }
    
    // Check if user is in a calendar event
    func isUserInCalendarEvent(at date: Date) -> Bool {
        // Ensure calendar access has been granted
        guard isCalendarAccessGranted() else {
            print("Calendar access not authorized.")
            return false
        }
        
        // Get events within a small window around the given date
        let startDate = date
        let endDate = date.addingTimeInterval(1) // 1-second range to ensure coverage
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        
        let events = eventStore.events(matching: predicate)
        return events.contains { !$0.isAllDay } // Exclude all-day events
    }
}

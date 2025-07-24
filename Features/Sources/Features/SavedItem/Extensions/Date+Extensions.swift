//
//  Date+Extensions.swift
//  STACK
//
//  Created by James Swent on 7/22/25.
//

import Foundation

extension Date {
    /// Returns a pretty formatted date string with ordinal suffix (e.g., "July 22nd, 2025")
    var prettyFormatted: String {
        let month = formatted(.dateTime.month(.wide))
        let day = Calendar.current.component(.day, from: self)
        let year = formatted(.dateTime.year())
        return "\(month) \(day)\(day.ordinalSuffix), \(year)"
    }
    
    /// Returns a relative formatted date string for recent dates, falls back to pretty format
    var relativePrettyFormatted: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            return "Today, \(formatted(.dateTime.hour().minute()))"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday, \(formatted(.dateTime.hour().minute()))"
        } else {
            let daysAgo = calendar.dateComponents([.day], from: self, to: now).day ?? 0
            if daysAgo < 7 { // Within a week
                let dayName = formatted(.dateTime.weekday(.wide))
                return "\(dayName), \(formatted(.dateTime.hour().minute()))"
            } else {
                return prettyFormatted
            }
        }
    }
}

extension Int {
    /// Returns the ordinal suffix for day numbers (st, nd, rd, th)
    var ordinalSuffix: String {
        let ones = self % 10
        let tens = (self / 10) % 10
        if tens == 1 { return "th" }
        switch ones {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}
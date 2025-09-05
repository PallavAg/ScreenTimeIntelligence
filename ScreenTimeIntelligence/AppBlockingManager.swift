//
//  AppBlockingManager.swift
//  ScreenTimeIntelligence
//
//  Created by Pallav Agarwal on 7/16/25.
//

import Foundation
import Combine
import FamilyControls
import ManagedSettings
import DeviceActivity

@MainActor
class AppBlockingManager: ObservableObject {
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private var unblockTimer: Timer?
    
    @Published var activitySelection = FamilyActivitySelection()
    @Published var isBlocking = false
    @Published var temporarilyUnblocked = false
    @Published var unblockEndTime: Date?
    
    func startBlocking() {
        // If we're temporarily unblocked, cancel the timer first
        if temporarilyUnblocked {
            unblockTimer?.invalidate()
            unblockTimer = nil
            temporarilyUnblocked = false
            unblockEndTime = nil
        }
        
        let applications = activitySelection.applicationTokens
        let categories = activitySelection.categoryTokens
        let webDomains = activitySelection.webDomainTokens
        
        store.shield.applications = applications.isEmpty ? nil : applications
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(categories, except: Set())
        store.shield.webDomains = webDomains.isEmpty ? nil : webDomains
        
        isBlocking = true
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let event = DeviceActivityEvent(
            applications: applications,
            categories: categories,
            webDomains: webDomains,
            threshold: DateComponents(minute: 0)
        )
        
        do {
            try center.startMonitoring(
                .daily,
                during: schedule,
                events: [.encouraged: event]
            )
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
    
    func stopBlocking() {
        store.clearAllSettings()
        center.stopMonitoring([.daily])
        isBlocking = false
        temporarilyUnblocked = false
        unblockEndTime = nil
        unblockTimer?.invalidate()
        unblockTimer = nil
    }
    
    func temporarilyUnblock(for minutes: Int) {
        guard isBlocking else { return }
        
        // Clear shields temporarily
        store.clearAllSettings()
        temporarilyUnblocked = true
        unblockEndTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        
        // Set timer to re-enable blocking
        unblockTimer?.invalidate()
        unblockTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.reapplyBlocking()
            }
        }
    }
    
    private func reapplyBlocking() {
        guard isBlocking else { return }
        
        let applications = activitySelection.applicationTokens
        let categories = activitySelection.categoryTokens
        let webDomains = activitySelection.webDomainTokens
        
        store.shield.applications = applications.isEmpty ? nil : applications
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(categories, except: Set())
        store.shield.webDomains = webDomains.isEmpty ? nil : webDomains
        
        temporarilyUnblocked = false
        unblockEndTime = nil
    }
}

extension DeviceActivityName {
    static let daily = Self("daily")
}

extension DeviceActivityEvent.Name {
    static let encouraged = Self("encouraged")
}
//
//  AuthorizationManager.swift
//  ScreenTimeIntelligence
//
//  Created by Pallav Agarwal on 7/16/25.
//

import Foundation
import Combine
import FamilyControls

@MainActor
class AuthorizationManager: ObservableObject {
    private let authorizationCenter = AuthorizationCenter.shared
    
    @Published var isAuthorized = false
    @Published var authorizationError: Error?
    
    init() {
        Task {
            await updateAuthorizationStatus()
        }
    }
    
    func requestAuthorization() async {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            await updateAuthorizationStatus()
        } catch {
            authorizationError = error
            print("Failed to request authorization: \(error.localizedDescription)")
        }
    }
    
    func updateAuthorizationStatus() async {
        switch authorizationCenter.authorizationStatus {
        case .approved:
            isAuthorized = true
        case .denied, .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
}
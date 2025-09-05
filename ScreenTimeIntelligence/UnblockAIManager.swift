//
//  UnblockAIManager.swift
//  ScreenTimeIntelligence
//
//  Created by Pallav Agarwal on 7/16/25.
//

import Foundation
import Combine
import FoundationModels

@Generable
struct UnblockResponse {
    @Guide(description: "A compassionate but firm response to the user's request to unblock apps")
    let message: String
    
    @Guide(description: "Number of minutes to unblock apps for (0 means don't unblock, max 60)")
    let unblockMinutes: Int
}

@MainActor
class UnblockAIManager: ObservableObject {
    private var session: LanguageModelSession?
    
    init() {
        setupSession()
    }
    
    private func setupSession() {
        session = LanguageModelSession(
            instructions: """
            You are a mindful digital wellness assistant helping users manage their screen time. 
            When users request to unblock apps, evaluate their reason compassionately but firmly.
            
            Guidelines:
            - For work/productivity reasons: Allow 15-30 minutes
            - For emergencies or important tasks: Allow 30-60 minutes  
            - For boredom or procrastination: Suggest 0-5 minutes or alternatives
            - For specific time-bound tasks: Match the time needed (max 60)
            - For sleep related tasks: Return 0 since they should go to sleep
            
            Always encourage mindful usage and suggest taking breaks.
            Keep responses brief (1-2 sentences) and supportive.
            """
        )
    }
    
    func evaluateUnblockRequest(_ reason: String) async throws -> UnblockResponse {
        guard let session = session else {
            throw UnblockError.sessionNotInitialized
        }
        
        let response = try await session.respond(
            to: "User wants to unblock apps for this reason: \(reason)",
            generating: UnblockResponse.self
        )
        
        return response.content
    }
}

enum UnblockError: LocalizedError {
    case sessionNotInitialized
    
    var errorDescription: String? {
        switch self {
        case .sessionNotInitialized:
            return "AI session not initialized"
        }
    }
}

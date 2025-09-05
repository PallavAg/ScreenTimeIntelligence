//
//  ContentView.swift
//  ScreenTimeIntelligence
//
//  Created by Pallav Agarwal on 7/16/25.
//

import SwiftUI
import FamilyControls

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthorizationManager
    @StateObject private var blockingManager = AppBlockingManager()
    @StateObject private var aiManager = UnblockAIManager()
    @State private var showAppPicker = false
    @State private var unblockReason = ""
    @State private var showUnblockDialog = false
    @State private var isProcessingAI = false
    @State private var aiResponse: UnblockResponse?
    @State private var showAIResponse = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if authManager.isAuthorized {
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("App Blocking")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Text(blockingManager.isBlocking ? "Active" : "Inactive")
                                    .font(.subheadline)
                                    .foregroundColor(blockingManager.isBlocking ? .green : .secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 40)
                        
                        VStack(spacing: 15) {
                            Button(action: {
                                showAppPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "app.badge.checkmark")
                                    Text("Select Apps to Block")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if !blockingManager.activitySelection.applicationTokens.isEmpty ||
                                !blockingManager.activitySelection.categoryTokens.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Apps That Will Be Blocked")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                        Text("\(blockingManager.activitySelection.applicationTokens.count) app, \(blockingManager.activitySelection.categoryTokens.count) categories")
                                            .font(.footnote)
                                    }
                                    .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal)
                        
                        if blockingManager.isBlocking {
                            VStack(spacing: 20) {
                                if blockingManager.temporarilyUnblocked, let endTime = blockingManager.unblockEndTime {
                                    // Temporarily unblocked state
                                    VStack(spacing: 15) {
                                        Image(systemName: "hourglass")
                                            .font(.system(size: 50))
                                            .foregroundColor(.orange)
                                            .symbolEffect(.pulse)
                                        
                                        Text("Apps Temporarily Unblocked")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                        
                                        Text("Reblocking at \(endTime, style: .time)")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                        
                                        Text("Time remaining: \(timeRemaining(until: endTime))")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                    .padding(30)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(20)
                                    .padding(.horizontal)
                                } else if showAIResponse, let response = aiResponse {
                                    // AI response state
                                    VStack(spacing: 20) {
                                        Image(systemName: "brain")
                                            .font(.system(size: 50))
                                            .foregroundColor(.blue)
                                            .symbolEffect(.bounce)
                                        
                                        Text("Apple Intelligence Says:")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                        
                                        Text(response.message)
                                            .font(.body)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                            .lineLimit(6)
                                        
                                        if response.unblockMinutes > 0 {
                                            VStack(spacing: 15) {
                                                Text("\(response.unblockMinutes) minutes offered")
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.blue)
                                                
                                                HStack(spacing: 20) {
                                                    Button(action: {
                                                        showAIResponse = false
                                                        aiResponse = nil
                                                    }) {
                                                        Text("Stay Focused")
                                                            .fontWeight(.medium)
                                                            .foregroundColor(.secondary)
                                                            .padding(.horizontal, 30)
                                                            .padding(.vertical, 15)
                                                            .glassEffect(.regular.tint(.gray).interactive())
                                                    }
                                                    
                                                    Button(action: {
                                                        blockingManager.temporarilyUnblock(for: response.unblockMinutes)
                                                        showAIResponse = false
                                                    }) {
                                                        Text("Accept")
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(.white)
                                                            .padding(.horizontal, 40)
                                                            .padding(.vertical, 15)
                                                            .glassEffect(.regular.tint(.blue).interactive())
                                                    }
                                                }
                                            }
                                        } else {
                                            Button(action: {
                                                showAIResponse = false
                                                aiResponse = nil
                                            }) {
                                                Text("OK")
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 50)
                                                    .padding(.vertical, 15)
                                                    .glassEffect(.regular.tint(.blue).interactive())
                                            }
                                        }
                                    }
                                    .padding(30)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(20)
                                    .padding(.horizontal)
                                } else {
                                    // Default blocking state - show unblock request form
                                    VStack(spacing: 10) {
                                        VStack(spacing: 15) {
                                            Image(systemName: "lock.circle.fill")
                                                .font(.system(size: 60))
                                                .symbolEffect(.pulse)
                                                .glassEffect(.regular.tint(.blue).interactive())
                                            
                                            Text("Apps are currently blocked")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .multilineTextAlignment(.center)
                                        }
                                        .padding(.top, 10)
                                        
                                        VStack(spacing: 15) {
                                            Text("Tell Apple Intelligence why you need to unblock your apps")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.center)
                                            
                                            VStack(spacing: 10) {
                                                TextField("", text: $unblockReason, prompt: Text("Enter your reason...").foregroundColor(.secondary), axis: .vertical)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(Color(.systemBackground))
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                                    )
                                                    .lineLimit(2...5)
                                                    .disabled(isProcessingAI)
                                                    .font(.body)
                                                
                                                if isProcessingAI {
                                                    HStack(spacing: 10) {
                                                        ProgressView()
                                                            .scaleEffect(0.8)
                                                        Text("Asking Apple Intelligence...")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    .padding(.top, 5)
                                                } else {
                                                    Button(action: {
                                                        if !unblockReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                            Task {
                                                                await processUnblockRequest()
                                                            }
                                                        }
                                                    }) {
                                                        HStack(spacing: 8) {
                                                            Image(systemName: "brain")
                                                                .font(.system(size: 16))
                                                            Text("Request Unblock")
                                                                .fontWeight(.semibold)
                                                        }
                                                        .foregroundColor(.white)
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.vertical, 16)
                                                        .glassEffect(.regular.tint(.blue).interactive())
                                                    }
                                                    .disabled(unblockReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                                    .padding(.top, 10)
                                                }
                                            }
                                        }
                                    }
                                    .padding(30)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color(.black).opacity(0.8))
                                            .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(.systemGray5), lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        Button(action: {
                            if blockingManager.isBlocking && !blockingManager.temporarilyUnblocked {
                                blockingManager.stopBlocking()
                                unblockReason = ""
                                showAIResponse = false
                                aiResponse = nil
                            } else {
                                blockingManager.startBlocking()
                                // Reset UI state when starting blocking (including from temporary unblock)
                                unblockReason = ""
                                showAIResponse = false
                                aiResponse = nil
                            }
                        }) {
                            Text(blockingManager.isBlocking && !blockingManager.temporarilyUnblocked ? "Stop Blocking Apps" : "Block Apps")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
//                                .background(blockingManager.isBlocking && !blockingManager.temporarilyUnblocked ? Color.red : Color.blue)
                                .glassEffect(.regular.tint(blockingManager.isBlocking && !blockingManager.temporarilyUnblocked ? .red : .blue).interactive())
                        }
                        .disabled(blockingManager.activitySelection.applicationTokens.isEmpty &&
                                  blockingManager.activitySelection.categoryTokens.isEmpty)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Screen Time Access Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This app needs permission to manage screen time restrictions.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            Task {
                                await authManager.requestAuthorization()
                            }
                        }) {
                            Text("Grant Permission")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .familyActivityPicker(isPresented: $showAppPicker, selection: $blockingManager.activitySelection)
    }
    
    private func processUnblockRequest() async {
        isProcessingAI = true
        
        do {
            let response = try await aiManager.evaluateUnblockRequest(unblockReason)
            aiResponse = response
            showAIResponse = true
            unblockReason = ""
        } catch {
            print("AI error: \(error)")
            aiResponse = UnblockResponse(
                message: "Unable to process request. Please try again.",
                unblockMinutes: 0
            )
            showAIResponse = true
        }
        
        isProcessingAI = false
    }
    
    private func timeRemaining(until date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        if interval <= 0 {
            return "0 minutes"
        }
        
        let minutes = Int(interval / 60)
        let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes) min \(seconds) sec"
        } else {
            return "\(seconds) seconds"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthorizationManager())
}

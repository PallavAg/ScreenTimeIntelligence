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
        NavigationView {
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
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if !blockingManager.activitySelection.applicationTokens.isEmpty ||
                               !blockingManager.activitySelection.categoryTokens.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Selected Items")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                        Text("\(blockingManager.activitySelection.applicationTokens.count) apps, \(blockingManager.activitySelection.categoryTokens.count) categories")
                                            .font(.footnote)
                                    }
                                    .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal)
                        
                        if blockingManager.temporarilyUnblocked, let endTime = blockingManager.unblockEndTime {
                            VStack(spacing: 10) {
                                Text("Temporarily Unblocked")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                Text("Reblocking at \(endTime, style: .time)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        if blockingManager.isBlocking && !blockingManager.temporarilyUnblocked {
                            Button(action: {
                                showUnblockDialog = true
                            }) {
                                Text("Request Temporary Unblock")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(15)
                            }
                            .padding(.horizontal)
                        }
                        
                        Button(action: {
                            if blockingManager.isBlocking {
                                blockingManager.stopBlocking()
                            } else {
                                blockingManager.startBlocking()
                            }
                        }) {
                            Text(blockingManager.isBlocking ? "Stop Blocking" : "Start Blocking")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(blockingManager.isBlocking ? Color.red : Color.blue)
                                .cornerRadius(15)
                        }
                        .disabled(blockingManager.activitySelection.applicationTokens.isEmpty && 
                                 blockingManager.activitySelection.categoryTokens.isEmpty)
                        .padding(.horizontal)
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
        .sheet(isPresented: $showUnblockDialog) {
            UnblockRequestView(
                reason: $unblockReason,
                isProcessing: $isProcessingAI,
                onSubmit: {
                    Task {
                        await processUnblockRequest()
                    }
                },
                onCancel: {
                    unblockReason = ""
                    showUnblockDialog = false
                }
            )
        }
        .alert("AI Decision", isPresented: $showAIResponse) {
            if let response = aiResponse {
                if response.unblockMinutes > 0 {
                    Button("Accept (\(response.unblockMinutes) min)") {
                        blockingManager.temporarilyUnblock(for: response.unblockMinutes)
                    }
                }
                Button("Cancel", role: .cancel) {
                    aiResponse = nil
                }
            }
        } message: {
            if let response = aiResponse {
                Text(response.message)
            }
        }
    }
    
    private func processUnblockRequest() async {
        isProcessingAI = true
        
        do {
            let response = try await aiManager.evaluateUnblockRequest(unblockReason)
            aiResponse = response
            showUnblockDialog = false
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
}

struct UnblockRequestView: View {
    @Binding var reason: String
    @Binding var isProcessing: Bool
    let onSubmit: () -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Why do you need to unblock your apps?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                TextField("Enter your reason...", text: $reason, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .focused($isFocused)
                    .disabled(isProcessing)
                    .padding(.horizontal)
                
                if isProcessing {
                    ProgressView("Evaluating request...")
                        .padding()
                }
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.red)
                    .disabled(isProcessing)
                    
                    Button("Submit") {
                        onSubmit()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                }
                .padding()
            }
            .navigationTitle("Unblock Request")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isFocused = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthorizationManager())
}

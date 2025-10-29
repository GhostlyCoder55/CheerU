//
//  CheerUp_App.swift
//  CheerUp!
//
//  Created by Christopher Ogbonnaya on 2025-01-14.
//

import SwiftUI

@main
struct CheerUp_App: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - Root View with Launch Screen
struct RootView: View {
    @State private var isShowingLaunchScreen = true
    
    var body: some View {
        ZStack {
            // Black background to prevent white flash
            Color.black
                .ignoresSafeArea()
            
            // Main content always present
            ContentView()
                .opacity(isShowingLaunchScreen ? 0 : 1)
                .zIndex(0)
            
            // Launch screen overlay
            if isShowingLaunchScreen {
                LaunchScreenView()
                    .zIndex(1)
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isShowingLaunchScreen = false
                }
            }
        }
    }
}

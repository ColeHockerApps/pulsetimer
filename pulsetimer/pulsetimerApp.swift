//
//  PulseTimerApp.swift
//  Pulse Timer
//
//  Created on 2025-10
//

import SwiftUI
import Combine
import Foundation

@main
public struct PulseTimerApp: App {

    @StateObject private var appState = AppState()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var haptics = HapticsManager()

    @Environment(\.scenePhase) private var scenePhase

    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    final class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication,
                         supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            if OrientationGate.allowAll {
                return [.portrait, .landscapeLeft, .landscapeRight]
            } else {
                return [.portrait]
            }
        }
    }
    
    
    public init() {
        
        NotificationCenter.default.post(name: Notification.Name("art.icon.loading.start"), object: nil)
        IconSettings.shared.attach()
        
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor.black
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = .white

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor.black
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().unselectedItemTintColor = UIColor(white: 1.0, alpha: 0.6)

        UISwitch.appearance().onTintColor = .systemCyan
        UIButton.appearance().tintColor = .white
    }

    public var body: some Scene {
        
        WindowGroup {
            TabSettingsView{
                TabRootView()
                    .environmentObject(appState)
                    .environmentObject(themeManager)
                    .environmentObject(haptics)
                    .preferredColorScheme(.dark)
                
                    .onAppear {
                                        
                        ReviewNudge.shared.schedule(after: 60)
                                 
                    }
                
            }
            
            .onAppear {
                OrientationGate.allowAll = false
            }
                
        }
        
        
        
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                appState.handleAppBecameActive()
            case .inactive:
                appState.handleAppWillResignActive()
            case .background:
                appState.handleAppEnteredBackground()
            @unknown default:
                break
            }
        }
        
        
        
    }
}

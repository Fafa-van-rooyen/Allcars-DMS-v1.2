//
//  Allcars_DMSApp.swift
//  Allcars DMS
//
//  Created by Fafa Van Rooyen on 2026/08/21.
//

import SwiftUI
import CoreData
import CloudKit
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting session: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: session.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let metadata = connectionOptions.cloudKitShareMetadata {
            accept(metadata)
        }
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith metadata: CKShare.Metadata
    ) {
        accept(metadata)
    }

    private func accept(_ metadata: CKShare.Metadata) {
        PersistenceController.shared.acceptShareInvitation(metadata) { error in
            if let error {
                print("CloudKit invitation failed:", error.localizedDescription)
            }
        }
    }
}

@main
struct All_CarsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(
                    \.managedObjectContext,
                    persistenceController.container.viewContext
                )
        }
    }
}

//
//  RsyncUIApp.swift
//
//  Created by Thomas Evensen on 12/01/2021.
//
// swiftlint:disable multiple_closures_with_trailing_closure

import OSLog
import SwiftData
import SwiftUI
import UserNotifications

@main
struct RsyncUIApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SynchronizeConfiguration.self,
                             UserConfiguration.self,
                             LogRecords.self])

        let storeURL = URL.documentsDirectory.appending(path: "rsyncui.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        Window("RsyncUI", id: "main") {
            RsyncUIView()
                .frame(minWidth: 1300, minHeight: 510)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            SidebarCommands()

            ExecuteCommands()

            SnapshotCommands()

            CommandGroup(replacing: .help) {
                Button(action: {
                    let documents: String = "https://rsyncui.netlify.app/"
                    NSWorkspace.shared.open(URL(string: documents)!)
                }) {
                    Text("RsyncUI help")
                }
            }

            AboutPanelCommand(
                title: "About RsyncUI",
                credits: "This app was created by SwiftUI and SwiftData\n https.//rsyncui.netlify.app"
            )
        }

        Settings {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }
    }

    func setusernotifications() {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        center.requestAuthorization(options: options) { granted, _ in
            if granted {
                // application.registerForRemoteNotifications()
            }
        }
    }
}

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let process = Logger(subsystem: subsystem, category: "process")
}

// swiftlint:enable multiple_closures_with_trailing_closure

//
//  AppSignerGuiApp.swift
//  AppSignerGui
//
//  Created by Axel Schwarz on 28.05.21.
//

import SwiftUI

@main
struct AppSignerGuiApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

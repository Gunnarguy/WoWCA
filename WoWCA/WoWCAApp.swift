//
//  WoWCAApp.swift
//  WoWCA
//
//  Created by Gunnar Hostetler on 8/13/25.
//

import SwiftUI

@main
struct WoWCAApp: App {
    @State private var vm: ItemSearchViewModel?

    init() {
        do {
            try DatabaseService.shared.configure()
            let repo = ItemRepository(dbQueue: DatabaseService.shared.dbQueue)
            _vm = State(initialValue: ItemSearchViewModel(repository: repo))
        } catch {
            print("DB init failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if let vm {
                RootView(vm: vm)
            } else {
                Text("Database failed to load").padding()
            }
        }
    }
}

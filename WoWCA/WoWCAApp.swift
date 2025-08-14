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
            _vm = State(initialValue: ItemSearchViewModel(dbQueue: DatabaseService.shared.dbQueue))
        } catch {
            print("DB init failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if let vm {
                SearchView(vm: vm)
            } else {
                Text("Database failed to load").padding()
            }
        }
    }
}

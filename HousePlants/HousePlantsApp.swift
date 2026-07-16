//
//  HousePlantsApp.swift
//  HousePlants
//
//  Created by Aryan Signh on 27/11/25.
//

import SwiftUI

@main
struct HousePlantsApp: App {
    init() {
        // AsyncImage reads/writes URLCache.shared. The default on-disk cache is small, so
        // remote plant images re-download on every scroll-past. Enlarge it once at launch.
        URLCache.shared = URLCache(memoryCapacity: 32 * 1024 * 1024,
                                   diskCapacity: 256 * 1024 * 1024)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

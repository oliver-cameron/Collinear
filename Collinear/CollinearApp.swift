//
//  CollinearApp.swift
//  Collinear
//
//  Created by Oliver Cameron on 3/12/2024.
//

import SwiftUI
import SwiftData

@main
struct CollinearApp: App {
//
//    var newModelContainer: ModelContainer = {
//        let schema = Schema([
//            Level.self,
//            nodeProtocol.self,
//            laser.self
//        ])
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//        
//        do {
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()

    var body: some Scene {
        WindowGroup {
            ContentView {
                var nodes: [node] = [
                    node(position: .init(x: 30, y: 500), target: .init(x: 2, y: 60), colour: "NodeRed"),
                    node(position: .init(x: 700, y: 200), target: .init(x: 50, y: 800), colour: "NodeYellow"),
                    node(position: .init(x: 30, y: 200), target: .init(x: 2, y: 700), colour: "NodeOrange"),
                    node(position: .init(x: 700, y: 500), target: .init(x: 50, y: 60), colour: "NodePurple")
                ]
                
                var lasers: [laser] = [
                    laser(p1: nodes[0], p2: nodes[1]),
                    laser(p1: nodes[2], p2: nodes[3]),
                ]
                var stickyIntersections: [stickyIntersection] = [
                    stickyIntersection(laser1: lasers[0], laser2: lasers[1])
                ]
                var anchors: [anchor] = [
                    anchor(position: .init(x: 500, y: 700))
                ]
                lasers.append( contentsOf: [
                    laser(p1: nodes[3], p2: anchors[0]),
                    laser(p1: stickyIntersections[0], p2: anchors[0])
                ]
                )
                return Level(nodes: nodes, lasers: lasers, bounds: CGRect(x: 0, y: 0, width: 1600, height: 900), anchors: anchors, stickyIntersections: stickyIntersections)
            }
        }
//        .modelContainer(newModelContainer)
    }
}

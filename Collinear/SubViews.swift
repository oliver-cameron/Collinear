//
//  SwiftUIView.swift
//  Collinear
//
//  Created by Oliver Cameron on 9/12/2024.
//

import SwiftUI

struct laserViews: View {
    let scalar: CGFloat
    let pos: CGPoint
    @Binding var lasers: [laser]
    @Binding var nodes: [node]
    var body: some View{
        ForEach(lasers, id: \.id) { laser in
            ZStack {
                let p1 = laser.p1.position * scalar + pos
                let p2 = laser.p2.position * scalar + pos
                let nodeBleeds: [LaserBleed] = laser.nodeBleed(nodes)
                // Laser line path (including glow)
                Path { path in
                    path.move(to: p1)
                    path.addLine(to: p2)
                }
                .stroke(.white, style: .init(lineWidth: 15 * scalar, lineCap: .round))
                .stroke(.white.opacity(0.5), style: .init(lineWidth: 30 * scalar, lineCap: .round))
                .shadow(color: .white, radius: 75)
                .compositingGroup()
                .zIndex(0) // Ensure it's behind any bleeds, if needed
                
                // Node Bleeds (rendered above laser lines)
                ForEach(nodeBleeds, id: \.id) { bleed in
                    let start = bleed.position1 * scalar + pos
                    let end = bleed.position2 * scalar + pos
                    let color = bleed.colour
                    
                    Path { path in
                        path.move(to: start)
                        path.addLine(to: end)
                    }
                    .stroke(color, style: .init(lineWidth: 30 * scalar, lineCap: .butt))
                    .blendMode(.multiply)
                    .compositingGroup() // Ensure bleed doesn't affect others
                    .zIndex(1) // Make sure bleeds are above the laser path
                }
            }
        }
    }
}
struct nodeViews: View{
    let scalar: CGFloat
    let pos: CGPoint
    
    let levelBounds: CGRect
    @Binding var nodes: [node]
    @Binding var lasers: [laser]
    var updateNodes: () -> Void
    var body: some View{
        ForEach(nodes) { node in
            let nodeColor = Color(node.colour)
            let nodeTarget = node.target * scalar + pos
            let nodePosition = node.position * scalar + pos
            
            Hexagon()
                .fill(nodeColor)
                .frame(width: 60 * scalar, height: 60 * scalar)
                .position((nodeTarget + pos) * scalar)
            
            ZStack {
                Circle()
                    .frame(width: 60 * scalar, height: 60 * scalar)
                    .foregroundColor(nodeColor)
                
                StrokeShapeView(shape: .circle, style: .white, strokeStyle: .init(lineWidth: 6 * scalar), isAntialiased: true, background: EmptyView())
                    .frame(width: 36 * scalar, height: 36 * scalar)
            }
            .position(nodePosition)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let newPosition = (value.location - pos) / scalar
                    //print(value,newPosition.isWithin(bounds: level.bounds))
                    if newPosition.isWithin(bounds: levelBounds) {
                        withAnimation {
                            node.position = newPosition
                        }
                        //                        print(node.position,newPosition)
                    }
                    for node in nodes {
                        if node.checkDie(allLasers: &lasers) {
                            // Handle node death (if applicable)
                        }
                    }
                }
                .onEnded({ value in
                    let newPosition = (value.location - pos) / scalar
                    if newPosition.isWithin(bounds: levelBounds) {
                        node.position = newPosition
                        print(node.position,newPosition)
                    }
                })
            )
        }
    }
}

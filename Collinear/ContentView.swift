//
//  ContentView.swift
//  Collinear
//
//  Created by Oliver Cameron on 3/12/2024.
//

import SwiftUI
import SwiftData
import AVKit
struct ContentView: View {
    init(_ clevel: @escaping () -> Level) {
        level = clevel()
    }
    @State private var level: Level
    @State private var isShaking = true // State to trigger screen shake
    
    var body: some View {
        
        ZStack {
            Rectangle()
                .fill(Color.black.mix(with: Color.white, by: 0.2))
                .ignoresSafeArea()
            let levelBounds = level.bounds
            let lasers: [laser] = level.lasers
            let nodes: [node] = level.nodes
            let anchors = level.anchors
            let stickyIntersections = level.stickyIntersections
            VStack{
                GeometryReader { geometry in
                    let pos = geometry.frame(in: .local).origin
                    let scalar = geometry.size.width / levelBounds.width
                    ZStack {
                        Rectangle()
                        ZStack {
                            // Background Color or other content
                            Rectangle()
                                .frame(idealWidth: levelBounds.width, idealHeight: levelBounds.height)
                                .foregroundColor(.black)
                            
                            // Lasers (Laser path + node bleeds)
                            laserViews(lasers: lasers, nodes: nodes, pos: pos, scalar: scalar)
                            
                            // Sticky Intersections
                            stickyIntersectionViews(stickyIntersections: stickyIntersections, pos: pos, scalar: scalar)
                            
                            // Nodes
                            nodeViews(nodes: nodes, pos: pos, scalar: scalar)
                            
                            // Anchors
                            anchorViews(anchors: anchors, pos: pos, scalar: scalar)
                        }
                    }
                    .frame(idealWidth: levelBounds.width, idealHeight: levelBounds.height)
                    .scaledToFit()
                    .screenShake(ison: $isShaking, duration: 1)
                    .animation(.easeInOut(duration: 0.1), value: isShaking)
                }
            }
            .padding()
        }
    }
    private func updateNodes() {
    }
    
    private func laserViews(lasers: [laser], nodes: [node], pos: CGPoint, scalar: CGFloat) -> some View {
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
                .stroke(.white, style: .init(lineWidth: 10 * scalar, lineCap: .round))
                .stroke(.white.opacity(0.5), style: .init(lineWidth: 20 * scalar, lineCap: .round))
                .shadow(color: .white, radius: 50)
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
                    .stroke(color, style: .init(lineWidth: 20 * scalar, lineCap: .butt))
                    .blendMode(.multiply)
                    .compositingGroup() // Ensure bleed doesn't affect others
                    .zIndex(1) // Make sure bleeds are above the laser path
                }
            }
        }
    } 
    private func stickyIntersectionViews(stickyIntersections: [stickyIntersection], pos: CGPoint, scalar: CGFloat) -> some View {
        ForEach(level.stickyIntersections, id: \.id) { intersection in
            let disCenter: CGFloat = 50
            let center: CGPoint = (intersection.position + pos) * scalar
            let o1 = CGPoint(x: CGFloat(cos(intersection.laser1.slope())) * disCenter, y: CGFloat(sin(intersection.laser1.slope())) * disCenter)*scalar
            let o2 = CGPoint(x: CGFloat(cos(intersection.laser2.slope())) * disCenter, y: CGFloat(sin(intersection.laser2.slope())) * disCenter)*scalar
            let p1 = center + o1
            let p2 = center + o2
            let p3 = center - o1
            let p4 = center - o2
            let q1 = center + o1 + o2
            let q2 = center + o2 - o1
            let q3 = center - o1 - o2
            let q4 = center - o2 + o1
            Path { path in
                path.move(to: p1)
//                path.addArc(center: c1, radius:r1, startAngle: Angle(radians: intersection.laser1.slope() - Double.pi  / 2), endAngle: Angle(radians: intersection.laser2.slope() + Double.pi / 2), clockwise: clockwise)
//                path.addArc(center: c2, radius: r2, startAngle: Angle(radians: intersection.laser2.slope() - Double.pi / 2), endAngle: Angle(radians: intersection.laser1.slope() - Double.pi  / 2), clockwise: clockwise)
                path.addQuadCurve(to: p2, control: avg(avg(center,q1),center))
                path.addQuadCurve(to: p3, control: avg(avg(center,q2),center))
                path.addQuadCurve(to: p4, control: avg(avg(center,q3),center))
                path.addQuadCurve(to: p1, control: avg(avg(center,q4),center))
                path.closeSubpath()
            }
            .fill(Color("IntersectionGreen"))
            .stroke(Color("IntersectionGreen") ,style: StrokeStyle(lineWidth: 30 * scalar, lineCap: .round, lineJoin: .round))
            Circle()
                .frame(width: 40 * scalar, height: 40 * scalar)
                .foregroundStyle(.white.opacity(0.5))
                .position(center)
        }
    }
    
    private func nodeViews(nodes: [node], pos: CGPoint, scalar: CGFloat) -> some View {
        ForEach(nodes) { node in
            let nodeColor = Color(node.colour)
            let nodeTarget = node.target * scalar + pos
            let nodePosition = node.position * scalar + pos
            
            Hexagon()
                .fill(nodeColor)
                .frame(width: 40 * scalar, height: 40 * scalar)
                .position((nodeTarget + pos) * scalar)
            
            ZStack {
                Circle()
                    .frame(width: 40 * scalar, height: 40 * scalar)
                    .foregroundColor(nodeColor)
                
                StrokeShapeView(shape: .circle, style: .white, strokeStyle: .init(lineWidth: 4 * scalar), isAntialiased: true, background: EmptyView())
                    .frame(width: 24 * scalar, height: 24 * scalar)
            }
            .position(nodePosition)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let newPosition = (value.location - pos) / scalar
                    
                    if newPosition.isWithin(bounds: level.bounds) {
                        node.position = newPosition
                    }
                    for node in nodes {
                        if node.checkDie(allLasers: &level.lasers) {
                            // Handle node death (if applicable)
                        }
                    }
                })
        }
    }
    
    private func anchorViews(anchors: [anchor], pos: CGPoint, scalar: CGFloat) -> some View {
        ForEach(anchors, id: \.id) { anchor in
            Circle()
                .frame(width: 30 * scalar, height: 30 * scalar)
                .foregroundColor(.white)
                .position(anchor.position * scalar + pos)
        }
    }
}

#Preview {
    ContentView {
        var nodes: [node] = [
            node(position: .init(x: 30, y: 500), target: .init(x: 350, y: 60), colour: "NodeRed"),
            node(position: .init(x: 700, y: 200), target: .init(x: 50, y: 800), colour: "NodeYellow"),
            node(position: .init(x: 30, y: 200), target: .init(x: 200, y: 700), colour: "NodeOrange"),
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

extension CGPoint:@retroactive _VectorMath{
    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        
        return .init(x: lhs.x - rhs.x ,y: lhs.y - rhs.y)
    }
    
    public mutating func scale(by rhs: Double) {
        x *= rhs
        y *= rhs
    }
    
    public var magnitudeSquared: Double {
        x * x + y * y
    }
    
    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return .init(x: lhs.x + rhs.x ,y: lhs.y + rhs.y)
    }
    
    func isWithin(bounds: CGRect) -> Bool{
        return x >= bounds.minX + 30 && x <= bounds.maxX - 30 && y >= bounds.minY + 30 && y <= bounds.maxY - 30
    }
}
struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.size.height, rect.size.width) / 2
        let corners = corners(center: center, radius: radius)
        path.move(to: corners[0])
        corners[1...5].forEach() { point in
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
    
    func corners(center: CGPoint, radius: CGFloat) -> [CGPoint] {
        var points: [CGPoint] = []
        for i in (0...5) {
            let angle = CGFloat.pi / 3 * CGFloat(i)
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            points.append(point)
        }
        return points
    }
}
struct ScreenShake: ViewModifier {
    @State private var offsetX: CGFloat = 0  // Horizontal offset
    @State private var offsetY: CGFloat = 0  // Vertical offset
    @State private var shakeTimer: Timer? // Timer to periodically update the shake offsets
    @State private var shakeEndTimer: Timer?  // Timer to stop the shake after duration
    @Binding var isOn: Bool
    @State private var shakeIntensity: CGFloat = 5
    let duration: Double
    func body(content: Content) -> some View {
        content
            .offset(x: offsetX, y: offsetY) // Apply both X and Y offsets
            .onChange(of: isOn, initial: false){o,n in
                if o {
                    startShake()
                } else {
                    stopShake()
                }
            }
            .onAppear {
                startShake()
                
                // Stop the shake after the duration
                shakeEndTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                    stopShake()  // Stop shake after duration
                }
            }
            .onDisappear {
                // Invalidate the timer when the view disappears
                stopShake()
            }
            .animation(.easeInOut(duration: 0.1), value: shakeIntensity)
    }
    
    // Method to start shaking and periodically change the shake direction
    func startShake() {
        // Start a timer that will update the shake offset periodically
        shakeTimer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { _ in
            // Randomly generate new offsets
            offsetX = CGFloat.random(in: -shakeIntensity...shakeIntensity)
            offsetY = CGFloat.random(in: -shakeIntensity...shakeIntensity)
        }
    }
    
    // Method to stop shaking
    func stopShake() {
        isOn = false
        shakeIntensity = 0
    }
}


extension View {
    func screenShake(ison: Binding<Bool>, duration: Double = 1) -> some View {
        self.modifier(ScreenShake(isOn: ison, duration: duration))
    }
}
func yIntercept(slope: CGFloat, point: CGPoint) -> CGFloat{
    return -slope * point.x + point.y
}
func lineIntersection(slope1: CGFloat, yIntercept1: CGFloat, slope2: CGFloat, yIntercept2: CGFloat) -> CGPoint{
    let x = (yIntercept2 - yIntercept1)/(slope1 - slope2)
    let y = slope1 * x + yIntercept1
    return CGPoint(x: x, y: y)
}
func avg(_ input: CGPoint...) -> CGPoint{
    var ret: CGPoint = .zero
    input.forEach{ ret += $0 }
    return ret / CGFloat(input.count)
}


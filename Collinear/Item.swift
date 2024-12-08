//
//  Item.swift
//  Collinear
//
//  Created by Oliver Cameron on 3/12/2024.
//

import Foundation
import SwiftData
import SwiftUI
@Model
final class Level {
    var nodes: [node]
    var lasers: [laser]
    var bounds: CGRect
    var anchors: [anchor]
    var stickyIntersections: [stickyIntersection]
    init(nodes: [node], lasers: [laser], bounds: CGRect, anchors: [anchor], stickyIntersections: [stickyIntersection]){
        self.nodes = nodes
        self.lasers = lasers
        self.bounds = bounds
        self.anchors = anchors
        self.stickyIntersections = stickyIntersections
    }
}
@Model
class nodeProtocol{
    var position: CGPoint // Add this line
    var colour: String
    init(position: CGPoint, colour: String) {
        self.position = position // Add this line
        self.colour = colour
    }
}
class node: nodeProtocol{
    var target: CGPoint
    private func connectedLasers(_ allLasers: [laser]) -> [laser]{
        return (allLasers.filter{$0.otherNode(self) != nil})
    }
    private func disconnectedLasers(_ allLasers: [laser]) -> [laser]{
        return (allLasers.filter{$0.otherNode(self) == nil})
    }
    func checkDie(allLasers: inout [laser]) -> Bool{
        let disconnectedLasers = disconnectedLasers(allLasers)
        let ret = disconnectedLasers.map{$0.closestPoint(to: self).1 < 30}.reduce(false){ $0 || $1 }
//        if(ret){
//            for laser in connectedLasers(allLasers){
//                allLasers.removeAll{$0.id == laser.id}
//            }
//        }
        return ret
    }
    init(position: CGPoint, target: CGPoint, colour: String) {
        self.target = target
        super.init(position: position, colour: colour)
    }
    required init(backingData: any BackingData<nodeProtocol>) {
        let backingData = backingData as! node
        self.target = backingData.target
        super.init(position: backingData.position, colour: backingData.colour)
    }
}
class anchor: nodeProtocol{
    init(position: CGPoint){
        super.init(position: position, colour: "Anchor")
    }
    required init(backingData: any SwiftData.BackingData<nodeProtocol>) {
        let backingData = backingData as! anchor
        super.init(position: backingData.position, colour: "Anchor")
    }
}
class stickyIntersection: nodeProtocol{
    var laser1: laser
    var laser2: laser
    private var _position: CGPoint?
    override var position: CGPoint {
        get {
            // If position is manually set, return that value
            // If not manually set, compute the position from the intersection of lasers
            let po1 = laser1.p1.position
            let po2 = laser1.p2.position
            let po3 = laser2.p1.position
            let po4 = laser2.p2.position
            
            // Slopes (m1 and m2) of the two lines
            let m1 = (po1.y - po2.y) / (po1.x - po2.x)
            let m2 = (po3.y - po4.y) / (po3.x - po4.x)
            
            // Y-intercepts (c1 and c2)
            let c1 = po1.y - m1 * po1.x
            let c2 = po3.y - m2 * po3.x
            
            // Calculate the intersection point (x, y)
            let x = (c2 - c1) / (m1 - m2)
            let y = m1 * x + c1
            
            return CGPoint(x: x, y: y)
        }
        set {
            // Allow manual setting of position
            _position = newValue
        }
    }
    init(laser1: laser, laser2: laser){
        self.laser1 = laser1
        self.laser2 = laser2
        super.init(position: .zero, colour: "IntersectionGreen")
    }
    required init(backingData: any SwiftData.BackingData<nodeProtocol>) {
        let backingData = backingData as! stickyIntersection
        self.laser1 = backingData.laser1
        self.laser2 = backingData.laser2
        super.init(position: backingData.position, colour: "IntersectionGreen")
    }
}
@Model
class laser: Identifiable{
    var id: UUID
    var p1: nodeProtocol
    var p2: nodeProtocol
    func otherNode(_ target: nodeProtocol) -> (nodeProtocol)?{
        switch target.id {
        case p1.id:
            return p2
        case p2.id:
            return p1
        default:
            return nil
        }
    }
    var length: CGFloat{
        return sqrt(pow(p1.position.x - p2.position.x, 2) + pow(p1.position.y - p2.position.y, 2))
    }
    func nodeBleed(_ allNodes: [nodeProtocol]) -> [LaserBleed]{
        let bleedDistance: CGFloat = 200
        var returner : [LaserBleed] = []
        for tnode in allNodes{

                if(otherNode(tnode) == nil){
                    if(tnode.colour == "IntersectionGreen"){
                        for i in 0...3{
                            returner.append(LaserBleed(
                                lerp(a:p1.position,b:p2.position,i: closestPoint(to: tnode).0 + (CGFloat(i)/12)/length*bleedDistance),
                                lerp(a:p1.position,b:p2.position,i: closestPoint(to: tnode).0 + (CGFloat(i - 1)/12)/length*bleedDistance),
                                Color(tnode.colour).opacity(Double(3 - i + 1)/Double(10)))
                            )
                            returner.append(LaserBleed(
                                lerp(a:p1.position,b:p2.position,i: closestPoint(to: tnode).0 - (CGFloat(i)/12)/length*bleedDistance),
                                lerp(a:p1.position,b:p2.position,i: closestPoint(to: tnode).0 - (CGFloat(i - 1)/12)/length*bleedDistance),
                                Color(tnode.colour).opacity(Double(3 - i + 1)/Double(10)))
                            )
                        }
                    } else{
                        if(closestPoint(to: tnode).1 > 60){
                            let it = Int(240 / closestPoint(to: tnode).1)
                            for i in 0...it{
                                returner.append(LaserBleed(
                                    lerp(a:p1.position,b:p2.position,i: closestPoint(to: tnode).0 + (CGFloat(i)/12)/length*bleedDistance),
                                    lerp(a:p1.position,b:p2.position,i: closestPoint(to: tnode).0 + (CGFloat(i - 1)/12)/length*bleedDistance),
                                    Color(tnode.colour).opacity(Double(it - i + 1)/Double(20)))
                                )
                                returner.append(LaserBleed(
                                    lerp(a:p1.position,b:p2.position,i: closestPoint(to: tnode).0 - (CGFloat(i)/12)/length*bleedDistance),
                                    lerp(a:p1.position,b:p2.position,i: closestPoint(to: tnode).0 - (CGFloat(i - 1)/12)/length*bleedDistance),
                                    Color(tnode.colour).opacity(Double(it - i + 1)/Double(20)))
                                )
                            }
                        }
                        
                        else{
                            return [LaserBleed(
                                p1.position,
                                p2.position,
                                Color(tnode.colour)
                            )]
                        }
                    }
                }
                else if tnode.id == p1.id{
                    for i in 1...8{
                        returner.append(LaserBleed(
                            lerp(a: p1.position, b: p2.position, i: (CGFloat(i - 1) / 12) / length * bleedDistance),
                            lerp(a: p1.position, b: p2.position, i:( CGFloat(i) / 12) / length * bleedDistance),
                            Color(tnode.colour).opacity(Double(9-i)/Double(8))
                        ))
                    }
                } else{
                    
                    for i in 1...8{
                        returner.append(LaserBleed(
                            lerp(a: p2.position, b: p1.position, i: (CGFloat(i - 1) / 12) / length * bleedDistance),
                            lerp(a: p2.position, b: p1.position, i: (CGFloat(i) / 12) / length * bleedDistance),
                            Color(tnode.colour).opacity(Double(9-i)/Double(8))
                        ))
                    }
                }
            
        }
        return returner
    }
    func closestPoint(to target: nodeProtocol) -> (CGFloat,CGFloat){
        let g = (p1.position.y - p2.position.y)/(p1.position.x - p2.position.x)
        let b = p1.position.y - g * p1.position.x
        let rg = -1/g
        let rb = target.position.y - rg * target.position.x
        let p3x = (rb - b) / (g - rg)
        let p3y = rg * p3x + rb
        let t = rlerp(a: p1.position.x, b: p2.position.x, i: p3x)
        var t2: CGFloat = 0
        var d: CGFloat = 0
        if(t < 0){
            t2 = 0
            d = sqrt(pow(p1.position.x - target.position.x, 2) + pow(p1.position.y - target.position.y, 2))
        } else if(t > 1){
             t2 = 1
             d = sqrt(pow(p2.position.x - target.position.x, 2) + pow(p2.position.y - target.position.y, 2))
        } else{
             t2 = t
             d = sqrt(pow(p3x - target.position.x, 2) + pow(p3y - target.position.y, 2))
        }
        return(t2,d)
    }
    init(id: UUID = .init(), p1:nodeProtocol, p2: nodeProtocol){
        self.id = id
        self.p1 = p1
        self.p2 = p2
    }
    deinit{
        
    }
}

func lerp(a: CGFloat ,b: CGFloat ,t: CGFloat) -> CGFloat{
    return a + (b - a) * t
}
func lerp(a: CGPoint ,b: CGPoint ,i: CGFloat) -> CGPoint{
    let x = lerp(a: a.x ,b: b.x ,t: i)
    let y = lerp(a: a.y ,b: b.y ,t: i)
    return CGPoint(x: x ,y: y)
}
func rlerp(a: CGFloat ,b: CGFloat ,i: CGFloat) -> CGFloat{
    return (i-a) / (b-a)
}
func rlerp(a: CGPoint ,b: CGPoint ,i: CGFloat) -> CGPoint{
    let x = rlerp(a: a.x ,b: b.x ,i: i)
    let y = rlerp(a: a.y ,b: b.y ,i: i)
    return CGPoint(x: x ,y: y)
}
struct LaserBleed: Identifiable{
    let id = UUID()
    var position1: CGPoint
    var position2: CGPoint
    var colour: Color
    init(_ position1: CGPoint, _ position2: CGPoint, _ colour: Color){
        self.position1 = position1
        self.position2 = position2
        self.colour = colour
    }
}
extension laser{
    func slope() -> Double{
        return atan(Double((p1.position.y - p2.position.y) / (p1.position.x - p2.position.x)))
    }
}


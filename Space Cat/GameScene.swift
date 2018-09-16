//
//  GameScene.swift
//  Space Cat
//
//  Created by codebendr on 24/08/2018.
//  Copyright © 2018 just pixel. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreGraphics

var projectileSpeed:CGFloat = 400

//struct CollisionCategory : OptionSet {
//    let rawValue: UInt32
//
//    static let Enemy  = CollisionCategory(rawValue: 1 << 0) //0000
//    static let Projectile = CollisionCategory(rawValue: 1 << 1) //0010
//    static let Debris  = CollisionCategory(rawValue: 1 << 2) //0100
//    static let Ground  = CollisionCategory(rawValue: 1 << 3) //1000
//
//    func bitmask() -> UInt32 {
//        return self.rawValue
//    }
//}

struct Collision {
    
    enum Detect: Int {
        case enemy, projectile, debris, ground
        var bitmask: UInt32 { return 1 << self.rawValue }
    }
    
    let bodies: (first: UInt32, second: UInt32)
    
    func detect (_ first: Detect, _ second: Detect) -> Bool {
        return (first.bitmask == bodies.first && second.bitmask == bodies.second) ||
            (first.bitmask == bodies.second && second.bitmask == bodies.first)
    }
}

class GameScene: SKScene {
    
    var spaceCatNode: SKSpriteNode?
    var machineNode: SKSpriteNode?
    var spaceCatAction: SKAction?
    
    var spaceDogNodeA: SKSpriteNode?
    var spaceDogNodeB: SKSpriteNode?


    //first function called when game is run
    override func didMove(to view: SKView) {
        
        let background = childNode(withName: "background") as! SKSpriteNode
        background.zPosition = -1
        
        if let machine = machine() {
            machine.name = "machine"
            self.machineNode = machine
        }
        
        
        if let spaceCatNode = spaceCat().node {
            spaceCatNode.name = "spaceCat"
            self.spaceCatNode = spaceCatNode
        }
        
        spaceCatAction = spaceCat().action
        
        if let spaceDogNodeA = spaceDog(type: .A) {
            self.spaceDogNodeA = spaceDogNodeA
        }
        
        if let spaceDogNodeB = spaceDog(type: .B) {
            self.spaceDogNodeB = spaceDogNodeB
        }
        
        ground(size: CGSize(width: self.frame.width, height: 22))
        
        //earths gravity Y -> -9.8
        //self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
        
        // Set the scale mode to scale to fit the window
        self.scaleMode = .aspectFill
        
    }
    
    override func update(_ currentTime: TimeInterval) {
    }
    
}

//MARK: Machine
extension GameScene {
    
    func machine () -> SKSpriteNode? {
        
        let spriteNode = childNode(withName: "machine") as? SKSpriteNode
        let textures = [SKTexture(imageNamed: "machine_1"), SKTexture(imageNamed: "machine_2")]
        let animate = SKAction.animate(with: textures, timePerFrame: 0.1)
        let action = SKAction.repeatForever(animate)
        
        if let spriteNode = spriteNode {
            spriteNode.run(action)
        }
        
        return spriteNode
    }
    
    
}

//MARK: Space Cat
extension GameScene {

    func spaceCat () -> (node: SKSpriteNode?, action: SKAction) {
        
        let spriteNode = childNode(withName: "spacecat") as? SKSpriteNode
        let textures = [SKTexture(imageNamed: "spacecat_2"), SKTexture(imageNamed: "spacecat_1")]
        let action = SKAction.animate(with: textures, timePerFrame: 0.25)
        return (spriteNode,action)
        
    }
    
    func action (position: CGPoint) -> (fire: SKAction, fade: SKAction) {
        let slope = ( position.y - self.position.y ) / (position.x - self.position.x)
        
        var offScreenX:CGFloat
        
        if( position.x <= self.position.x ) {
            //get left section of screen
            offScreenX = -self.frame.width + 10
        } else {
            //get right section of screen
            offScreenX = self.frame.width + 10
        }
        
        let offScreenY = slope * offScreenX - slope * self.position.x + self.position.y
        let pointOffScreen = CGPoint(x: offScreenX, y: offScreenY)
        
        let distanceA = (pointOffScreen.y - self.position.y)
        let distanceB = -(pointOffScreen.x - self.position.x)
        
        let distanceC = CGFloat(sqrtf(powf(Float(distanceA), 2) + powf(Float(distanceB), 2)))
        
        // distance = speed * time
        //time = distance / speed
        
        let time:CGFloat = distanceC / projectileSpeed
        let waitToFade = time * 0.75
        let fadeTime = time - waitToFade
        
        let sequence:[SKAction] = [SKAction.wait(forDuration: TimeInterval(waitToFade)),SKAction.fadeOut(withDuration: TimeInterval(fadeTime)),SKAction.removeFromParent()]
        
        return (SKAction.move(to: pointOffScreen, duration: TimeInterval(time)),SKAction.sequence(sequence))
        
    }
    
}

// MARK: Projectile
extension GameScene {
    
    func projectile () -> (node: SKSpriteNode?, action: SKAction) {
        
        let spriteNode = SKSpriteNode(imageNamed: "projectile_1")
        spriteNode.name = "projectile"
        spriteNode.zPosition = 3
        let textures : Array<SKTexture> = (1...3).map({ return "projectile_\($0)"}).map(SKTexture.init)
        let animate = SKAction.animate(with: textures, timePerFrame: 0.25)
        let action = SKAction.repeatForever(animate)
        spriteNode.physicsBody = SKPhysicsBody(rectangleOf: spriteNode.size)
        
        if let physicsBody = spriteNode.physicsBody {
            physicsBody.affectedByGravity = false
            physicsBody.categoryBitMask = Collision.Detect.projectile.bitmask
            physicsBody.collisionBitMask = 0
            physicsBody.contactTestBitMask = Collision.Detect.enemy.bitmask
        }
        
        return (spriteNode,action)
        
    }
}

//MARK: Space Dog
extension GameScene {
    
    enum SpaceDogType:Int {
        case A
        case B
    }
    
    func spaceDog(type: SpaceDogType) -> SKSpriteNode? {
        
        let _spriteNode = childNode(withName: "spacedog_A") as? SKSpriteNode
        guard var spriteNode = _spriteNode else { return nil }
        
        var textures : Array<SKTexture>
        
        switch type {
        case .A:
            textures = (1...3).map({ return "spacedog_A_\($0)"}).map(SKTexture.init)
        case .B:
            spriteNode = childNode(withName: "spacedog_B") as! SKSpriteNode
            textures = (1...4).map({ return "spacedog_B_\($0)"}).map(SKTexture.init)
        }
        
        let animate = SKAction.animate(with: textures, timePerFrame: 0.1)
        let action = SKAction.repeatForever(animate)
        
        if let physicsBody = spriteNode.physicsBody {
            physicsBody.categoryBitMask = Collision.Detect.enemy.bitmask
            physicsBody.collisionBitMask = 0
            physicsBody.contactTestBitMask = Collision.Detect.projectile.bitmask | Collision.Detect.ground.bitmask
        }
        
        spriteNode.run(action)
        return spriteNode
    }
    
}

//MARK: Ground
extension GameScene {
    
    func ground(size: CGSize){
        let ground = SKSpriteNode(color: .green, size: size)
        ground.name = "ground"
        ground.physicsBody = SKPhysicsBody(rectangleOf: size)
        ground.position = CGPoint(x: 0, y: -self.frame.maxY)
        guard let physicsBody = ground.physicsBody else {return}
        physicsBody.affectedByGravity = false
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = Collision.Detect.ground.bitmask
        physicsBody.collisionBitMask = Collision.Detect.debris.bitmask
        physicsBody.contactTestBitMask = Collision.Detect.enemy.bitmask
        
        addChild(ground)
    }
    
}

//MARK: Debris
extension GameScene {
    
    func debris(position: CGPoint) {
        
        for _ in 1...Int.random(in: 5...20) {
            let spriteNode = SKSpriteNode(imageNamed: "debri_\(Int.random(in: 1...3))")
            spriteNode.name = "debris"
            spriteNode.position = position
            spriteNode.physicsBody = SKPhysicsBody(rectangleOf: spriteNode.size)
            
            if let physicsBody = spriteNode.physicsBody {
                physicsBody.affectedByGravity = false
                physicsBody.categoryBitMask = Collision.Detect.debris.bitmask
                physicsBody.collisionBitMask = Collision.Detect.ground.bitmask | Collision.Detect.debris.bitmask
                physicsBody.contactTestBitMask = 0
          
                let dx = Double(Int.random(in: -150...(-10)))
                let dy = Double(Int.random(in: -350...(-150)))
                physicsBody.velocity = CGVector(dx:dx , dy: dy)
            }
            
            addChild(spriteNode)
            
            spriteNode.run(SKAction.wait(forDuration: 2)){
                spriteNode.removeFromParent()
            }
        
        }
    }
}

//MARK: Touches
extension GameScene {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let spaceCatNode = spaceCatNode else {return}
        guard let spaceCatAction = spaceCatAction else {return}
        
        spaceCatNode.run(spaceCatAction)
        
        for touch in touches {
            let position = touch.location(in: self)
            
            if let projectileNode = projectile().node {
                addChild(projectileNode)
                if let machineNode = machineNode{
                    projectileNode.position = CGPoint(x: machineNode.position.x, y: -(machineNode.frame.size.height)-10)
                }
                projectileNode.run(projectile().action)
                projectileNode.run(action(position: position).fire)
                projectileNode.run(action(position: position).fade)
            }
            
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
}

// MARK: SKPhysicsContactDelegate
extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {

        let collision = Collision(bodies: (first: contact.bodyA.categoryBitMask, second: contact.bodyB.categoryBitMask))
        
        if collision.detect(.enemy,.projectile) {
            
            if let enemy = contact.bodyA.node {
                if contact.bodyA.node?.name == "spacedog_A" || contact.bodyA.node?.name == "spacedog_B" {
                     enemy.removeFromParent()
                }
            }
            
            if contact.bodyB.node?.name == "projectile", let projectile = contact.bodyB.node {
                projectile.removeFromParent()
            }
        }
        
        if collision.detect(.enemy, .ground) {
            
            if let enemy = contact.bodyA.node {
                if contact.bodyA.node?.name == "spacedog_A" || contact.bodyA.node?.name == "spacedog_B" {
                    enemy.removeFromParent()
                }
            }
            
        }
        
        debris(position: contact.contactPoint)
        
    }
    
}

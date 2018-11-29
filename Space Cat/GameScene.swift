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
import AVFoundation

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

func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

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

class SpaceDog: SKNode {
    var isDamaged = false
}

class GameScene: SKScene {
    
    var spaceCatNode: SKSpriteNode?
    var machineNode: SKSpriteNode?
    var spaceCatAction: SKAction?
    var gameplaySound: SKAudioNode = SKAudioNode(fileNamed: "Gameplay.mp3")
    
    var score = 0
    var lives = 4
    var pointsPerHit = 100
    var isGameOver = false
    var isGameOverSound = false
    
    var sndDamage = SKAction.playSoundFileNamed("Damage.caf", waitForCompletion: false)
    var sndExplode = SKAction.playSoundFileNamed("Explode.caf", waitForCompletion: false)
    var sndLaser = SKAction.playSoundFileNamed("Laser.caf", waitForCompletion: false)
    
    //first function called when game is run
    override func didMove(to view: SKView) {
        
        //head up display for the game
        hud()
        
        
        let background = childNode(withName: "background") as! SKSpriteNode
        background.zPosition = -2
        
        if let rain = SKEmitterNode(fileNamed: "Rain") {
            rain.position = CGPoint(x: 0, y: self.frame.maxY)
            
            background.zPosition = -1
            addChild(rain)
        }
        
        if let machine = machine() {
            machine.name = "machine"
            self.machineNode = machine
        }
        
        if let spaceCatNode = spaceCat().node {
            spaceCatNode.name = "spaceCat"
            self.spaceCatNode = spaceCatNode
        }
        
        self.addChild(gameplaySound)
        
        spaceCatAction = spaceCat().action
        
        let wait = SKAction.wait(forDuration:1.0)
        let action = SKAction.run {
            if !self.isGameOver {
                self.spaceDog()
            } else {
                if !self.isGameOverSound {
                    self.isGameOverSound = true
                    self.gameOver()
                }
            }
        }
        //        self.action(forKey: "spawn").pau
        // run(SKAction.sequence([wait,action]), withKey: "spawn")
        run(SKAction.repeatForever(SKAction.sequence([wait,action])))
        
        ground(size: CGSize(width: self.frame.width, height: 22))
        
        //earths gravity Y -> -9.8
        //self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
        
        // Set the scale mode to scale to fit the window
        self.scaleMode = .aspectFill
        
        
       // self.scene?.isPaused = true
        
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
    
    func fire (position: CGPoint) -> SKAction {
        
        let offset = position - self.position
        let direction = offset.normalized()
        let shootAmount  = direction * 1000
        let realDest = shootAmount + self.position
        
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        
        return (SKAction.sequence([actionMove, actionMoveDone]))
        
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
    
    func spaceDog(isDamage: Bool = false) {
        
        var spriteNode = SKSpriteNode(imageNamed: "spacedog_A_1")
        var type:SpaceDogType = .A
        
        if Int.random(in: 0...1) == 1 {
            type = .B
        }
        
        var textures : Array<SKTexture>
        
        switch type {
        case .A:
            spriteNode.name = "spacedog"
            textures = (1...2).map({ return "spacedog_A_\($0)"}).map(SKTexture.init)
        case .B:
            spriteNode = SKSpriteNode(imageNamed: "spacedog_B_1")
            spriteNode.name = "spacedog"
            textures = (1...3).map({ return "spacedog_B_\($0)"}).map(SKTexture.init)
        }
        
        let y = Int(self.frame.maxY - spriteNode.size.height)
        let width = Int(spriteNode.size.width - 20)
        let maxXLeft = Int(-self.frame.maxX)
        let maxXRight = Int(self.frame.maxX)
        let maxX = Int.random(in: maxXLeft...maxXRight)
        let x =  maxX < width ? Int.random(in: maxX...width) : Int.random(in: width...maxX)
        
        spriteNode.position = CGPoint(x: x, y: y)
        let scale = CGFloat.random(in: 65...100) / CGFloat(100.0)
        spriteNode.xScale = scale
        spriteNode.yScale = scale
        
        addChild(spriteNode)
        let animate = SKAction.animate(with: textures, timePerFrame: 0.1)
        let action = SKAction.repeatForever(animate)
        spriteNode.physicsBody = SKPhysicsBody(rectangleOf: spriteNode.size)
        
        var velocity = -30
        
        switch score {
            
        case 0...1000:
            velocity = Int.random(in: -90...(-30))
            
        case 1100...2000:
            velocity = Int.random(in: -100...(-50))
            
        case 2000...10000000:
            velocity = Int.random(in: -150...(-90))
            
        default:
            return
        }
        
        if let physicsBody = spriteNode.physicsBody {
            physicsBody.affectedByGravity = false
            physicsBody.velocity = CGVector(dx: 0, dy: velocity)
            physicsBody.categoryBitMask = Collision.Detect.enemy.bitmask
            physicsBody.collisionBitMask = 0
            physicsBody.contactTestBitMask = Collision.Detect.projectile.bitmask | Collision.Detect.ground.bitmask
        }
        
        spriteNode.run(action)
    }
}

//MARK: Ground
extension GameScene {
    
    func ground(size: CGSize) {
        let ground = SKSpriteNode(color: .clear, size: size)
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
                physicsBody.affectedByGravity = true
                physicsBody.categoryBitMask = Collision.Detect.debris.bitmask
                physicsBody.collisionBitMask = Collision.Detect.ground.bitmask | Collision.Detect.debris.bitmask
                physicsBody.contactTestBitMask = 0
                
                let dx = Double(Int.random(in: -150...(150)))
                let dy = Double(Int.random(in: -350...(150)))
                physicsBody.velocity = CGVector(dx:dx , dy: dy)
            }
            
            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                explosion.position = position
                addChild(explosion)
                explosion.run(SKAction.wait(forDuration: 2.0)) {
                    explosion.removeFromParent()
                }
            }
            
            addChild(spriteNode)
            
            spriteNode.run(SKAction.wait(forDuration: 2)){
                spriteNode.removeFromParent()
            }
        }
    }
}

//MARK: HUD
extension GameScene {
    
    func hud() {
        
        let catNode = SKSpriteNode(imageNamed: "HUD_cat_1")
        let y = Int(self.frame.maxY - catNode.size.height)
        let x = Int(self.frame.maxX - catNode.size.width) - 70
        catNode.position = CGPoint(x: -x, y: y)
        addChild(catNode)
        
        for i in 1...lives {
            let lifeBarNode = SKSpriteNode(imageNamed: "HUD_life_1")
            lifeBarNode.name = "life\(i)"
            let lifeBarX = (x-Int(lifeBarNode.frame.width)*i)-20
            lifeBarNode.position = CGPoint(x: -lifeBarX, y: y)
            
            addChild(lifeBarNode)
            
        }
        
    }
    
    func addScore(points: Int){
        self.score += points
        if let label = self.childNode(withName: "score") as? SKLabelNode {
            let y = Int(self.frame.maxY) - 40
            let x = Int(self.frame.maxX) - 90
            label.position = CGPoint(x: x, y: y)
            label.text = "\(self.score)"
        }
    }
    
    func gameOver() {
        
        if let label = self.childNode(withName: "gameOver") as? SKLabelNode {
            
            label.zPosition = 60
            label.setScale(0)
            label.isHidden = false
            
            let scaleXY = SKAction.scale(to: 1.3, duration: 0.2)
            let scaleNormal = SKAction.scale(to: 1.0, duration: 0.4)
            let actions = [scaleXY, scaleNormal]
            label.run(SKAction.sequence(actions)) {
                if let label = self.childNode(withName: "restart") as? SKLabelNode {
                    label.isHidden = false
                }
            }
        }

        self.gameplaySound.removeFromParent()
        self.addChild(SKAudioNode(fileNamed: "GameOver.mp3"))
        
    }
    
    func loseLife() {
        
        if lives == 0 {
            
            isGameOver = true
     
            
        } else {
            
            if let life = self.childNode(withName: "life\(lives)") as? SKSpriteNode {
                lives -= 1
                life.removeFromParent()
            }
            
        }
    }
}


//MARK: Touches
extension GameScene {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if isGameOver {
            
            for node in self.children {
                node.removeFromParent()
            }
            
            if let view = self.view {
                
                // Load the SKScene from 'GameScene.sks'
                if let scene = SKScene(fileNamed: "GameScene") {
                    
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFill
                    
                    self.run(SKAction.playSoundFileNamed("PressStart.caf", waitForCompletion: false))
                    
                    // Present the scene
                    view.presentScene(scene, transition: .moveIn(with: .left, duration: 0.5))
                }
                
                view.ignoresSiblingOrder = true
                
                view.showsFPS = true
                view.showsNodeCount = true
                
            }
            
            
        } else {
            
            guard let spaceCatNode = spaceCatNode else {return}
            guard let spaceCatAction = spaceCatAction else {return}
            
            spaceCatNode.run(spaceCatAction)
            
            for touch in touches {
                
                let position = touch.location(in: self)
                
                if let projectileNode = projectile().node {
                    
                    addChild(projectileNode)
                    
                    self.run(sndLaser)
                    
                    if let machineNode = machineNode {
                        projectileNode.position = CGPoint(x: machineNode.position.x, y: -(machineNode.frame.size.height)-10)
                    }
                    
                    projectileNode.run(projectile().action)
                    projectileNode.run(fire(position: position))
                  //  projectileNode.run(action(position: position).fade)
                }
                
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
            
            if let node = contact.bodyA.node {
                
                if contact.bodyA.node?.name == "spacedog" {
                    self.run(sndExplode)
                    addScore(points: pointsPerHit)
                    node.removeFromParent()
                }
                
                if contact.bodyA.node?.name == "projectile" {
                    node.removeFromParent()
                }
            }
            
            if let node = contact.bodyB.node {
                
                if contact.bodyB.node?.name == "spacedog" {
                    self.run(sndExplode)
                    addScore(points: pointsPerHit)
                    node.removeFromParent()
                }
                
                if contact.bodyB.node?.name == "projectile" {
                    node.removeFromParent()
                }
            }
        }
        
        if collision.detect(.enemy, .ground) {
            
            if let enemy = contact.bodyA.node {
                if contact.bodyA.node?.name == "spacedog" {
                    self.run(sndDamage)
                    enemy.removeFromParent()
                }
            }
            
            if let enemy = contact.bodyB.node {
                if contact.bodyB.node?.name == "spacedog" {
                    self.run(sndDamage)
                    enemy.removeFromParent()
                }
            }
            
            loseLife()
            
        }
        
        debris(position: contact.contactPoint)
        
    }
    
}

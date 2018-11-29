//
//  TitleScene.swift
//  Space Cat
//
//  Created by codebendr on 25/08/2018.
//  Copyright © 2018 just pixel. All rights reserved.
//

import SpriteKit
import GameplayKit

class TitleScene: SKScene {
    
    var background: SKSpriteNode?
    
    override func didMove(to view: SKView) {
        
        background = childNode(withName: "background") as? SKSpriteNode
        
        self.addChild(SKAudioNode(fileNamed: "StartScreen.mp3"))
        
    }
    
}

extension TitleScene {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //guard let background = self.background else { return }
        
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
        
    }
    
}

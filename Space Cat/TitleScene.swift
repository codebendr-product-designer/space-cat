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
    
    var background:SKSpriteNode?
    
    override func didMove(to view: SKView) {
        
        background = childNode(withName: "background") as? SKSpriteNode
        
//        if let background = self.background {
//
//        }
        
        
    }

}

extension TitleScene {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let background = self.background else { return }
        
        if let view = self.view {
            
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene, transition: .fade(withDuration: 1.0))
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
            
        }
        
    }
    
}

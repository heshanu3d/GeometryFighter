//
//  GameViewController.swift
//  GeometryFighter
//
//  Created by hs on 2019/1/1.
//  Copyright © 2019年 hs. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {
    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var spawnTime: TimeInterval = 0
    var game = GameHelper.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        setupHUD()
    }
    
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupView() {
        scnView = self.view as! SCNView
        scnView.delegate = self
    }

    func setupScene() {
        scnScene = SCNScene()
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.jpg"
        scnView.scene = scnScene
        scnView.showsStatistics = true
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true
    }
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }

    func spawnShape() {
        var geometry:SCNGeometry
        switch ShapeType.random() {
        case ShapeType(rawValue: 0)!: geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        case ShapeType(rawValue: 1)!: geometry = SCNSphere(radius: 1.0)
        case ShapeType(rawValue: 2)!: geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
        case ShapeType(rawValue: 3)!: geometry = SCNTorus(ringRadius: 1.0, pipeRadius: 1.0)
        case ShapeType(rawValue: 4)!: geometry = SCNCapsule(capRadius: 1.0, height: 1.0)
        case ShapeType(rawValue: 5)!: geometry = SCNCylinder(radius: 1.0, height: 1.0)
        case ShapeType(rawValue: 6)!: geometry = SCNCone(topRadius: 1.0, bottomRadius: 1.0, height: 1.0)
        case ShapeType(rawValue: 7)!: geometry = SCNTube(innerRadius: 1.0, outerRadius: 1.0, height: 1.0)
        default: geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        }
        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color
        
        let geometryNode = SCNNode(geometry: geometry)
        scnScene.rootNode.addChildNode(geometryNode)
        geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        let force = SCNVector3(x: randomX, y: randomY , z: 0)
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        geometryNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
        
        let trailEmitter = createTrail(color: color, geometry: geometry)
        geometryNode.addParticleSystem(trailEmitter)
        
        if color == UIColor.black {
            geometryNode.name = "BAD"
        } else {
            geometryNode.name = "GOOD"
        }
    }
    
    func cleanScene() {
        for node in scnScene.rootNode.childNodes {
            if node.presentation.position.y < -2 {
                node.removeFromParentNode() }
        }
    }
    
    func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
            let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
            trail.particleColor = color
            trail.emitterShape = geometry
            return trail
    }
    
    func setupHUD() {
        game.hudNode.position = SCNVector3(x: 0.0, y: 10.0, z: 0.0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
    func handleTouchFor(node: SCNNode) {
        if node.name == "GOOD" {
            game.score += 1
            node.removeFromParentNode()
            createExplosion(geometry: node.geometry!, color: node.geometry!.firstMaterial?.diffuse.contents! as! UIColor, position: node.presentation.position, rotation: node.presentation.rotation)
        } else if node.name == "BAD" {
            game.lives -= 1
            node.removeFromParentNode()
        }
    }
    
    func createExplosion(geometry: SCNGeometry, color: UIColor, position: SCNVector3, rotation: SCNVector4) {
        let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
        explosion.emitterShape = geometry
        explosion.birthLocation = .surface
        explosion.particleColor = color
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(explosion, transform: transformMatrix)
    }
}

extension GameViewController : SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if time > spawnTime {
            spawnShape()
            spawnTime = time + TimeInterval(Float.random(min: 0.2, max: 1.5))
        }
        cleanScene()
         game.updateHUD()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        let touch = touches.first!
        let location = touch.location(in: scnView)
        let hitResults = scnView.hitTest(location, options: nil)
        if let result = hitResults.first {
            handleTouchFor(node: result.node)
        }
    }
}

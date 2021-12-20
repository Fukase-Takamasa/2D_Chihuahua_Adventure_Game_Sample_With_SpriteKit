//
//  GameScene.swift
//  Vamos-a-jugar-al-SpriteKit
//
//  Created by 深瀬 貴将 on 2021/12/20.
//

import SpriteKit
import GameplayKit
import SKTiled

enum Direction: Int {
    case up = 0
    case left = 1
    case right = 2
    case down = 3
}

class GameScene: SKScene {
    
    var currentEventStatus: ArsagaMapNotifyFromSceneType = .introduction
        
    var chihuahuaTextures: [[SKTexture]] = []
    var eventAuraTextures: [SKTexture] = []
    
    var tilemap = SKTilemap.load(tmxFile: "testMap1")!
    var topLayer: SKTileLayer?
    var obstacleLayer: SKTileLayer?
    var chihuahuaNode = SKSpriteNode(imageNamed: "chihuahua_right_0")
    var chihuahuaCamera = SKCameraNode()
    
    var eventPointAura = SKSpriteNode(imageNamed: "eventPointAura_0")
    
    var obstacleTilePositions = [CGPoint]()
    
    
    var timer = Timer()
    var timerCount = 0.0
    
    var direction: Direction?
    var originPos = CGPoint()
    
    override func didMove(to view: SKView) {
        
        self.addChild(tilemap)

        setchihuahua()
        setEventAura()
        setObstacleTilePositions()
        setAnimationTextures()
        
        NotificationCenter.default.addObserver(self, selector: #selector(notifyFromVC(notification:)), name: .arsagaMapNotifyFromVC, object: nil)
    }
    
    @objc func notifyFromVC(notification: Notification) {
        
        guard let notifyType = notification.userInfo!["notifyType"] as? ArsagaMapNotifyFromVCType else {
            print("userInfo取得失敗")
            return
        }
        
        switch notifyType {
        case .didEndFirstEvent:
            print("didEndFirstEvent")
            eventPointAura.isHidden = true
        }
        
    }
    
    @objc func notifyFromSideMenu(notification: Notification) {
        
        switch notification.userInfo!["type"] as! NotifyType {
        case .changeEvent:
            let event = notification.userInfo!["event"] as! ArsagaMapNotifyFromSceneType
            switch event {
            case .introduction:
                break
                
            case .firstEvent:
                notifyEvent(type: .firstEvent)
                currentEventStatus = .firstEvent
            }
        }
        
    }
    
    func notifyEvent(type: ArsagaMapNotifyFromSceneType) {
        NotificationCenter.default.post(name: .arsagaMapNotifyFromScene, object: nil, userInfo: ["notifyType": type])
    }
    
    func setObstacleTilePositions() {
        let obstacleLayer = tilemap.tileLayer(atIndex: 2)
        print("tileSize: \(String(describing: obstacleLayer?.tileSize))")

        obstacleLayer?.getTiles().forEach({ tile in

            obstacleTilePositions += [CGPoint(x: tile.position.x - 16, y: tile.position.y + 16)]

        })

        print(obstacleTilePositions)

        self.obstacleLayer = obstacleLayer
        
    }
    
    func setchihuahua() {
        chihuahuaNode.addChild(chihuahuaCamera)
        
        topLayer = tilemap.tileLayers().last
        
        topLayer?.addChild(chihuahuaNode)
        chihuahuaNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        chihuahuaNode.position = CGPoint(x: (32 * 20), y: -(32 * 6))
        
        self.camera = chihuahuaCamera
    }
    
    func setEventAura() {
        topLayer?.addChild(eventPointAura)
        eventPointAura.position = CGPoint(x: 1683.50927734375, y: -602.942626953125)
    }
    
    func setAnimationTextures() {
        [["chihuahua_back_0", "chihuahua_back_1"],
         ["chihuahua_left_0","chihuahua_left_1"],
         ["chihuahua_right_0", "chihuahua_right_1"],
         ["chihuahua_front_0", "chihuahua_front_1"]].forEach({ item in
                chihuahuaTextures += [[SKTexture(imageNamed: item[0]), SKTexture(imageNamed: item[1])]]
            })
        
        var eventAuraImageNames: [String] = []
        for i in 0...9 {
            eventAuraImageNames += ["eventPointAura_\(i)"]
        }
        eventAuraImageNames.forEach({ item in
            eventAuraTextures += [SKTexture(imageNamed: item)]
        })
        
        let eventAuraAnimateAction = SKAction.animate(with: eventAuraTextures, timePerFrame: 0.1)
        let repeatForever = SKAction.repeatForever(eventAuraAnimateAction)
        
        eventPointAura.run(repeatForever)
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        let location = touches.first!.location(in: self)

        let position = convert(location, to: topLayer!)

        self.timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.move(timer:)), userInfo: nil, repeats: true)

        originPos = position

        print("timer start, originPos: \(originPos)")
        
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)

        let position = convert(location, to: topLayer!)

        let distance = position - originPos

        if distance.x > distance.y {
            if distance.x > 0 {
                print("右")
                direction = .right
            }else {
                print("下")
                direction = .down
            }

        }else {
            if distance.y > 0 {
                print("上")
                direction = .up
            }else {
                print("左")
                direction = .left
            }

        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        print("end")
        
        timer.invalidate()
        timerCount = 0.0
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        print("position: \(chihuahuaNode.position)")
        
        switch currentEventStatus {
        case .introduction:
            if reachedEventPoint(currentPos: chihuahuaNode.position, eventTarget: eventPointAura) {
                notifyEvent(type: .firstEvent)
                currentEventStatus = .firstEvent
            }
        default:
            break
        }
    }
    
    
    @objc func move(timer: Timer) {
        
        var targetPos = chihuahuaNode.position
        
        //0.2秒間隔でテクスチャーを切り替えるパラパラ漫画風アニメーション
        let animateAction = SKAction.animate(with: chihuahuaTextures[direction!.rawValue], timePerFrame: 0.2)
        
        //0.4秒ごとにアニメーションを実行させる（0.4秒ごとにアニメーションが終わるので再開させる）
        if (Int(timerCount * 10) % 4 == 0) || timerCount == 0 {
            
            chihuahuaNode.run(animateAction)
            
            print("animate")
            
        }
        
        //MARK: - 少数同士の計算だとずれるので、整数換算してから計算
        timerCount *= 10
        timerCount += 2
        timerCount /= 10
//        timerCount += 0.2
        
        switch direction {
        case .up:
            targetPos.y += 32
            
        case .right:
            targetPos.x += 32
            
        case .left:
            targetPos.x -= 32
            
        case .down:
            targetPos.y -= 32
            
        default: break
        }
                
        guard checkObstacles(targetPos: targetPos) else {
            print("checkObstacles == falseなのでreturn")
            return
        }
        print("move")
        
        let action = SKAction.move(to: targetPos, duration: 0.2)
        chihuahuaNode.run(action)

    }
    
    func checkObstacles(targetPos: CGPoint) -> Bool {
        
        let result = obstacleTilePositions.first(where: { item in
            
            let xRange = item.x...(item.x + 32)
            let yRange = (item.y - 32)...item.y
            
            return xRange.contains(targetPos.x) && yRange.contains(targetPos.y)
            
        })
                
        print("異動先のタイル座標が障害物（obstacle）である: \(result == nil)")

        return result == nil
        
    }
    
    func reachedEventPoint(currentPos: CGPoint, eventTarget: SKSpriteNode) -> Bool {
        
        let eventPos = eventTarget.position
        
        let xRange = (eventPos.x - 32)...(eventPos.x + 132)
        let yRange = (eventPos.y - 100)...(eventPos.y)
        
        return xRange.contains(currentPos.x) && yRange.contains(currentPos.y)
    }
    
}

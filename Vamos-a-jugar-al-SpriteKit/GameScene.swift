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
    
    
    
    //マップ(.tmxファイル)をインポート
    var tilemap = SKTilemap.load(tmxFile: "testMap1")!
    
    //上記インスタンスから抽出した一番全面のレイヤーを後で格納します
    var topLayer: SKTileLayer?
    
    //上記インスタンスから抽出した障害物判定用のレイヤーを後で格納します
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

        setChihuahua()
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
    
    
    //障害物判定用の座標リストを取得
    func setObstacleTilePositions() {
        //TiledMapで見ていたときにレイヤーリストの下から3番目に位置していたので、index=2を指定して取得
        let obstacleLayer = tilemap.tileLayer(atIndex: 2)
        
        //座標計算ようにタイルのpxを確認。今回は32×32です。
        print("tileSize: \(String(describing: obstacleLayer?.tileSize))")
        
        //障害物タイルの座標リストを配列に格納
        obstacleLayer?.getTiles().forEach({ tile in
            /*
             16pxずつずらしている理由↓
             tileのアンカーポイント（座標基準点）が正方形の中心（x:0.5, y:0.5）になっているので、
             正方形の左上になるようにずらしています。
            */
            obstacleTilePositions += [CGPoint(x: tile.position.x - 16, y: tile.position.y + 16)]
        })

        print(obstacleTilePositions)

        self.obstacleLayer = obstacleLayer
        
    }
    
    
    //チワワをMAPの最前面レイヤーに配置
    func setChihuahua() {
        //チワワnodeにカメラを設定
        chihuahuaNode.addChild(chihuahuaCamera)
        
        //MAPの最前面のレイヤーを取得
        topLayer = tilemap.tileLayers().last
        
        //チワワを最前面のレイヤーに設置
        topLayer?.addChild(chihuahuaNode)
        // - アンカーポイントの調整（画像と座標基準点の関係）
        chihuahuaNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        // - 初期座標を設定（今回1マス32pxなので、左上から見て右に20、下に6マスのところ）
        chihuahuaNode.position = CGPoint(x: (32 * 20), y: -(32 * 6))
        
        //カメラをSceneに適用
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
        //キャラクターの現在座標を取得
        var targetPos = chihuahuaNode.position
        
        //0.2秒間隔でテクスチャーを切り替えるパラパラ漫画風アニメーション
        let animateAction = SKAction.animate(with: chihuahuaTextures[direction!.rawValue], timePerFrame: 0.2)
        
        //0.4秒ごとにアニメーションを実行させる（0.4秒ごとにアニメーションが終わるので再開させる）
        if (Int(timerCount * 10) % 4 == 0) || timerCount == 0 {
            chihuahuaNode.run(animateAction)
        }
        
        //MARK: - 少数同士の計算だとずれるので、整数換算してから計算
        timerCount *= 10
        timerCount += 2
        timerCount /= 10
//        timerCount += 0.2
        
        //移動しようとしている方向によって移動先座標を書き換え
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
                
        //MARK: - 移動先の座標が障害物座標リストに含まれていたら、進ませずに終了する
        guard checkObstacles(targetPos: targetPos) else {
            print("checkObstacles == falseなのでreturn")
            return
        }
        
        //キャラクターの移動を実行
        let action = SKAction.move(to: targetPos, duration: 0.2)
        chihuahuaNode.run(action)

    }
    
    //移動先の座標が障害物座標リストに含まれているかチェック
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

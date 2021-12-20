//
//  GameViewController.swift
//  Vamos-a-jugar-al-SpriteKit
//
//  Created by 深瀬 貴将 on 2021/12/20.
//

import UIKit
import SpriteKit
import GameplayKit
import SRGNovelGameTexts

class GameViewController: UIViewController {

    var currentEvent: ArsagaMapNotifyFromSceneType = .introduction

    let narrationTexts: [ArsagaMapNotifyFromSceneType: [String]] = [
        .introduction: ["2021年12月 都内某所。",
                        "B'zからのプレゼントがあると聞きつけて、とあるオフィスにやってきたチワワ君。",
                        "早速プレゼントを受け取りに行ってみよう！",
                        "  --Mission--  『オフィスのどこかにある黄色いイベントポイントを探せ！』"],
        
            .firstEvent: ["B'zのニューアルバム「FRIENDS Ⅲ」をGETした！",
                          "Merry christmas！",
                          "  --完--  ",],
    ]

    var textIndex = 0
    var novelGameTextView: SRGNovelGameTexts!
    var clearView: UIView!
    
    @IBOutlet weak var skView: SKView!
    @IBOutlet weak var bzImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Load the SKScene from 'GameScene.sks'
        if let scene = SKScene(fileNamed: "GameScene") {
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            
            // Present the scene
            skView.presentScene(scene)
        }
        
        skView.ignoresSiblingOrder = true
        
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        showNovelGameText()
        
        NotificationCenter.default.addObserver(self, selector: #selector(notifyFromScene(notification:)), name: .arsagaMapNotifyFromScene, object: nil)
    }
    
    @objc func notifyFromScene(notification: Notification) {

        guard let notifyType = notification.userInfo!["notifyType"] as? ArsagaMapNotifyFromSceneType else {
            print("userInfo取得失敗")
            return
        }
        currentEvent = notifyType

        switch notifyType {
        case .firstEvent:
            print("firstEvent")
            showNovelGameText()
            AudioModel.playSound(of: .itsukanoMerryXmas)
            
            UIView.animate(withDuration: 2) {
                self.bzImageView.alpha = 0.8
            }
            UIView.animate(withDuration: 5) {
                self.bzImageView.frame.origin.y += 300
            }

        default:
            break
        }

    }
    
    func notifyEvent(type: ArsagaMapNotifyFromVCType) {
        NotificationCenter.default.post(name: .arsagaMapNotifyFromVC, object: nil, userInfo: ["notifyType": type])
    }

    func showNovelGameText() {
        clearView = UIView(frame: self.view.frame)
        clearView.backgroundColor = .clear
        clearView.isUserInteractionEnabled = true
        self.view.addSubview(clearView)

        let novelGameTextBackGroundView = UIView(frame: CGRect(x: 0, y: self.view.frame.height - 200, width: self.view.frame.width, height: 200))
        novelGameTextBackGroundView.backgroundColor = .black
        novelGameTextBackGroundView.layer.borderWidth = 3
        novelGameTextBackGroundView.layer.borderColor = UIColor.white.cgColor
        clearView.addSubview(novelGameTextBackGroundView)

        let frameView = UIView(frame: CGRect(x: 25, y: 20, width: novelGameTextBackGroundView.frame.width - 60, height: novelGameTextBackGroundView.frame.height - 40))
        frameView.backgroundColor = .clear
        novelGameTextBackGroundView.addSubview(frameView)

        novelGameTextView = SRGNovelGameTexts()
        novelGameTextView.frame = CGRect(x: 0, y: 0, width: frameView.frame.width, height: frameView.frame.height)
        novelGameTextView.textColor = .white
        frameView.addSubview(novelGameTextView)

        print("currentEvent: \(currentEvent), textIndex: \(textIndex)")
        // 出力したいテキストをセット
        novelGameTextView.setText(narrationTexts[currentEvent]?[textIndex])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AudioModel.audioPlayers[.subtitles]?.numberOfLoops = 100
            AudioModel.playSound(of: .subtitles)
            // 演出を再生開始
            self.novelGameTextView.startDisplayingText()
            self.novelGameTextView.onAllTextDisplayed = {
                print("text完了")
                AudioModel.audioPlayers[.subtitles]?.stop()
            }
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard self.view.subviews.contains(clearView) else {
            print("clearViewがないので、タップは無効にします")
            return
        }
        
        if novelGameTextView.isTextDisplayingCompleted {
            self.textIndex += 1
            AudioModel.audioPlayers[.subtitles]?.stop()
            
            guard self.textIndex < self.narrationTexts[currentEvent]?.count ?? 0 else {

                clearView.removeFromSuperview()
                print("text終了")
                textIndex = 0

                switch currentEvent {
                case .firstEvent:
                    notifyEvent(type: .didEndFirstEvent)
                    bzImageView.isHidden = true

                default:
                    break
                }

                return
            }
            
            novelGameTextView.cleanup()
            novelGameTextView.setText(narrationTexts[currentEvent]?[textIndex])
            novelGameTextView.startDisplayingText()
            AudioModel.audioPlayers[.subtitles]?.numberOfLoops = 100
            AudioModel.playSound(of: .subtitles)
            
        }else {

            novelGameTextView.displayAllText()
            AudioModel.audioPlayers[.subtitles]?.stop()
        }
        
    }
}


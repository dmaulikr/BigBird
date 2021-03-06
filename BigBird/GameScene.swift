//
//  GameScene.swift
//  BigBird
//
//  Created by baby on 15/12/6.
//  Copyright (c) 2015年 baby. All rights reserved.
//

import SpriteKit
import GameKit

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    var fullyEat = 0//满能量的情况下连续吃鱼的次数
    var onlyBigFish = false//仅吃大鱼
    var onlySmallFish = false//仅吃小鱼
    var isonly = true//用来标记是否仅吃大鱼或小鱼
    var energy:Int = 100
    var distance:Int = 0
    var eatFishCount:Int = 0
    var maxDistance:Int = 0
    var tempMaxDistance:Int = 0//临时保存飞行最高纪录
    var alredayShowTip = false
    var firstTimePlay = true
    var lastBirdY:CGFloat = 0
    
    enum GameStatus:UInt{
        case Ready = 0
        case Playing = 1
        case Over = 2
    }
    var gameStatus:GameStatus = .Ready
    
    enum ColliderType:UInt32{
        case Bird = 1
        case Fish1 = 2
        case Fish2 = 4
        case Object = 8
    }
    
    var background = SKSpriteNode()
    var bird = SKSpriteNode()
    var water = SKSpriteNode()
    var tornato = SKSpriteNode()
    var fish1 = SKSpriteNode()
    var fish2 = SKSpriteNode()
    var shark = SKSpriteNode()
    var distanceLabel = SKLabelNode()
    var maxDistanceLabel = SKLabelNode()
    var startLabel = SKSpriteNode()
    var tapLabel = SKSpriteNode()
    var progressBackground = SKSpriteNode()
    var progress = SKSpriteNode()
    var energyLabel = SKLabelNode()
    var introduce = SKSpriteNode()
    var bestSorceTipLabel = SKLabelNode()
    
    override func didMoveToView(view: SKView) {
        
        self.physicsWorld.contactDelegate = self
        
        maxDistance = NSUserDefaults.standardUserDefaults().objectForKey("maxDistance") as? NSInteger ?? 0
        firstTimePlay = NSUserDefaults.standardUserDefaults().objectForKey("firstTimePlay") as? Bool ?? true
        tempMaxDistance = maxDistance
        
        setupBackground()
        
        progressBackground.color = UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 1)
        progressBackground.size = CGSizeMake(180, 30)
        progressBackground.anchorPoint = CGPointMake(0, 1)
        progressBackground.position = CGPointMake(CGRectGetMidX(frame)-90, frame.height)
        addChild(progressBackground)
        
        progress.color = UIColor(red: 94/255, green: 202/255, blue: 138/255, alpha: 1)
        progress.size = CGSizeMake(180, 30)
        progress.anchorPoint = CGPointMake(0, 1)
        progress.position = CGPointMake(CGRectGetMidX(frame)-90, frame.height)
        addChild(progress)
        
        energyLabel.text = "100/100"
        energyLabel.fontSize = 20
        energyLabel.fontName = "PingFang SC"
        energyLabel.position = CGPointMake(CGRectGetMidX(frame), frame.height - 22)
        addChild(energyLabel)
                
        distanceLabel.text = "当前:0M"
        distanceLabel.fontSize = 20
        distanceLabel.fontColor = UIColor(red: 245/255, green: 161/255, blue: 49/255, alpha: 1)
        distanceLabel.fontName = "PingFang SC"
        distanceLabel.position = CGPointMake(CGRectGetMidX(frame)-150, frame.height - 22)
        addChild(distanceLabel)
        
        maxDistanceLabel.text = "最高:\(maxDistance)M"
        maxDistanceLabel.fontSize = 20
        maxDistanceLabel.fontColor = UIColor(red: 94/255, green: 202/255, blue: 138/255, alpha: 1)
        maxDistanceLabel.fontName = "PingFang SC"
        maxDistanceLabel.position = CGPointMake(CGRectGetMidX(frame)+150, frame.height - 22)
        addChild(maxDistanceLabel)
        
        startLabel = SKSpriteNode(imageNamed: "start")
        startLabel.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame) + 150)
        addChild(startLabel)
        
        let tapTexture1 = SKTexture(imageNamed: "tap1")
        let tapTexture2 = SKTexture(imageNamed: "tap2")
        let tapAction = SKAction.animateWithTextures([tapTexture1,tapTexture2], timePerFrame: 0.5)
        let tapForever = SKAction.repeatActionForever(tapAction)
        tapLabel = SKSpriteNode(texture: tapTexture1)
        tapLabel.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
        tapLabel.runAction(tapForever)
        addChild(tapLabel)
        
        setupBird()
        setupRain()
        
        let bottomBound = SKNode()
        bottomBound.position = CGPointMake(0, 0)
        bottomBound.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(frame.width, 1))
        bottomBound.physicsBody?.dynamic = false
        bottomBound.physicsBody?.categoryBitMask = ColliderType.Object.rawValue
        bottomBound.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue
        bottomBound.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        addChild(bottomBound)

        setupWater()
        if firstTimePlay{
            setupIntroduce()
        }
    }
    
    
    func setupLightning(){
        let offsetY1 = CGFloat(arc4random_uniform(100))+150
        let offsetY2 = CGFloat(arc4random_uniform(50))+30
        let offsetX1 = CGFloat(arc4random_uniform(UInt32(frame.width/2))) - frame.width/4
        let offsetX2 = CGFloat(arc4random_uniform(UInt32(frame.width/2))) - frame.width/4
        let lightning = LightningNode(size: size)
        lightning.position = CGPointZero
        lightning.startLightning(CGPointMake(CGRectGetMidX(frame)+offsetX1, frame.height - offsetY2), endPoint: CGPointMake(CGRectGetMidX(frame)+offsetX2, frame.height-offsetY2-offsetY1))
        let duration = SKAction.waitForDuration(2)
        let remove = SKAction.removeFromParent()
        lightning.runAction(SKAction.sequence([duration,remove]))
        self.addChild(lightning)
    }
    
    func setupRain(){
        let rainTexture = SKTexture(imageNamed: "rain.png")
        let emitterNode = SKEmitterNode()
        emitterNode.particleTexture = rainTexture
        emitterNode.particleBirthRate = 150.0
        emitterNode.particleColor = SKColor.whiteColor()
        emitterNode.particleSpeed = -450
        emitterNode.particleSpeedRange = 150
        emitterNode.particleLifetime = 2.0
        emitterNode.particleScale = 0.4
        emitterNode.particleScaleRange = 0.6
        emitterNode.particleAlpha = 0.75
        emitterNode.particleAlphaRange = 0.5
        emitterNode.position = CGPoint(x: CGRectGetWidth(frame) / 2, y:
            CGRectGetHeight(frame)-160)
        emitterNode.particlePositionRange = CGVector(dx: CGRectGetMaxX(frame),
            dy: 0)
        addChild(emitterNode)
    }
    
    func setupIntroduce(){
        introduce = SKSpriteNode(imageNamed: "introduce")
        introduce.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
        introduce.zPosition = 10
        introduce.size.height = frame.size.height
        addChild(introduce)
    }
    
    func setupBackground(){
        let bgTexture = SKTexture(imageNamed: "background")
        let moveBg = SKAction.moveByX(-bgTexture.size().width, y: 0, duration: 10)
        let replaceBg = SKAction.moveByX(bgTexture.size().width, y: 0, duration: 0)
        let moveBgForever = SKAction.repeatActionForever(SKAction.sequence([moveBg,replaceBg]))
        for i in 0...1{
        background = SKSpriteNode(texture: bgTexture)
        background.position = CGPointMake(bgTexture.size().width/2 + bgTexture.size().width * CGFloat(i), CGRectGetMidY(frame))
        background.zPosition = -5
        background.size.height = frame.size.height
        background.runAction(moveBgForever)
        addChild(background)
        }
    }
    
    func setupWater(){
        let waterTexture = SKTexture(imageNamed: "water")
        let moveBg = SKAction.moveByX(-waterTexture.size().width, y: 0, duration: 10)
        let replaceBg = SKAction.moveByX(waterTexture.size().width, y: 0, duration: 0)
        let moveBgForever = SKAction.repeatActionForever(SKAction.sequence([moveBg,replaceBg]))
        for i in 0...1{
            water = SKSpriteNode(texture: waterTexture)
            water.anchorPoint = CGPointMake(0.5, 0)
            water.position = CGPointMake(waterTexture.size().width/2 + waterTexture.size().width * CGFloat(i), 0)
            water.zPosition = 5
            water.size.height = frame.size.height * 160 / 667
            water.runAction(moveBgForever)
            addChild(water)
        }
    }
    
    func setupBird(){
        let birdTexture1 = SKTexture(imageNamed: "bird1")
        let birdTexture2 = SKTexture(imageNamed: "bird2")
        let birdTexture3 = SKTexture(imageNamed: "bird3")
        let birdTexture4 = SKTexture(imageNamed: "bird2")
        let fly = SKAction.animateWithTextures([birdTexture1,birdTexture2,birdTexture3,birdTexture4], timePerFrame: 0.2)
        let flyForever = SKAction.repeatActionForever(fly)
        bird = SKSpriteNode(texture: birdTexture1)
        bird.position = CGPointMake(CGRectGetMidX(frame) - 120, CGRectGetMidY(frame))
        bird.runAction(flyForever)
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdTexture1.size().height/2)
        bird.physicsBody?.dynamic = false
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = ColliderType.Bird.rawValue
        bird.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue
        bird.physicsBody?.collisionBitMask = ColliderType.Object.rawValue

        addChild(bird)
        
    }
    
    func setupTornato(){
        distance += 5
        distanceLabel.text = "当前:"+"\(distance)"+"M"
        maxDistance = max(maxDistance,distance)
        maxDistanceLabel.text = "最高:"+"\(maxDistance)"+"M"
        
        if maxDistance > tempMaxDistance && tempMaxDistance != 0 && !alredayShowTip{
            showBestScoreTip()
            alredayShowTip = true
        }
        
        let offset = CGFloat(arc4random_uniform(UInt32(frame.height/2.5))) - frame.height/5
        let tornatoTexture1 = SKTexture(imageNamed: "tornado1")
        let tornatoTexture2 = SKTexture(imageNamed: "tornado2")
        let blewAction = SKAction.animateWithTextures([tornatoTexture1,tornatoTexture2], timePerFrame: 0.2)
        let blewForever = SKAction.repeatActionForever(blewAction)

        let moveTornato = SKAction.moveByX(-frame.width * 2, y: 0, duration:NSTimeInterval(frame.width/100))
        let removeTornato = SKAction.removeFromParent()
        let moveAndRemovePies = SKAction.sequence([moveTornato,removeTornato])
        tornato = SKSpriteNode(texture: tornatoTexture1)
        tornato.position = CGPointMake(CGRectGetMidX(frame) + frame.width, CGRectGetMidY(frame) + offset)
        tornato.physicsBody = SKPhysicsBody(texture: tornatoTexture2, size: tornato.size)
        tornato.physicsBody?.dynamic = false
        tornato.name = "tornato"
        tornato.runAction(blewForever)
        tornato.runAction(moveAndRemovePies)
        tornato.physicsBody?.categoryBitMask = ColliderType.Object.rawValue
        tornato.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue
        tornato.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        addChild(tornato)
        for _ in 0...1{
            setupFish1()
            setupFish2()
        }
        
        if distance % 20 == 0 {
            setupShark()
        }
        if distance % 30 == 0 {
            setupLightning()
        }
    }
    
    func setupFish1(){
        let offsetY = CGFloat(arc4random_uniform(100))
        let randomDuration = NSTimeInterval(arc4random_uniform(2)) + 10
        let offsetX = CGFloat(arc4random_uniform(UInt32(frame.width)))
        let Fish1Texture = SKTexture(imageNamed: "fish1")
        let moveFish = SKAction.moveByX(-frame.width * 3, y: 0, duration:randomDuration)
        let removeFish = SKAction.removeFromParent()
        let moveAndRemoveFish = SKAction.sequence([moveFish,removeFish])
        fish1 = SKSpriteNode(texture: Fish1Texture)
        fish1.position = CGPointMake(CGRectGetMidX(frame) + frame.width + offsetX , 10 + offsetY)
        fish1.physicsBody = SKPhysicsBody(texture: Fish1Texture, size: fish1.size)
        fish1.physicsBody?.dynamic = false
        fish1.name = "fish1"
        fish1.runAction(moveAndRemoveFish)
        fish1.physicsBody?.categoryBitMask = ColliderType.Fish1.rawValue
        fish1.physicsBody?.contactTestBitMask = ColliderType.Bird.rawValue
        fish1.physicsBody?.collisionBitMask = ColliderType.Fish1.rawValue
        addChild(fish1)
    }
    
    func setupFish2(){
        let offsetY = CGFloat(arc4random_uniform(110))
        let randomDuration = NSTimeInterval(arc4random_uniform(3))+15
        let offsetX = CGFloat(arc4random_uniform(UInt32(frame.width)))
        let Fish2Texture = SKTexture(imageNamed: "fish2")
        let moveFish = SKAction.moveByX(-frame.width * 4, y: 0, duration:randomDuration)
        let removeFish = SKAction.removeFromParent()
        let moveAndRemoveFish = SKAction.sequence([moveFish,removeFish])
        fish2 = SKSpriteNode(texture: Fish2Texture)
        fish2.position = CGPointMake(CGRectGetMidX(frame) + frame.width + offsetX*2 , 10 + offsetY)
        fish2.physicsBody = SKPhysicsBody(texture: Fish2Texture, size: fish2.size)
        fish2.physicsBody?.dynamic = false
        fish2.name = "fish2"
        fish2.runAction(moveAndRemoveFish)
        fish2.physicsBody?.categoryBitMask = ColliderType.Fish2.rawValue
        fish2.physicsBody?.contactTestBitMask = ColliderType.Bird.rawValue
        fish2.physicsBody?.collisionBitMask = ColliderType.Fish2.rawValue
        addChild(fish2)
    }
    
    func setupShark(){
        let sharkTexture = SKTexture(imageNamed: "shark")
        let moveShark = SKAction.moveByX(0, y: 100, duration:0.5)
        let pauseShark = SKAction.waitForDuration(2)
        let moveOut = SKAction.moveByX(0, y: -100, duration: 0.5)
        let removeShark = SKAction.removeFromParent()
        let moveAndRemoveShark = SKAction.sequence([moveShark,pauseShark,moveOut,removeShark])
        shark = SKSpriteNode(texture: sharkTexture)
        shark.position = CGPointMake(CGRectGetMidX(frame) - 120 , -50)
        shark.zPosition = 1
        shark.physicsBody = SKPhysicsBody(texture: sharkTexture, size: shark.size)
        shark.physicsBody?.dynamic = false
        shark.runAction(moveAndRemoveShark)
        shark.physicsBody?.categoryBitMask = ColliderType.Object.rawValue
        shark.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue
        shark.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        addChild(shark)
    }
    
    func showBestScoreTip(){
        runAction(SKAction.playSoundFileNamed("handclap.wav", waitForCompletion: false))
        let pause = SKAction.moveByX(0, y: 0, duration: 5)
        let remove = SKAction.removeFromParent()
        bestSorceTipLabel.text = "恭喜你！破纪录了！"
        bestSorceTipLabel.fontSize = 30
        bestSorceTipLabel.fontName = "PingFang SC"
        bestSorceTipLabel.fontColor = UIColor(red: 245/255, green: 161/255, blue: 49/255, alpha: 1)
        bestSorceTipLabel.position = CGPointMake(CGRectGetMidX(frame), frame.height - 80)
        bestSorceTipLabel.runAction(SKAction.sequence([pause,remove]))
        addChild(bestSorceTipLabel)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if gameStatus == .Ready && !firstTimePlay {
            gameStatus = .Playing
            bird.physicsBody?.dynamic = true
            startLabel.removeFromParent()
            tapLabel.removeFromParent()
            (UIApplication.sharedApplication().delegate as! AppDelegate).timer = NSTimer.scheduledTimerWithTimeInterval( 2, target: self, selector: "setupTornato", userInfo: nil, repeats: true)
        }

        if firstTimePlay{
            firstTimePlay = false
            introduce.removeFromParent()
            NSUserDefaults.standardUserDefaults().setBool(firstTimePlay, forKey: "firstTimePlay")
        }
        
        if gameStatus == .Playing {
            var achievements = [GKAchievement]()
            //当极度接近鲨鱼没死触发
            if bird.position.y - shark.position.y > 159/2 && bird.position.y - shark.position.y <= 85{
                achievements.append(AchievementsHelper.completeLiveSoOkAchievement())
                GameKitHelper.shareInstance.reportAchievements(achievements)
            }
            
            if lastBirdY - bird.position.y > frame.height {
                achievements.append(AchievementsHelper.completeFreeFallAchievement())
                GameKitHelper.shareInstance.reportAchievements(achievements)
            }
            
            lastBirdY = bird.position.y
            
            energy -= 2
            progress.size.width -= 3.6
            switch energy{
            case 75...100:
                runAction(SKAction.playSoundFileNamed("BubblePo-Benjamin-8920_hifi.mp3", waitForCompletion: false))
                progress.color = UIColor(red: 94/255, green: 202/255, blue: 138/255, alpha: 1)
            case 50..<75:
                runAction(SKAction.playSoundFileNamed("BubblePo-Benjamin-8920_hifi.mp3", waitForCompletion: false))
                progress.color = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1)
            default:
                let playSound = SKAction.playSoundFileNamed("6.wav", waitForCompletion: false)
                runAction(playSound)
                progress.color = UIColor(red: 208/255, green: 2/255, blue: 27/255, alpha: 1)
            }
            
            energyLabel.text = "\(energy)/100"
            bird.physicsBody?.velocity = CGVectorMake(0, 0)
            bird.physicsBody?.applyImpulse(CGVectorMake(0, CGFloat(energy)*0.8))
        }
  
    }
    
    
    //MARK: - Contact Delegate
    func didBeginContact(contact: SKPhysicsContact) {
        var achievements = [GKAchievement]()

        if contact.bodyA.categoryBitMask == ColliderType.Fish1.rawValue || contact.bodyB.categoryBitMask == ColliderType.Fish1.rawValue{
            if contact.bodyA.node?.name == "fish1" {
                runAction(SKAction.playSoundFileNamed("CRUNCH_I-Intermed-566_hifi.mp3", waitForCompletion: false))
            }
            contact.bodyA.node?.removeFromParent()
            if energy >= 90 {
                fullyEat++
            }else{
                fullyEat = 0
            }
            energy += 10
            eatFishCount++
            //进吃小鱼的判断
            onlySmallFish = true
            if onlyBigFish{
                isonly = false
            }
            
            energy = min(energy,100)
            progress.size.width = min(progress.size.width + 18 , 180)
            energyLabel.text = "\(energy)/100"
        }
        
        if contact.bodyA.categoryBitMask == ColliderType.Fish2.rawValue || contact.bodyB.categoryBitMask == ColliderType.Fish2.rawValue{
            if contact.bodyA.node?.name == "fish2" {
                runAction(SKAction.playSoundFileNamed("CRUNCH_I-Intermed-566_hifi.mp3", waitForCompletion: false))
            }

            contact.bodyA.node?.removeFromParent()
            if energy >= 85 {
                fullyEat++
            }else{
                fullyEat = 0
            }
            energy += 15
            eatFishCount++
            //仅吃大鱼的判断
            onlyBigFish = true
            if onlySmallFish{
                isonly = false
            }
            
            
            onlySmallFish = false
            energy = min(energy,100)
            progress.size.width = min(progress.size.width + 27 , 180)
            energyLabel.text = "\(energy)/100"
        }
        //在满能量的情况下连续吃鱼10条
        if fullyEat >= 10 {
            achievements.append(AchievementsHelper.completefullyEatAchievement())
            GameKitHelper.shareInstance.reportAchievements(achievements)
        }
        
        if contact.bodyA.categoryBitMask == ColliderType.Object.rawValue || contact.bodyB.categoryBitMask == ColliderType.Object.rawValue{
            if gameStatus != .Over {
                gameStatus = .Over
              
                //发送成就榜
                if isonly && onlyBigFish && distance >= 1000{
                    achievements.append(AchievementsHelper.completeonlyBigFishAchievement())
                }
                if isonly && onlySmallFish && distance >= 1000{
                    achievements.append(AchievementsHelper.completeonlySmallFishAchievement())
                }
                
                achievements.append(AchievementsHelper.completeJuniorAirmanAchievement(distance))
                achievements.append(AchievementsHelper.completeAirmanAchievement(distance))
                achievements.append(AchievementsHelper.completeSeniorAirmanAchievement(distance))
                achievements.append(AchievementsHelper.completeProAirmanAchievement(distance))
                GameKitHelper.shareInstance.reportAchievements(achievements)
                
                //把分数发给排行榜
                GameKitHelper.shareInstance.reportScore(Int64(distance), forLeaderBoardId: flyingLeadboardID)
                GameKitHelper.shareInstance.reportScore(Int64(eatFishCount), forLeaderBoardId: eatFishLeaderboardID)
                
                (UIApplication.sharedApplication().delegate as! AppDelegate).timer!.invalidate()
                NSUserDefaults.standardUserDefaults().setInteger(maxDistance, forKey: "maxDistance")
                NSUserDefaults.standardUserDefaults().synchronize()
                if let scene = GameStartScene(fileNamed: "GameStartScene"){
                    //碰到飓风的声音
                    if contact.bodyA.node?.name == "tornato" {
                        scene.runAction(SKAction.playSoundFileNamed("wind-Intermed-481_hifi.mp3", waitForCompletion: false))
                    }else{
                        scene.runAction(SKAction.playSoundFileNamed("Oowh_Pai-Nathan_H-7830_hifi.mp3", waitForCompletion: false))
                    }
                    scene.currentScore = distance
                    scene.bestScore = maxDistance
                    scene.gameOver = true
                    scene.scaleMode = .AspectFill
                    let transtion = SKTransition.pushWithDirection(.Down, duration: 0.5)
                    view?.presentScene(scene, transition: transtion)
                }
                
            }
        }
    }
}

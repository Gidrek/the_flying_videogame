//
//  MyScene.m
//  TheFlying
//
//  Created by Giovanni Cortes on 3/11/14.
//  Copyright (c) 2014 Giovanni Cortes. All rights reserved.
//

#import "MyScene.h"

// -----------------------------------------------------------------
# pragma mark - Enums
// -----------------------------------------------------------------

typedef NS_ENUM(int, Layer) {
    LayerBackground,
    LayerObstacle,
    LayerForeground,
    LayerEnemy,
    LayerPlayer,
    LayerUI
};

typedef NS_OPTIONS(int, EntityCategory) {
    EntityCategoryPlayer = 1 << 0,
    EntityCategoryCoin = 1 << 1,
    EntityCategoryFire = 1 << 2
};

// -----------------------------------------------------------------
# pragma mark - Constants
// -----------------------------------------------------------------

// Gameplay - Player movement
static const float kGravity = -1500.0;
static const float kImpulse = 400.0;
static const float kAcceleration = 15;

// Gameplay - Enemy movement
static const float kPositionPlayerInY = 50.0;

// Looks
static const int kMarginTop = 20;
static const int kMarginRigth = 50;
static const float kAnimDelay = 0.3;
static const int kNumPlayerFrames = 3;
static const int kNumEnemyFrames = 4;
static NSString *const kFontName = @"AmericanTypeWriter-Bold";

// Apple ID
static const int APP_STORE_ID = "YOUR APP STORE ID FOR THE GAME";

// -----------------------------------------------------------------
# pragma mark - Implementation and init
// -----------------------------------------------------------------
@interface MyScene() <SKPhysicsContactDelegate>
@end

@implementation MyScene
{
    SKNode *_worldNode;
    
    // Player
    SKSpriteNode *_player;
    CGPoint _playerVelocity;
    
    // Enemy
    SKSpriteNode *_enemy;
    NSTimeInterval _lastSpawnEnemyTimeInterval;
    
    // Coins
    NSTimeInterval _lastSpawnCoinTimeInterval;
    
    // Fire
    NSTimeInterval _lastSpawnFireTimeInterval;
    
    NSTimeInterval _lastUpdatePlayerTimeInterval;
    
    float _playableStart;
    float _playableHeight;
    
    // Sounds
    SKAction *_coinAction;
    SKAction *_popAction;
    SKAction *_hitAction;
    SKAction *_jumpAction;
    
    // Labels
    SKLabelNode *_scoreLabel;
    int _score;
    
    SKLabelNode *_coinsLabel;
    int _coins;
    
    // Time for get delta time in the update method
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    
    GameState _gameState;
    
    BOOL _hitFire;
    BOOL _hitCoin;
}

-(id)initWithSize:(CGSize)size delegate:(id<MyScenceDelegate>)delegate state:(GameState)state
{
    _delegate = delegate;
    
    if (self = [super initWithSize:size]) {
        // Initialize the worldNode and add to the view
        _worldNode = [SKNode node];
        [self addChild:_worldNode];
        
        // Motion manager for the player
        [self setupMotionManager];
        
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        
        if (state == GameStateMainMenu)
        {
            [self switchToMainMenu];
        }
        else
        {
            [self switchToTutorial];
        }
        
        
    }
    return self;
}

// -----------------------------------------------------------------
# pragma mark - Setup methods
// -----------------------------------------------------------------

-(void)setupSounds
{
    _coinAction = [SKAction playSoundFileNamed:@"coin.wav" waitForCompletion:NO];
    _popAction = [SKAction playSoundFileNamed:@"pop.wav" waitForCompletion:NO];
    _hitAction = [SKAction playSoundFileNamed:@"hitGround.wav" waitForCompletion:NO];
    _jumpAction  = [SKAction playSoundFileNamed:@"pop.wav" waitForCompletion:NO];
}

// -----------------------------------------------------------------

-(void)setupMainMenu
{
    SKSpriteNode *logo = [SKSpriteNode spriteNodeWithImageNamed:@"Logo"];
    logo.position = CGPointMake(self.size.width / 2, self.size.height * 0.7);
    logo.zPosition = LayerUI;
    
    [_worldNode addChild:logo];
    
    // Play button
    SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"Button"];
    playButton.position = CGPointMake(self.size.width * 0.25, self.size.height * 0.25);
    playButton.zPosition = LayerUI;
    
    [_worldNode addChild:playButton];
    
    SKSpriteNode *play = [SKSpriteNode spriteNodeWithImageNamed:@"Play"];
    play.position = CGPointZero;
    [playButton addChild:play];
    
    // Rate button
    SKSpriteNode *rateButton = [SKSpriteNode spriteNodeWithImageNamed:@"Button"];
    rateButton.position = CGPointMake(self.size.width * 0.75, self.size.height * 0.25);
    rateButton.zPosition = LayerUI;
    
    [_worldNode addChild:rateButton];
    
    SKSpriteNode *rate = [SKSpriteNode spriteNodeWithImageNamed:@"Rate"];
    rate.position = CGPointZero;
    [rateButton addChild:rate];
    
    
}

// -----------------------------------------------------------------

-(void)setupBackground
{
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
    background.anchorPoint = CGPointMake(0.5, 1);
    background.position = CGPointMake(self.size.width / 2, self.size.height);
    background.zPosition = LayerBackground;
    
    [_worldNode addChild:background];
    
    _playableStart = self.size.height - background.size.height;
    _playableHeight = background.size.height;
}

// -----------------------------------------------------------------

-(void)setupForeground
{
    SKSpriteNode *foreground = [SKSpriteNode spriteNodeWithImageNamed:@"Ground"];
    foreground.anchorPoint = CGPointMake(0, 1);
    foreground.position = CGPointMake(0, _playableStart);
    foreground.zPosition = LayerForeground;
    
    [_worldNode addChild:foreground];
}

-(void)setupTutorial
{
    SKSpriteNode *tutorial = [SKSpriteNode spriteNodeWithImageNamed:@"Tutorial"];
    tutorial.position = CGPointMake((int)self.size.width * 0.5, (int)_playableHeight * 0.4 + _playableStart);
    tutorial.name = @"Tutorial";
    tutorial.zPosition = LayerUI;
    [_worldNode addChild:tutorial];
    
    SKSpriteNode *ready = [SKSpriteNode spriteNodeWithImageNamed:@"Ready"];
    ready.position = CGPointMake(self.size.width * 0.5, _playableHeight * 0.7 + _playableStart);
    ready.name = @"Tutorial";
    ready.zPosition = LayerUI;
    [_worldNode addChild:ready];
}

// -----------------------------------------------------------------

-(void)setupScoreLabel
{
    _scoreLabel = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    _scoreLabel.fontColor = [SKColor colorWithRed:101.0/255 green:71.01/255 blue:73.0/255 alpha:1.0];
    _scoreLabel.position = CGPointMake(self.size.width - kMarginRigth, self.size.height - kMarginTop);
    _scoreLabel.fontSize = 14;
    _score = 0;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", _score];
    _scoreLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    _scoreLabel.zPosition =  LayerUI;
    [_worldNode addChild:_scoreLabel];
}

// -----------------------------------------------------------------

-(void)setupScoreCard
{
    if (_score > [self bestScore])
    {
        [self setBestScore:_score];
    }
    
    SKSpriteNode *scoreCard = [SKSpriteNode spriteNodeWithImageNamed:@"Scorecard"];
    scoreCard.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5);
    scoreCard.name = @"ScoreCard";
    scoreCard.zPosition = LayerUI;
    [_worldNode addChild:scoreCard];
    
    SKLabelNode *lastScore = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    lastScore.fontColor = [SKColor colorWithRed:101.0/255 green:71.0/255 blue:73.0/255 alpha:1.0];
    lastScore.position = CGPointMake(-scoreCard.size.width * 0.25, -scoreCard.size.height * 0.2);
    lastScore.text = [NSString stringWithFormat:@"%d", _score];
    [scoreCard addChild:lastScore];
    
    SKLabelNode *bestScore = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    bestScore.fontColor = [SKColor colorWithRed:101.0/255 green:71.0/255 blue:73.0/255 alpha:1.0];
    bestScore.position = CGPointMake(scoreCard.size.width * 0.25, -scoreCard.size.height * 0.2);
    bestScore.text = [NSString stringWithFormat:@"%d", [self bestScore]];
    [scoreCard addChild:bestScore];
    
    SKSpriteNode *gameOver = [SKSpriteNode spriteNodeWithImageNamed:@"GameOver"];
    gameOver.position = CGPointMake(self.size.width / 2 , self.size.height / 2 + scoreCard.size.height / 2 + kMarginTop + gameOver.size.height / 2);
    gameOver.zPosition = LayerUI;
    [_worldNode addChild:gameOver];
    
    SKSpriteNode *okButton = [SKSpriteNode spriteNodeWithImageNamed:@"Button"];
    okButton.position = CGPointMake(self.size.width * 0.25, self.size.height / 2 - scoreCard.size.height / 2 - kMarginTop - okButton.size.height / 2);
    okButton.zPosition = LayerUI;
    [_worldNode addChild:okButton];
    
    SKSpriteNode *ok = [SKSpriteNode spriteNodeWithImageNamed:@"OK"];
    ok.position = CGPointZero;
    ok.zPosition = LayerUI;
    [okButton addChild:ok];
    
    SKSpriteNode *shareButton = [SKSpriteNode spriteNodeWithImageNamed:@"Button"];
    shareButton.position = CGPointMake(self.size.width * 0.75, self.size.height / 2 - scoreCard.size.height / 2 - kMarginTop - shareButton.size.height / 2);
    shareButton.zPosition = LayerUI;
    [_worldNode addChild:shareButton];
    
    SKSpriteNode *share = [SKSpriteNode spriteNodeWithImageNamed:@"Share"];
    share.position = CGPointZero;
    share.zPosition = LayerUI;
    [shareButton addChild:share];
    
    // Animations when the scorecard is presented
    gameOver.scale = 0;
    gameOver.alpha = 0;
    SKAction *group = [SKAction group:@[
            [SKAction fadeInWithDuration:kAnimDelay],
            [SKAction scaleTo:1.0 duration:kAnimDelay]
        ]];
    
    group.timingMode = SKActionTimingEaseInEaseOut;
    [gameOver runAction:[SKAction sequence:@[
                [SKAction waitForDuration:kAnimDelay],
                group
            ]]];
    
    scoreCard.position = CGPointMake(self.size.width * 0.5, -scoreCard.size.height / 2);
    SKAction *moveTo = [SKAction moveTo:CGPointMake(self.size.width / 2, self.size.height / 2) duration:kAnimDelay];
    moveTo.timingMode = SKActionTimingEaseInEaseOut;
    [scoreCard runAction:[SKAction sequence:@[
            [SKAction waitForDuration:kAnimDelay * 2],
            moveTo
        ]]];
    
    
    okButton.alpha = 0;
    shareButton.alpha = 0;
    SKAction *fadeIn = [SKAction sequence:@[
                                            
            [SKAction waitForDuration:kAnimDelay * 3],
            [SKAction fadeInWithDuration:kAnimDelay]
        ]];
    
    [okButton runAction:fadeIn];
    [shareButton runAction:fadeIn];
    
    // Put sounds for every sprite
    SKAction *pops = [SKAction sequence:@[
            [SKAction waitForDuration:kAnimDelay],
            _popAction,
            [SKAction waitForDuration:kAnimDelay],
            _popAction,
            [SKAction waitForDuration:kAnimDelay],
            _popAction,
            [SKAction runBlock:^{
                [self switchToGameOver];
            }]
        ]];
    
    [self runAction:pops];
}


// -----------------------------------------------------------------

-(void)setupPlayer
{
    _player = [SKSpriteNode spriteNodeWithImageNamed:@"player0"];
    _player.position = CGPointMake(self.size.width * 0.2, _playableStart + _player.size.height / 2);
    _player.zPosition = LayerPlayer;
    
    [_worldNode addChild:_player];
    
    // This add the polygon for the sprite, change when the sprite changes
    CGFloat offsetX = _player.frame.size.width * _player.anchorPoint.x;
    CGFloat offsetY = _player.frame.size.height * _player.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 4 - offsetX, 8 - offsetY);
    CGPathAddLineToPoint(path, NULL, 5 - offsetX, 28 - offsetY);
    CGPathAddLineToPoint(path, NULL, 22 - offsetX, 30 - offsetY);
    CGPathAddLineToPoint(path, NULL, 28 - offsetX, 27 - offsetY);
    CGPathAddLineToPoint(path, NULL, 25 - offsetX, 13 - offsetY);
    CGPathAddLineToPoint(path, NULL, 23 - offsetX, 3 - offsetY);
    CGPathAddLineToPoint(path, NULL, 11 - offsetX, 1 - offsetY);
    
    CGPathCloseSubpath(path);
    
    _player.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    
    // Code for the collision
    [_player skt_attachDebugFrameFromPath:path color:[SKColor redColor]];
    _player.physicsBody.categoryBitMask = EntityCategoryPlayer;
    _player.physicsBody.collisionBitMask = 0;
    _player.physicsBody.contactTestBitMask = EntityCategoryCoin | EntityCategoryFire;
    
    // Add code for motion movement
    _player.physicsBody.dynamic = YES;
    _player.physicsBody.affectedByGravity = NO;
    _player.physicsBody.mass = .02;
    
}

// -----------------------------------------------------------------

-(void)setupPlayerAnimation
{
    NSMutableArray *textures = [NSMutableArray array];
    
    for (int i = 0; i < kNumPlayerFrames; i++)
    {
        NSString *textureName = [NSString stringWithFormat:@"player%d", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
        [textures addObject:texture];
    }
    
    SKAction *playerAnimation = [SKAction animateWithTextures:textures timePerFrame:0.15];
    [_player runAction:[SKAction repeatActionForever:playerAnimation]];
    
}

// -----------------------------------------------------------------

-(void)setupEnemy
{
    _enemy = [SKSpriteNode spriteNodeWithImageNamed:@"enemy0"];
    _enemy.position = CGPointMake(self.size.width / 2, self.size.height - _enemy.size.width / 2 - kPositionPlayerInY);
    _enemy.zPosition = LayerEnemy;
    
    [_worldNode addChild:_enemy];
}

// -----------------------------------------------------------------

-(void)setupEnemyAnimation
{
    NSMutableArray *textures = [NSMutableArray array];
    
    for (int i = 0; i < kNumEnemyFrames; i++)
    {
        NSString *textureName = [NSString stringWithFormat:@"enemy%d", i];
        [textures addObject:[SKTexture textureWithImageNamed:textureName]];
    }
    
    SKAction *enemyAnimation = [SKAction animateWithTextures:textures timePerFrame:0.1];
    [_enemy runAction:[SKAction repeatActionForever:enemyAnimation]];
}

// -----------------------------------------------------------------

-(void)setupMotionManager
{
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager startAccelerometerUpdates];
}

// -----------------------------------------------------------------
# pragma mark - Gameplay methods
// -----------------------------------------------------------------

-(void)jumpPlayer
{
    [_player runAction:_jumpAction];
    _playerVelocity = CGPointMake(0, kImpulse);
}

// -----------------------------------------------------------------

-(void)stopFalling
{
    [self removeActionForKey:@"CoinAction"];
    [self removeActionForKey:@"FireAction"];
    
    [_worldNode enumerateChildNodesWithName:@"Fire" usingBlock:^(SKNode *node, BOOL *stop){
        [node removeAllActions];
    }];
    
    [_worldNode enumerateChildNodesWithName:@"Coin" usingBlock:^(SKNode *node, BOOL *stop){
        [node removeAllActions];
    }];
    
    [self stopMotion];
}


// -----------------------------------------------------------------
# pragma mark - Switch state
// -----------------------------------------------------------------

-(void)switchToMainMenu
{
    _gameState = GameStateMainMenu;
    
    [self setupBackground];
    [self setupForeground];
    [self setupPlayer];
    [self setupPlayerAnimation];
    [self setupEnemy];
    [self setupEnemyAnimation];
    [self setupSounds];
    [self setupMainMenu];
}

// -----------------------------------------------------------------

-(void)switchToPlay
{
    _gameState = GameStatePlay;
    
    // Remove tutorial
    [_worldNode enumerateChildNodesWithName:@"Tutorial" usingBlock:^(SKNode *node, BOOL *stop) {
        [node runAction:[SKAction sequence:@[
                            [SKAction fadeOutWithDuration:0.5],
                            [SKAction removeFromParent]
                        ]]];
    }];
}

// -----------------------------------------------------------------

-(void)switchToTutorial
{
    _gameState = GameStateTutorial;
    [self setupBackground];
    [self setupForeground];
    [self setupPlayer];
    [self setupPlayerAnimation];
    [self setupEnemy];
    [self setupEnemyAnimation];
    [self setupSounds];
    [self setupScoreLabel];
    [self setupTutorial];
}

// -----------------------------------------------------------------

-(void)switchToShowScore
{
    _gameState = GameStateShowingScore;
    
    // Remove all actions from the player
    [_player removeAllActions];
    [self stopFalling];
    [self setupScoreCard];
}

// -----------------------------------------------------------------

-(void)switchToNewGame:(GameState)state
{
    // Put a sound
    
    SKScene *newScence = [[MyScene alloc] initWithSize:self.size delegate:self.delegate state:state];
    SKTransition *transition = [SKTransition fadeWithColor:[SKColor blackColor] duration:0.5];
    [self.view presentScene:newScence transition:transition];
}

// -----------------------------------------------------------------

-(void)switchToGameOver
{
    _gameState = GameStateGameOver;
}

// -----------------------------------------------------------------
# pragma mark - Touch events
// -----------------------------------------------------------------

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    
    switch (_gameState) {
        case GameStateMainMenu:
            if (touchLocation.x < self.size.width * 0.6)
            {
                [self switchToNewGame:GameStateTutorial];
            }
            else
            {
                [self rateApp];
            }

        case GameStateTutorial:
            [self switchToPlay];
            break;
        case GameStatePlay:
            [self jumpPlayer];
            break;
        case GameStateShowingScore:
            break;
        case GameStateGameOver:
            if (touchLocation.x < self.size.width * 0.6)
            {
                [self switchToNewGame:GameStateMainMenu];
            }
            else
            {
                [self shareScore];
            }
            break;
    }

    
}

// -----------------------------------------------------------------
# pragma mark - Motion events
// -----------------------------------------------------------------

-(void)processUserMotionForUpdate:(NSTimeInterval)currentTime
{
    CMAccelerometerData *data = self.motionManager.accelerometerData;
    
    if (data.acceleration.x < 0)
    {
        SKAction *mirrorDirection  = [SKAction scaleXTo:-1 y:1 duration:0.0];
        [_player runAction:mirrorDirection];
    }
    if (data.acceleration.x > 0)
    {
        SKAction *mirrorDirection  = [SKAction scaleXTo:1 y:1 duration:0.0];
        [_player runAction:mirrorDirection];
    }

    
    if (fabs(data.acceleration.x) > 0.2)
    {
        [_player.physicsBody applyForce:CGVectorMake(kAcceleration * data.acceleration.x, 0)];
    }
}

-(void)stopMotion
{
    [_player removeAllActions];
    [self.motionManager stopAccelerometerUpdates];
}

// -----------------------------------------------------------------
# pragma mark - Update methods
// -----------------------------------------------------------------

-(void)checkHitFire
{
    if (_hitFire)
    {
        _hitFire = NO;
        [self switchToShowScore];
    }
}

// -----------------------------------------------------------------

-(void)checkHitCoin
{
    if (_hitCoin)
    {
        _hitCoin = NO;
    }
}

// -----------------------------------------------------------------

-(void)updatePlayer
{
    // Apply gravity
    CGPoint gravity = CGPointMake(0, kGravity);
    CGPoint gravityStep = CGPointMultiplyScalar(gravity, _dt);
    _playerVelocity = CGPointAdd(_playerVelocity, gravityStep);
    
    // Apply velocity
    CGPoint velocityStep = CGPointMultiplyScalar(_playerVelocity, _dt);
    _player.position = CGPointAdd(_player.position, velocityStep);
    
    _player.position = CGPointMake(_player.position.x, MIN(_player.position.y, self.size.height));
    
    if (_player.position.y - _player.size.height / 2 <= _playableStart)
    {
        _player.position = CGPointMake(_player.position.x, _playableStart + _player.size.height / 2);
    }
    
    if (_player.position.x >= self.size.width - _player.size.width / 2)
    {
        _player.position = CGPointMake(self.size.width - _player.size.width / 2, _player.position.y);
    }
    
    if (_player.position.x <= _player.size.width / 2)
    {
        _player.position = CGPointMake(_player.size.width / 2 , _player.position.y);
    }

    
}

// -----------------------------------------------------------------

-(void)updateEnemy
{
    int minX = _enemy.size.width / 2;
    int maxX = self.frame.size.width - _enemy.size.width / 2;
    int rangeX = maxX - minX;
    int randomX = (arc4random() % rangeX) + minX;
    
    // The duration max and min of the enemy
    int minDuration = 1.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int randomDuration = (arc4random() % rangeDuration) + minDuration;
    
    // Action to move the enemy
    SKAction *actionMove = [SKAction moveTo:CGPointMake(randomX, self.size.height - _enemy.size.width / 2 - kPositionPlayerInY) duration:randomDuration];
    [_enemy runAction:actionMove];
}

// -----------------------------------------------------------------

-(void)updateCoins
{
    
    SKSpriteNode *coin = [SKSpriteNode spriteNodeWithImageNamed:@"coin"];
    
    coin.name = @"Coin";
    
    // Setup the minX and maxX where the coin going to appear
    int minX = coin.size.width / 2;
    int maxX = self.size.width - coin.size.width / 2;
    int rangeX = maxX - minX;
    int randomX = (arc4random() % rangeX) + minX;
    
    coin.position = CGPointMake(randomX, self.size.height + coin.size.width / 2);
    [_worldNode addChild:coin];
    
    // This add the polygon for the sprite, change when the sprite changes
    CGFloat offsetX = coin.frame.size.width * coin.anchorPoint.x;
    CGFloat offsetY = coin.frame.size.height * coin.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 4 - offsetX, 11 - offsetY);
    CGPathAddLineToPoint(path, NULL, 8 - offsetX, 12 - offsetY);
    CGPathAddLineToPoint(path, NULL, 12 - offsetX, 8 - offsetY);
    CGPathAddLineToPoint(path, NULL, 11 - offsetX, 4 - offsetY);
    CGPathAddLineToPoint(path, NULL, 7 - offsetX, 4 - offsetY);
    CGPathAddLineToPoint(path, NULL, 4 - offsetX, 6 - offsetY);
    
    CGPathCloseSubpath(path);
    
    coin.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    
    // Code for collision
    [coin skt_attachDebugFrameFromPath:path color:[SKColor redColor]];
    coin.physicsBody.categoryBitMask = EntityCategoryCoin;
    coin.physicsBody.collisionBitMask = 0;
    coin.physicsBody.contactTestBitMask = EntityCategoryPlayer;
    
    int minDuration = 2.0;
    int maxDuration = 10.0;
    int rangeDuration = maxDuration - minDuration;
    int randomDuration = (arc4random() % rangeDuration) + minDuration;
    SKAction *scoreMinus = [SKAction runBlock:^{
        [self scoreMinusOne];
    }];
    SKAction *actionMove = [SKAction moveTo:CGPointMake(randomX, -100) duration:randomDuration];
    SKAction *actionDone = [SKAction removeFromParent];
    [coin runAction:[SKAction sequence:@[actionMove,scoreMinus, actionDone]] withKey:@"CoinAction"];
}

// -----------------------------------------------------------------

-(void)updateFire
{
    // Create the sprite
    SKSpriteNode *fire = [SKSpriteNode spriteNodeWithImageNamed:@"spark"];
    NSString *myParticlePath = [[NSBundle mainBundle] pathForResource:@"MyParticle" ofType:@"sks"];
    SKEmitterNode *myParticle = [NSKeyedUnarchiver unarchiveObjectWithFile:myParticlePath];
    
    myParticle.name = @"Fire";
    
    // Add the position of the projectile where is the enemy
    myParticle.position = CGPointMake(_enemy.position.x, self.size.height - kPositionPlayerInY - _enemy.size.height / 2);
    fire.position = CGPointMake(_enemy.position.x, self.size.height - kPositionPlayerInY - _enemy.size.height / 2);
    [_worldNode addChild:myParticle];
    
    // This add the polygon for the sprite, change when the sprite changes
    CGFloat offsetX = (myParticle.frame.size.width + 40) * fire.anchorPoint.x;
    CGFloat offsetY = (myParticle.frame.size.height + 20) * fire.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 13 - offsetX, 21 - offsetY);
    CGPathAddLineToPoint(path, NULL, 12 - offsetX, 9 - offsetY);
    CGPathAddLineToPoint(path, NULL, 21 - offsetX, 6 - offsetY);
    CGPathAddLineToPoint(path, NULL, 25 - offsetX, 15 - offsetY);
    CGPathAddLineToPoint(path, NULL, 19 - offsetX, 20 - offsetY);
    
    CGPathCloseSubpath(path);
    
    myParticle.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    
    // Code for collision
    [myParticle skt_attachDebugFrameFromPath:path color:[SKColor redColor]];
    myParticle.physicsBody.categoryBitMask = EntityCategoryFire;
    myParticle.physicsBody.collisionBitMask = 0;
    myParticle.physicsBody.contactTestBitMask = EntityCategoryPlayer;
    
    // Duration of the fire
    int minDuration = 4.0;
    int maxDuration = 10.0;
    int rangeDuration = maxDuration - minDuration;
    int randomDuration = (arc4random() % rangeDuration) + minDuration;
    
    SKAction *actionMove = [SKAction moveTo:CGPointMake(_enemy.position.x, -100) duration:randomDuration];
    SKAction *actionRemove = [SKAction removeFromParent];
    [myParticle runAction:[SKAction sequence:@[actionMove,actionRemove]] withKey:@"FireAction"];
}

// -----------------------------------------------------------------

-(void)update:(CFTimeInterval)currentTime
{
    if (_lastUpdateTime)
    {
        _dt = currentTime - _lastUpdateTime;
    }
    else
    {
        _dt = 0;
    }
    
    
    _lastUpdateTime = currentTime;
    
    switch (_gameState) {
        case GameStateMainMenu:
            break;
        case GameStateTutorial:
            break;
        case GameStatePlay:
            [self updatePlayer];
            [self updateEnemyWithTimeSinceLastUpdate:_dt];
            [self updateCoinWithTimeSiceLastUpdate:_dt];
            [self updateFireWithTimeSiceLastUpdate:_dt];
            [self processUserMotionForUpdate:currentTime];
            [self checkHitCoin];
            [self checkHitFire];
            break;
        case GameStateShowingScore:
            break;
        case GameStateGameOver:
            break;
    }
    
    
}

// -----------------------------------------------------------------

// Update the monster every second using the delta time
- (void)updateEnemyWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast
{
    
    _lastSpawnEnemyTimeInterval += timeSinceLast;
    if (_lastSpawnEnemyTimeInterval > 1) {
        _lastSpawnEnemyTimeInterval = 0;
        [self updateEnemy];
    }
}

// -----------------------------------------------------------------

-(void)updateCoinWithTimeSiceLastUpdate:(CFTimeInterval)timeSinceLast
{
    int minInterval = 6.0;
    int maxInterval = 15.0;
    int rangeInterval = maxInterval - minInterval;
    float randomInterval = (arc4random() % rangeInterval) + minInterval;
    
    _lastSpawnCoinTimeInterval += timeSinceLast;
    if (_lastSpawnCoinTimeInterval > randomInterval) {
        _lastSpawnCoinTimeInterval = 0;
        [self updateCoins];
    }
}

// -----------------------------------------------------------------

-(void)updateFireWithTimeSiceLastUpdate:(CFTimeInterval)timeSinceLast
{
    int minInterval = 2.0;
    int maxInterval = 12.0;
    int rangeInterval = maxInterval - minInterval;
    float randomInterval = (arc4random() % rangeInterval) + minInterval;
    
    _lastSpawnFireTimeInterval += timeSinceLast;
    if (_lastSpawnFireTimeInterval > randomInterval) {
        _lastSpawnFireTimeInterval = 0;
        [self updateFire];
    }
}


// -----------------------------------------------------------------
# pragma mark - Collision Detection
// -----------------------------------------------------------------

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *other = (contact.bodyA.categoryBitMask == EntityCategoryPlayer ? contact.bodyB: contact.bodyA);
    
    if (other.categoryBitMask == EntityCategoryFire)
    {
        [self runAction:_hitAction];
        _hitFire = YES;
        return;
    }
    if (other.categoryBitMask == EntityCategoryCoin)
    {
        [self runAction:_coinAction];
        [contact.bodyB.node removeFromParent];
        _hitCoin = YES;
        _score++;
        [_scoreLabel setText:[NSString stringWithFormat:@"Score: %d", _score]];
        return;
    }
}

// -----------------------------------------------------------------
# pragma mark - Score
// -----------------------------------------------------------------

-(void)scoreMinusOne
{
    _score--;
    [_scoreLabel setText:[NSString stringWithFormat:@"Score: %d", _score]];
}

// -----------------------------------------------------------------

-(int)bestScore
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"BestScore"];
}

-(void)setBestScore:(int)bestScore
{
    [[NSUserDefaults standardUserDefaults] setInteger:bestScore forKey:@"BestScore"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// -----------------------------------------------------------------
# pragma mark - Special
// -----------------------------------------------------------------

-(void)shareScore
{
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%d?mt=8", APP_STORE_ID];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    UIImage *screenshot = [self.delegate screenshot];
    
    NSString *initialTextString = [NSString stringWithFormat:@"OMG! I scored %d point in The Flying Videogame", _score];
    
    [self.delegate shareString:initialTextString url:url image:screenshot];
}

// -----------------------------------------------------------------

-(void)rateApp
{
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%d?mt=8", APP_STORE_ID];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    [[UIApplication sharedApplication] openURL:url];
}

@end

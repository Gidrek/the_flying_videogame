//
//  MyScene.h
//  TheFlying
//

//  Copyright (c) 2014 Giovanni Cortes. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <CoreMotion/CoreMotion.h>

typedef NS_ENUM(int, GameState) {
    GameStateMainMenu,
    GameStateTutorial,
    GameStatePlay,
    GameStateShowingScore,
    GameStateGameOver
};

@protocol MyScenceDelegate
-(UIImage *)screenshot;
-(void)shareString:(NSString *)string url:(NSURL *)url image:(UIImage *)image;
@end

@interface MyScene : SKScene

@property(strong) CMMotionManager *motionManager;

-(id)initWithSize:(CGSize)size delegate:(id<MyScenceDelegate>)delegate state:(GameState)state;

@property(strong, nonatomic) id<MyScenceDelegate>delegate;

@end

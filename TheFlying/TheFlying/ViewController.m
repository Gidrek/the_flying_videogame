//
//  ViewController.m
//  TheFlying
//
//  Created by Giovanni Cortes on 3/11/14.
//  Copyright (c) 2014 Giovanni Cortes. All rights reserved.
//

#import "ViewController.h"
#import "MyScene.h"

@interface ViewController() <MyScenceDelegate>
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = NO;
    skView.showsNodeCount = NO;
    
    // Create and configure the scene.
    SKScene * scene = [[MyScene alloc] initWithSize:skView.bounds.size delegate:self state:GameStateMainMenu];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(UIImage *)screenshot
{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 1.0);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

-(void)shareString:(NSString *)string url:(NSURL *)url image:(UIImage *)image
{
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[string, url, image] applicationActivities:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

@end

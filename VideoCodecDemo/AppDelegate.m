//
//  AppDelegate.m
//  VideoCodecDemo
//
//  Created by 李贺 on 2020/6/17.
//  Copyright © 2020 李贺. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"


@interface AppDelegate ()
@property(nonatomic, strong) UIWindow * mainWin;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.mainWin = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    ViewController *vc = [[ViewController alloc]init];
    self.mainWin.rootViewController = vc;
    [self.mainWin makeKeyAndVisible];
    return YES;
}




@end

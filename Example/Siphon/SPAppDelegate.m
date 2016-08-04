//
//  SPAppDelegate.m
//  Siphon
//
//  Created by Ali Roberts on 01/14/2016.
//  Copyright (c) 2016 Ali Roberts. All rights reserved.
//

#import "SPAppDelegate.h"
#import <Siphon/SPAppViewController.h>
#import <Siphon/SPDevelopmentAppViewController.h>
#import "SPConfig.h"

@implementation SPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    
    if (SP_SUBMISSION_ID) {
        SPAppViewController *appViewController;
        
        if (SP_CUSTOM_HOST) {
            appViewController = [[SPAppViewController alloc] initWithAppId:SP_APP_ID andSubmissionId:SP_SUBMISSION_ID andHost:SP_CUSTOM_HOST];
        } else {
            appViewController = [[SPAppViewController alloc] initWithAppId:SP_APP_ID andSubmissionId:SP_SUBMISSION_ID];
        }
        self.window.rootViewController = appViewController;
    } else {
        SPDevelopmentAppViewController *appViewController;
        
        if (SP_CUSTOM_HOST) {
            appViewController = [[SPDevelopmentAppViewController alloc] initWithAppId:SP_APP_ID andAuthToken:SP_AUTH_TOKEN andDelegate:nil andHost:SP_CUSTOM_HOST sandboxMode:NO devMode:SP_DEV_MODE];
        } else {
            appViewController = [[SPDevelopmentAppViewController alloc] initWithAppId:SP_APP_ID andAuthToken:SP_AUTH_TOKEN andDelegate:nil sandboxMode:NO devMode:SP_DEV_MODE];
        }
        self.window.rootViewController = appViewController;
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

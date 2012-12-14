//
//  AppDelegate.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2012, Davide Casali, Marco Colombo, Alessandro Morandi
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of
//  conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials
//  provided with the distribution.
//  Neither the name of the Baker Framework nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "Constants.h"

#import "AppDelegate.h"
#import "UICustomNavigationController.h"
#import "UICustomNavigationBar.h"
#import "ShelfManager.h"
#import "Reachability.h"

#ifdef BAKER_NEWSSTAND
#import "IssuesManager.h"
#endif

#ifdef PARSE_SUPPORT
#import "Parse/Parse.h"
#endif

#import "BakerViewController.h"

@implementation AppDelegate

@synthesize window;
@synthesize rootViewController;
@synthesize rootNavigationController;

#ifdef GOOGLE_ANALYTICS
@synthesize tracker = tracker_;
#endif


+ (void)initialize {
    // Set user agent (the only problem is that we can't modify the User-Agent later in the program)
    // We use a more browser-like User-Agent in order to allow browser detection scripts to run (like Tumult Hype).
    NSDictionary *userAgent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Mozilla/5.0 (compatible; BakerFramework) AppleWebKit/533.00+ (KHTML, like Gecko) Mobile", @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:userAgent];
    [userAgent release];
}

- (void)dealloc
{
    #ifdef GOOGLE_ANALYTICS
        [tracker_ release];
    #endif
    
    [window release];
    [rootViewController release];
    [rootNavigationController release];

    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[InterceptorWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
                                
    #ifdef PARSE_SUPPORT
    
        #warning Newsstand: Remember to set the below item to NO for Production Push Notification usage.
        // Development Only.  Set to NO for Production.
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NKDontThrottleNewsstandContentNotifications"];
    
        // PARSE FRAMEWORK SETUP
        [Parse setApplicationId: PARSE_APPLICATION_ID
                      clientKey: PARSE_CLIENT_KEY];
        
        // Register for push notifications
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeNewsstandContentAvailability|UIRemoteNotificationTypeAlert];

        // check if the application will run in background after being called by a push notification
        NSDictionary *payload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    
        if(payload) {
            NSLog(@"%@",payload);
            
            NSDictionary *aps = (NSDictionary *)[payload objectForKey:@"aps"];
            
            NSLog(@"%@",aps);
            
            // Now check if it is new content; if so we show an alert
            if ([aps objectForKey:@"content-available"])
            {
                if([[UIApplication sharedApplication] applicationState]==UIApplicationStateActive) {
                    // active app -> display an alert
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New MagRocket Issue"
                                                                    message:@"There is a new issue available.  Click on the refresh icon to update the shelf view and download."
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Close"
                                                          otherButtonTitles:nil];
                    [alert show];
                    [alert release];
                } else {
                    // inactive app -> do something else (e.g. download the latest issue)
                    // schedule for issue downloading in background
                    // in this tutorial we hard-code background download of magazine-2, but normally the magazine to be downloaded
                    // has to be provided in the push notification custom payload
                    
                    //NKIssue *issue4 = [[NKLibrary sharedLibrary] issueWithName:@"Magazine-2"];
                    //if(issue4) {
                    //    NSURL *downloadURL = [NSURL URLWithString:@"http://www.viggiosoft.com/media/data/blog/newsstand/magazine-2.pdf"];
                    //    NSURLRequest *req = [NSURLRequest requestWithURL:downloadURL];
                    //    NKAssetDownload *assetDownload = [issue4 addAssetWithRequest:req];
                    //    [assetDownload downloadWithDelegate:store];
                    //}
                }
            }
            else{
                // This is not a content-available push.  Handle Normally.
                [PFPush handlePush:payload];
            }
        }

    #endif

    #ifdef GOOGLE_ANALYTICS
        [GAI sharedInstance].debug = NO;
        [GAI sharedInstance].dispatchInterval = GOOGLE_DISPATCH_PERIOD_SECONDS;
        [GAI sharedInstance].trackUncaughtExceptions = YES;
        self.tracker = [[GAI sharedInstance] trackerWithTrackingId:GOOGLE_WEB_PROPERTY_ID];
    #endif
    
    #ifdef BAKER_NEWSSTAND

    NSLog(@"====== Newsstand is enabled ======");
    IssuesManager *issuesManager = [[[IssuesManager alloc] initWithURL:NEWSSTAND_MANIFEST_URL] autorelease];
    [issuesManager refresh];
    NSArray *books = issuesManager.issues;
    self.rootViewController = [[[ShelfViewController alloc] initWithBooks:books] autorelease];

    // Enable payment queue for In-App Purchases
    [[SKPaymentQueue defaultQueue] addTransactionObserver:(ShelfViewController *)self.rootViewController];

    #else

    NSLog(@"====== Newsstand is not enabled ======");
    NSArray *books = [ShelfManager localBooksList];
    if ([books count] == 1) {
        self.rootViewController = [[[BakerViewController alloc] initWithBook:[[books objectAtIndex:0] bakerBook]] autorelease];
    } else  {
        self.rootViewController = [[[ShelfViewController alloc] initWithBooks:books] autorelease];
    }

    #endif

    self.rootNavigationController = [[UICustomNavigationController alloc] initWithRootViewController:self.rootViewController];
    UICustomNavigationBar *navigationBar = (UICustomNavigationBar *)self.rootNavigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"navigation-bar-bg.png"] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setTintColor:[UIColor clearColor]];

    self.window.rootViewController = self.rootNavigationController;
    [self.window makeKeyAndVisible];
    
    //From Viggiosoft.com Tutorial.  Investigate if this needs to be implemented.
    //#ifdef BAKER_NEWSSTAND
    //    //Check for existing pending downloads.  If any exist, reconnect them to the download delegate.
    //    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    //    for(NKAssetDownload *asset in [nkLib downloadingAssets]) {
    //        [asset downloadWithDelegate:store];
    //    }
    //#endif

    return YES;
}

#ifdef PARSE_SUPPORT
    - (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
    {
        // Send parse the device token
        [PFPush storeDeviceToken:newDeviceToken];
        
        // Subscribe this user to the broadcast channel, ""
        [PFPush subscribeToChannelInBackground:@"" block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"Successfully subscribed to the broadcast channel.");
            } else {
                NSLog(@"Failed to subscribe to the broadcast channel.");
            }
        }];
    }

    -(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {       
        NSDictionary *aps = (NSDictionary *)[userInfo objectForKey:@"aps"];
        
        NSLog(@"%@",aps);
        
        // Now check if it is new content; if so we show an alert
        if ([aps objectForKey:@"content-available"])
        {
            if([[UIApplication sharedApplication] applicationState]==UIApplicationStateActive) {
                // active app -> display an alert
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New MagRocket Issue"
                                                                message:@"There is a new issue available.  Click on the refresh icon to update the shelf view and download."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Close"
                                                      otherButtonTitles:nil];
                [alert show];
                [alert release];
            } else {
                // inactive app -> do something else (e.g. download the latest issue)
                // schedule for issue downloading in background
                // in this tutorial we hard-code background download of magazine-2, but normally the magazine to be downloaded
                // has to be provided in the push notification custom payload
                
                //NKIssue *issue4 = [[NKLibrary sharedLibrary] issueWithName:@"Magazine-2"];
                //if(issue4) {
                //    NSURL *downloadURL = [NSURL URLWithString:@"http://www.viggiosoft.com/media/data/blog/newsstand/magazine-2.pdf"];
                //    NSURLRequest *req = [NSURLRequest requestWithURL:downloadURL];
                //    NKAssetDownload *assetDownload = [issue4 addAssetWithRequest:req];
                //    [assetDownload downloadWithDelegate:store];
                //}
            }
        }
        else{
            // This is not a content-available push.  Handle Normally.
            [PFPush handlePush:userInfo];
        }
    }
#endif

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationWillResignActiveNotification" object:nil];
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

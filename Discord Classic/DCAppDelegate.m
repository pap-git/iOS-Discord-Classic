//
//  DCAppDelegate.m
//  Discord Classic
//
//  Created by Julian Triveri on 3/2/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import "DCAppDelegate.h"
#import "DCServerCommunicator.h"

@interface DCAppDelegate()
@property bool shouldReload;
@end

@implementation DCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOption{
	self.window.backgroundColor = [UIColor clearColor];
	self.window.opaque = NO;
	
	self.shouldReload = false;
	
	[UINavigationBar.appearance setBackgroundImage:[UIImage imageNamed:@"TbarBG"] forBarMetrics:UIBarMetricsDefault];
    
    NSURLCache *urlCache = [[NSURLCache alloc] initWithMemoryCapacity:1024*1024*8  // 8MB mem cache
                                                         diskCapacity:1024*1024*60 // 60MB disk cache
                                                             diskPath:nil];
    [NSURLCache setSharedURLCache:urlCache];
    //[urlCache release];
	
	if(DCServerCommunicator.sharedInstance.token.length)
		[DCServerCommunicator.sharedInstance startCommunicator];
	
	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application{
	NSLog(@"Will resign active");
}


- (void)applicationDidEnterBackground:(UIApplication *)application{
	NSLog(@"Did enter background");
	self.shouldReload = DCServerCommunicator.sharedInstance.didAuthenticate;
}


- (void)applicationWillEnterForeground:(UIApplication *)application{
	NSLog(@"Will enter foreground");
}


- (void)applicationDidBecomeActive:(UIApplication *)application{
	NSLog(@"Did become active");
	if(self.shouldReload){
		[DCServerCommunicator.sharedInstance sendResume];
	}
}


- (void)applicationWillTerminate:(UIApplication *)application{
	NSLog(@"Will terminate");
}

@end

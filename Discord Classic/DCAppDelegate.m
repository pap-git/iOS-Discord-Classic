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
	
	[UINavigationBar.appearance setBackgroundImage:[UIImage imageNamed:@"UINavigationBarTexture"] forBarMetrics:UIBarMetricsDefault];
    
    NSURLCache *urlCache = [[NSURLCache alloc] initWithMemoryCapacity:1024*1024*20 // 20MB mem cache
                                                         diskCapacity:1024*1024*60 // 60MB disk cache
                                                             diskPath:nil];
    [NSURLCache setSharedURLCache:urlCache];
    //[urlCache release];
	
	if(DCServerCommunicator.sharedInstance.token.length)
		[DCServerCommunicator.sharedInstance startCommunicator];
	
	return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if (application.applicationState == UIApplicationStateActive) {
        // Extract the sender's name from the alertBody
        NSString *alertBody = notification.alertBody;
        NSRange separatorRange = [alertBody rangeOfString:@": "];
        NSString *senderName = (separatorRange.location != NSNotFound) ? [alertBody substringToIndex:separatorRange.location] : @"New Message";
        NSString *messageContent = (separatorRange.location != NSNotFound) ? [alertBody substringFromIndex:separatorRange.location + 2] : alertBody;
        
        // Create custom notification view
        UIView *notificationView = [[UIView alloc] initWithFrame:CGRectMake(0, -100, self.window.frame.size.width, 100)];
        
        // Gradient background
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = notificationView.bounds;
        gradient.colors = @[(id)[UIColor blackColor].CGColor, (id)[UIColor darkGrayColor].CGColor];
        [notificationView.layer insertSublayer:gradient atIndex:0];
        
        // Rounded corners & shadow
        notificationView.layer.cornerRadius = 10;
        notificationView.clipsToBounds = YES;
        notificationView.layer.shadowColor = [UIColor blackColor].CGColor;
        notificationView.layer.shadowOpacity = 0.3;
        notificationView.layer.shadowOffset = CGSizeMake(0, 2);
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, self.window.frame.size.width - 20, 30)];
        titleLabel.text = senderName;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [notificationView addSubview:titleLabel];
        
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 60, self.window.frame.size.width - 20, 30)];
        messageLabel.text = messageContent;
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont systemFontOfSize:16];
        [notificationView addSubview:messageLabel];
        
        // Add Tap Gesture to dismiss
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissNotification:)];
        [notificationView addGestureRecognizer:tapGesture];
        
        // Add Swipe Up Gesture to dismiss
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissNotification:)];
        swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
        [notificationView addGestureRecognizer:swipeGesture];
        
        [self.window addSubview:notificationView];
        
        // Animate notification view
        [UIView animateWithDuration:0.5 animations:^{
            notificationView.frame = CGRectMake(0, 0, self.window.frame.size.width, 100);
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissNotificationWithView:notificationView];
            });
        }];
    }
}

- (void)dismissNotification:(UIGestureRecognizer *)gestureRecognizer {
    UIView *notificationView = gestureRecognizer.view;
    [self dismissNotificationWithView:notificationView];
}

- (void)dismissNotificationWithView:(UIView *)notificationView {
    [UIView animateWithDuration:0.5 animations:^{
        notificationView.frame = CGRectMake(0, -100, self.window.frame.size.width, 100);
    } completion:^(BOOL finished) {
        [notificationView removeFromSuperview];
    }];
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

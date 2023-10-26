//
//  DCMessage.m
//  Discord Classic
//
//  Created by Julian Triveri on 4/7/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import "DCMessage.h"
#import "DCServerCommunicator.h"
#import "DCTools.h"

@implementation DCMessage

- (void)deleteMessage{
    dispatch_queue_t apiQueue = dispatch_queue_create([[NSString stringWithFormat:@"Discord::API::Event::deleteMessage%i", arc4random_uniform(4)] UTF8String], NULL);
	dispatch_async(apiQueue, ^{
		NSURL* messageURL = [NSURL URLWithString: [NSString stringWithFormat:@"https://discordapp.com/api/v6/channels/%@/messages/%@", DCServerCommunicator.sharedInstance.selectedChannel.snowflake, self.snowflake]];
		
		NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:messageURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
		
		[urlRequest setHTTPMethod:@"DELETE"];
		
		[urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
		[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		
		
		/*NSError *error = nil;
		NSHTTPURLResponse *responseCode = nil;
        int attempts = 0;
        while (attempts == 0 || (attempts <= 10 && error.code == NSURLErrorTimedOut)) {
            attempts++;
            error = nil;
            [UIApplication sharedApplication].networkActivityIndicatorVisible++;
            [DCTools checkData:[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error] withError:error];
            [UIApplication sharedApplication].networkActivityIndicatorVisible--;*/
            dispatch_sync(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible++;
            });
            [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connError) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if ([UIApplication sharedApplication].networkActivityIndicatorVisible > 0)
                        [UIApplication sharedApplication].networkActivityIndicatorVisible--;
                    else if ([UIApplication sharedApplication].networkActivityIndicatorVisible < 0)
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = 0;
                });

            }];
        //}
	});
    dispatch_release(apiQueue);
}

- (BOOL)isEqual:(id)other{
	if (!other || ![other isKindOfClass:DCMessage.class])
		return NO;
	
	return [self.snowflake isEqual:((DCMessage*)other).snowflake];
}

@end

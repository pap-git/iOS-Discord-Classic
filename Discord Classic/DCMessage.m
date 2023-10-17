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
	//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		NSURL* messageURL = [NSURL URLWithString: [NSString stringWithFormat:@"https://discordapp.com/api/v6/channels/%@/messages/%@", DCServerCommunicator.sharedInstance.selectedChannel.snowflake, self.snowflake]];
		
		NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:messageURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:1];
		
		[urlRequest setHTTPMethod:@"DELETE"];
		
		[urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
		[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		
		
		NSError *error = nil;
		NSHTTPURLResponse *responseCode = nil;
        int attempts = 0;
        while (attempts == 0 || (attempts <= 10 && error.code == NSURLErrorTimedOut)) {
            attempts++;
            error = nil;
            /*[UIApplication sharedApplication].networkActivityIndicatorVisible++;
            [DCTools checkData:[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error] withError:error];
            [UIApplication sharedApplication].networkActivityIndicatorVisible--;*/
            NSLog(@"Showing network indicator (deleteMessage) %d", (int)[UIApplication sharedApplication].networkActivityIndicatorVisible);
            [UIApplication sharedApplication].networkActivityIndicatorVisible++;
            [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connError) {
                NSLog(@"Showing network indicator (deleteMessage) %d", (int)[UIApplication sharedApplication].networkActivityIndicatorVisible);
                [UIApplication sharedApplication].networkActivityIndicatorVisible--;
            }];
        }
	//});
}

- (BOOL)isEqual:(id)other{
	if (!other || ![other isKindOfClass:DCMessage.class])
		return NO;
	
	return [self.snowflake isEqual:((DCMessage*)other).snowflake];
}

@end

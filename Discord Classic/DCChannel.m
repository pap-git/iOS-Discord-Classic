//
//  DCChannel.m
//  Discord Classic
//
//  Created by Julian Triveri on 3/12/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import "DCChannel.h"
#import "DCServerCommunicator.h"
#import "DCTools.h"

@interface DCChannel()

@property NSURLConnection *connection;

@end

@implementation DCChannel

-(NSString *)description{
	return [NSString stringWithFormat:@"[Channel] Snowflake: %@, Type: %i, Read: %d, Name: %@", self.snowflake, self.type, self.unread, self.name];
}

-(void)checkIfRead{
    @try {
        self.unread = (!self.muted && self.lastReadMessageId != (id)NSNull.null && ![self.lastReadMessageId    isEqualToString:self.lastMessageId]);
        [self.parentGuild checkIfRead];
    } @catch(NSException* e) {}
}



- (void)sendMessage:(NSString*)message {
	//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		NSURL* channelURL = [NSURL URLWithString: [NSString stringWithFormat:@"https://discordapp.com/api/channels/%@/messages", self.snowflake]];
		
		NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:channelURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
        
        NSString* escapedMessage = [message mutableCopy];
        
        CFStringRef transform = CFSTR("Any-Hex/Java");
        CFStringTransform((__bridge CFMutableStringRef)escapedMessage, NULL, transform, NO);
		
		NSString* messageString = [NSString stringWithFormat:@"{\"content\":\"%@\"}", escapedMessage];
		
		[urlRequest setHTTPMethod:@"POST"];
		
		[urlRequest setHTTPBody:[NSData dataWithBytes:[messageString UTF8String] length:[messageString length]]];
		[urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
		[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		NSError *error = nil;
		NSHTTPURLResponse *responseCode = nil;
        /*[UIApplication sharedApplication].networkActivityIndicatorVisible++;
        [DCTools checkData:[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error] withError:error];
            [UIApplication sharedApplication].networkActivityIndicatorVisible--;*/
        NSLog(@"Showing network indicator (sendMessage) %d", (int)[UIApplication sharedApplication].networkActivityIndicatorVisible);
        [UIApplication sharedApplication].networkActivityIndicatorVisible++;
        [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connError) {
            NSLog(@"Hiding network indicator (sendMessage) %d", (int)[UIApplication sharedApplication].networkActivityIndicatorVisible);
            [UIApplication sharedApplication].networkActivityIndicatorVisible--;
        }];
	//});
}



- (void)sendImage:(UIImage*)image {
	//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSURL* channelURL = [NSURL URLWithString: [NSString stringWithFormat:@"https://discordapp.com/api/channels/%@/messages", self.snowflake]];
		
		NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:channelURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:1];
		
		[urlRequest setHTTPMethod:@"POST"];
		
		NSString *boundary = @"---------------------------14737809831466499882746641449";
		
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
		[urlRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
		[urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
		
		NSMutableData *postbody = NSMutableData.new;
		[postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"upload.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[NSData dataWithData:UIImageJPEGRepresentation(image, 0.9f)]];
		[postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[@"Content-Disposition: form-data; name=\"content\"\r\n\r\n " dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		[urlRequest setHTTPBody:postbody];
		
        NSError *error = nil;
		NSHTTPURLResponse *responseCode = nil;
        int attempts = 0;
        while (attempts == 0 || (attempts <= 10 && error.code == NSURLErrorTimedOut)) {
            attempts++;
            error = nil;
            //[DCTools checkData:[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error] withError:error];
            //[UIApplication sharedApplication].networkActivityIndicatorVisible--;
            NSLog(@"Showing network indicator (sendImage) %d", (int)[UIApplication sharedApplication].networkActivityIndicatorVisible);
            [UIApplication sharedApplication].networkActivityIndicatorVisible++;
            [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connError) {
                NSLog(@"Hiding network indicator (sendImage) %d", (int)[UIApplication sharedApplication].networkActivityIndicatorVisible);
                [UIApplication sharedApplication].networkActivityIndicatorVisible--;
            }];
        }
	//});
}

- (void)sendTypingIndicator{
    NSURL* channelURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://discordapp.com/api/channels/%@/typing", self.snowflake]];
    
    NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:channelURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
    
    [urlRequest setHTTPMethod:@"POST"];
    
    [urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connError) {
        //[UIApplication sharedApplication].networkActivityIndicatorVisible--;
    }];
}

- (void)ackMessage:(NSString*)messageId{
	self.lastReadMessageId = messageId;
	
	//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		NSURL* channelURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://discordapp.com/api/channels/%@/messages/%@/ack", self.snowflake, messageId]];
		
		NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:channelURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
		
		[urlRequest setHTTPMethod:@"POST"];
		
		[urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
		[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		NSError *error = nil;
		NSHTTPURLResponse *responseCode = nil;
        int attempts = 0;
        while (attempts == 0 || (attempts <= 10 && error.code == NSURLErrorTimedOut)) {
            attempts++;
            error = nil;
            //[UIApplication sharedApplication].networkActivityIndicatorVisible++;
            //[DCTools checkData:[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error] withError:error];
            
            //[UIApplication sharedApplication].networkActivityIndicatorVisible--;
            //[UIApplication sharedApplication].networkActivityIndicatorVisible++;
            [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connError) {
                //[UIApplication sharedApplication].networkActivityIndicatorVisible--;
            }];
        }
	//});
}



- (NSArray*)getMessages:(int)numberOfMessages beforeMessage:(DCMessage*)message{
	
	NSMutableArray* messages = NSMutableArray.new;
	
	//Generate URL from args
	NSMutableString* getChannelAddress = [[NSString stringWithFormat: @"https://discordapp.com/api/channels/%@/messages?", self.snowflake] mutableCopy];
	
	if(numberOfMessages)
		[getChannelAddress appendString:[NSString stringWithFormat:@"limit=%i", numberOfMessages]];
	if(numberOfMessages && message)
		[getChannelAddress appendString:@"&"];
	if(message)
		[getChannelAddress appendString:[NSString stringWithFormat:@"before=%@", message.snowflake]];
    
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:getChannelAddress] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:1];
	
	[urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
	[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	
	NSError *error = nil;
    NSHTTPURLResponse *responseCode = nil;
    int attempts = 0;
    while (attempts == 0 || (attempts <= 10 && error.code == NSURLErrorTimedOut)) {
        attempts++;
        error = nil;
        NSLog(@"Showing network indicator (getMessages) %d", (int)[UIApplication sharedApplication].networkActivityIndicatorVisible);
        [UIApplication sharedApplication].networkActivityIndicatorVisible++;
        NSData *response = [DCTools checkData:[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error] withError:error];
        NSLog(@"Showing network indicator (getMessages) %d", (int)[UIApplication sharedApplication].networkActivityIndicatorVisible);
        [UIApplication sharedApplication].networkActivityIndicatorVisible--;
        if(response){
            NSArray* parsedResponse = [NSJSONSerialization JSONObjectWithData:response options:0 error:&error];
		
            if(parsedResponse.count > 0)
                for(NSDictionary* jsonMessage in parsedResponse)
                    [messages insertObject:[DCTools convertJsonMessage:jsonMessage] atIndex:0];
		
            for (int i=0; i < messages.count; i++)
            {
                DCMessage* prevMessage;
                if (i==0)
                    prevMessage = message;
                else
                    prevMessage = messages[i-1];
                DCMessage* currentMessage = messages[i];
                if (prevMessage != nil) {
                    NSDateComponents* curComponents = [[NSCalendar currentCalendar] components:kCFCalendarUnitHour | kCFCalendarUnitDay | kCFCalendarUnitMonth | kCFCalendarUnitYear fromDate:currentMessage.timestamp];
                    NSDateComponents* prevComponents = [[NSCalendar currentCalendar] components:kCFCalendarUnitHour | kCFCalendarUnitDay | kCFCalendarUnitMonth | kCFCalendarUnitYear fromDate:prevMessage.timestamp];
               
                    if (prevMessage.author.snowflake == currentMessage.author.snowflake
                        && (curComponents.minute - prevComponents.minute < 10)
                        && curComponents.hour == prevComponents.hour
                        && curComponents.day == prevComponents.day
                        && curComponents.month == prevComponents.month
                        && curComponents.year == prevComponents.year) {
                        currentMessage.isGrouped = currentMessage.referencedMessage == nil;
                   
                        if (currentMessage.isGrouped) {
                            float contentWidth = UIScreen.mainScreen.bounds.size.width - 63;
                            CGSize authorNameSize = [currentMessage.author.globalName sizeWithFont:[UIFont boldSystemFontOfSize:15] constrainedToSize:CGSizeMake(contentWidth, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
                       
                            currentMessage.contentHeight -= authorNameSize.height + 4;
                        }
                    }
                }
            }
            
            if(messages.count > 0)
                return messages;
            
            [DCTools alert:@"No messages!" withMessage:@"No further messages could be found"];
        }
    }
	
	return nil;
}


@end

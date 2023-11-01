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
    dispatch_async(dispatch_get_main_queue(), ^{
    @try {
        self.unread = (!self.muted && self.lastReadMessageId != (id)NSNull.null && [self.lastReadMessageId isKindOfClass:[NSString class]] && ![self.lastReadMessageId    isEqualToString:self.lastMessageId]);
        [self.parentGuild checkIfRead];
    } @catch(NSException* e) {}
    });
}



- (void)sendMessage:(NSString*)message {
    dispatch_queue_t apiQueue = dispatch_queue_create("Discord::API::Send::sendMessage", NULL);
    
	dispatch_async(apiQueue, ^{
		NSURL* channelURL = [NSURL URLWithString: [NSString stringWithFormat:@"https://discord.com/api/v9/channels/%@/messages", self.snowflake]];
		
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
        dispatch_sync(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible++;
        });
        [DCTools checkData:[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error] withError:error];
        dispatch_sync(dispatch_get_main_queue(), ^{
        if ([UIApplication sharedApplication].networkActivityIndicatorVisible > 0)
            [UIApplication sharedApplication].networkActivityIndicatorVisible--;
        else if ([UIApplication sharedApplication].networkActivityIndicatorVisible < 0)
            [UIApplication sharedApplication].networkActivityIndicatorVisible = 0;
        });
	});
    
    dispatch_release(apiQueue);
}



- (void)sendImage:(UIImage*)image mimeType:(NSString*)type {
    dispatch_queue_t apiQueue = dispatch_queue_create("Discord::API::Send::sendImage", NULL);
        NSURL* channelURL = [NSURL URLWithString: [NSString stringWithFormat:@"https://discord.com/api/v9/channels/%@/messages", self.snowflake]];
		
		NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:channelURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
		
		[urlRequest setHTTPMethod:@"POST"];
		
		NSString *boundary = @"---------------------------14737809831466499882746641449";
		
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
		[urlRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
		[urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
		
		NSMutableData *postbody = NSMutableData.new;
		[postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"upload.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        if ([type isEqualToString:@"image/jpeg"]) {
            [postbody appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [postbody appendData:[NSData dataWithData:UIImageJPEGRepresentation(image, 80)]];
        } else if ([type isEqualToString:@"image/png"]){
            [postbody appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [postbody appendData:[NSData dataWithData:UIImagePNGRepresentation(image)]];
        }
		[postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[@"Content-Disposition: form-data; name=\"content\"\r\n\r\n " dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		[urlRequest setHTTPBody:postbody];
		
    
    dispatch_async(apiQueue, ^{
        NSError *error = nil;
		NSHTTPURLResponse *responseCode = nil;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible++;
        });
        [DCTools checkData:[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error] withError:error];
        dispatch_sync(dispatch_get_main_queue(), ^{
        if ([UIApplication sharedApplication].networkActivityIndicatorVisible > 0)
            [UIApplication sharedApplication].networkActivityIndicatorVisible--;
        else if ([UIApplication sharedApplication].networkActivityIndicatorVisible < 0)
            [UIApplication sharedApplication].networkActivityIndicatorVisible = 0;
        });
	});
    dispatch_release(apiQueue);
}

- (void)sendTypingIndicator{
    dispatch_queue_t apiQueue = dispatch_queue_create("Discord::API::Event", NULL);
    dispatch_async(apiQueue, ^{
    NSURL* channelURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://discord.com/api/v9/channels/%@/typing", self.snowflake]];
    
    NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:channelURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5]; // low timeout to avoid API spam
    
    [urlRequest setHTTPMethod:@"POST"];
    
    [urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSError *error = nil;
		NSHTTPURLResponse *responseCode = nil;
        
        //[UIApplication sharedApplication].networkActivityIndicatorVisible++;
        [DCTools checkData:[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error] withError:error];
        /*if ([UIApplication sharedApplication].networkActivityIndicatorVisible > 0)
            [UIApplication sharedApplication].networkActivityIndicatorVisible--;
        else if ([UIApplication sharedApplication].networkActivityIndicatorVisible < 0)
            [UIApplication sharedApplication].networkActivityIndicatorVisible = 0;*/
    });
    dispatch_release(apiQueue);
}

- (void)ackMessage:(NSString*)messageId{
	self.lastReadMessageId = messageId;
	dispatch_queue_t apiQueue = dispatch_queue_create([@"Discord::API::Event" UTF8String], NULL);
	dispatch_async(apiQueue, ^{
		NSURL* channelURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://discord.com/api/v9/channels/%@/messages/%@/ack", self.snowflake, messageId]];
		
		NSMutableURLRequest *urlRequest=[NSMutableURLRequest requestWithURL:channelURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
		
		[urlRequest setHTTPMethod:@"POST"];
		
		[urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
		[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		NSError *error = nil;
		NSHTTPURLResponse *responseCode = nil;
        
        //[UIApplication sharedApplication].networkActivityIndicatorVisible++;
        [DCTools checkData:[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error] withError:error];
        /*if ([UIApplication sharedApplication].networkActivityIndicatorVisible > 0)
            [UIApplication sharedApplication].networkActivityIndicatorVisible--;
        else if ([UIApplication sharedApplication].networkActivityIndicatorVisible < 0)
            [UIApplication sharedApplication].networkActivityIndicatorVisible = 0;*/
	});
    dispatch_release(apiQueue);
}



- (NSArray*)getMessages:(int)numberOfMessages beforeMessage:(DCMessage*)message{
	
    NSMutableArray* messages = NSMutableArray.new;
	//Generate URL from args
	NSMutableString* getChannelAddress = [[NSString stringWithFormat: @"https://discord.com/api/v9/channels/%@/messages?", self.snowflake] mutableCopy];
	
	if(numberOfMessages)
		[getChannelAddress appendString:[NSString stringWithFormat:@"limit=%i", numberOfMessages]];
	if(numberOfMessages && message)
		[getChannelAddress appendString:@"&"];
	if(message)
		[getChannelAddress appendString:[NSString stringWithFormat:@"before=%@", message.snowflake]];
    
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:getChannelAddress] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
	
	[urlRequest addValue:DCServerCommunicator.sharedInstance.token forHTTPHeaderField:@"Authorization"];
	[urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	
	NSError *error = nil;
    NSHTTPURLResponse *responseCode = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible++;
        });
        NSData *response = [DCTools checkData:[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error] withError:error];
        dispatch_sync(dispatch_get_main_queue(), ^{
        if ([UIApplication sharedApplication].networkActivityIndicatorVisible > 0)
            [UIApplication sharedApplication].networkActivityIndicatorVisible--;
        else if ([UIApplication sharedApplication].networkActivityIndicatorVisible < 0)
            [UIApplication sharedApplication].networkActivityIndicatorVisible = 0;
        });
        if(response){
            dispatch_sync(dispatch_get_main_queue(), ^{
            NSError *error = nil;
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
                        && ([currentMessage.timestamp timeIntervalSince1970] - [prevMessage.timestamp timeIntervalSince1970] < 420)
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
            });
            
            if(messages.count > 0)
                return messages;
            
            [DCTools alert:@"No messages!" withMessage:@"No further messages could be found"];
    }
    
	return nil;
}


@end

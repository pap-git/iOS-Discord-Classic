//
//  DCChatViewController.m
//  Discord Classic
//
//  Created by Julian Triveri on 3/6/18.
//  Copyright (c) 2018 Julian Triveri. All rights reserved.
//

#import "DCChatViewController.h"
#import "DCServerCommunicator.h"
#import "TRMalleableFrameView.h"
#import "DCMessage.h"
#import "DCTools.h"
#import "DCChatTableCell.h"
#import "DCUser.h"
#import "DCImageViewController.h"
#import "TRMalleableFrameView.h"

@interface DCChatViewController()
@property int numberOfMessagesLoaded;
@property UIImage* selectedImage;
@property UIRefreshControl *refreshControl;
@end

@implementation DCChatViewController

int lastTimeInterval = 0; // for typing indicator

- (void)viewDidLoad{
	[super viewDidLoad];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleMessageCreate:) name:@"MESSAGE CREATE" object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleMessageDelete:) name:@"MESSAGE DELETE" object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleAsyncReload) name:@"RELOAD CHAT DATA" object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleReady) name:@"READY" object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	lastTimeInterval = 0;
    
	self.refreshControl = UIRefreshControl.new;
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Earlier messages"];
	
	[self.chatTableView addSubview:self.refreshControl];
	
	[self.refreshControl addTarget:self action:@selector(get50MoreMessages:) forControlEvents:UIControlEventValueChanged];
    
    [self.inputField setDelegate:self];
    self.inputFieldPlaceholder.text = [NSString stringWithFormat:@"Message %@", self.navigationItem.title];
    self.inputFieldPlaceholder.hidden = NO;
}

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView {
    self.inputFieldPlaceholder.hidden = self.inputField.text.length != 0;
    lastTimeInterval = 0;
    return YES;
}

-(void) textViewDidChange:(UITextView *)textView {
    self.inputFieldPlaceholder.hidden = self.inputField.text.length != 0;
    int currentTimeInterval = [[NSDate date] timeIntervalSince1970];
    if (currentTimeInterval - lastTimeInterval >= 10) {
        [DCServerCommunicator.sharedInstance.selectedChannel sendTypingIndicator];
        lastTimeInterval = currentTimeInterval;
    }
}

-(void) textViewShouldEndEditing:(UITextView *)textView {
    self.inputFieldPlaceholder.hidden = self.inputField.text.length != 0;
    lastTimeInterval = 0;
}

- (void) handleAsyncReload {
    dispatch_async(dispatch_get_main_queue(), ^{
        //NSLog(@"async reload!");
        [self.chatTableView reloadData];
    });
}

- (void)handleReady {
	
	if(DCServerCommunicator.sharedInstance.selectedChannel){
		self.messages = NSMutableArray.new;
	
		[self getMessages:50 beforeMessage:nil];
	}
	
	[self.refreshControl endRefreshing];
}


- (void)handleMessageCreate:(NSNotification*)notification {
    DCMessage* newMessage = [DCTools convertJsonMessage:notification.userInfo];
	
    if (self.messages.count > 0) {
        DCMessage* prevMessage = self.messages[self.messages.count - 1];
        if (prevMessage != nil) {
            NSDateComponents* curComponents = [[NSCalendar currentCalendar] components:kCFCalendarUnitHour | kCFCalendarUnitDay | kCFCalendarUnitMonth | kCFCalendarUnitYear fromDate:newMessage.timestamp];
            NSDateComponents* prevComponents = [[NSCalendar currentCalendar] components:kCFCalendarUnitHour | kCFCalendarUnitDay | kCFCalendarUnitMonth | kCFCalendarUnitYear fromDate:prevMessage.timestamp];
            
            if (prevMessage.author.snowflake == newMessage.author.snowflake
                && ([newMessage.timestamp timeIntervalSince1970] - [prevMessage.timestamp timeIntervalSince1970] < 420)
                && curComponents.day == prevComponents.day
                && curComponents.month == prevComponents.month
                && curComponents.year == prevComponents.year) {
                newMessage.isGrouped = newMessage.referencedMessage == nil;
                
                if (newMessage.isGrouped ) {
                    float contentWidth = UIScreen.mainScreen.bounds.size.width - 63;
                    CGSize authorNameSize = [newMessage.author.globalName sizeWithFont:[UIFont boldSystemFontOfSize:15] constrainedToSize:CGSizeMake(contentWidth, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
                    
                    newMessage.contentHeight -= authorNameSize.height + 4;
                }
            }
        }
    }
    
	[self.messages addObject:newMessage];
	[self.chatTableView reloadData];
	
	if(self.viewingPresentTime)
		[self.chatTableView setContentOffset:CGPointMake(0, self.chatTableView.contentSize.height - self.chatTableView.frame.size.height) animated:NO];
}


- (void)handleMessageDelete:(NSNotification*)notification {
	DCMessage *compareMessage = DCMessage.new;
	compareMessage.snowflake = [notification.userInfo valueForKey:@"id"];
		
	[self.messages removeObject:compareMessage];
	[self.chatTableView reloadData];
				
}


- (void)getMessages:(int)numberOfMessages beforeMessage:(DCMessage*)message{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
	NSArray* newMessages = [DCServerCommunicator.sharedInstance.selectedChannel getMessages:numberOfMessages beforeMessage:message];
	
	if(newMessages){
		NSRange range = NSMakeRange(0, [newMessages count]);
		NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
		[self.messages insertObjects:newMessages atIndexes:indexSet];
		
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.chatTableView reloadData];

			int scrollOffset = -self.chatTableView.height;
			for(DCMessage* newMessage in newMessages)
				scrollOffset += newMessage.contentHeight + newMessage.embeddedImageCount * 224;
			
			[self.chatTableView setContentOffset:CGPointMake(0, scrollOffset) animated:NO];
		});
	}
	
	[self.refreshControl endRefreshing];
    });
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	//static NSString *guildCellIdentifier = @"Channel Cell";
	
	DCChatTableCell* cell;
	
	DCMessage* messageAtRowIndex = [self.messages objectAtIndex:indexPath.row];

    [tableView registerNib:[UINib nibWithNibName:@"DCChatGroupedTableCell" bundle:nil] forCellReuseIdentifier:@"Grouped Message Cell"];
    [tableView registerNib:[UINib nibWithNibName:@"DCChatTableCell" bundle:nil] forCellReuseIdentifier:@"Message Cell"];
    [tableView registerNib:[UINib nibWithNibName:@"DCChatReplyTableCell" bundle:nil] forCellReuseIdentifier:@"Reply Message Cell"];
    
    if (messageAtRowIndex.isGrouped)
        cell = [tableView dequeueReusableCellWithIdentifier:@"Grouped Message Cell"];
    else if (messageAtRowIndex.referencedMessage != nil)
        cell = [tableView dequeueReusableCellWithIdentifier:@"Reply Message Cell"];
    else
        cell = [tableView dequeueReusableCellWithIdentifier:@"Message Cell"];
    
    if (messageAtRowIndex.referencedMessage != nil) {
        [cell.referencedAuthorLabel setText:messageAtRowIndex.referencedMessage.author.globalName];
        [cell.referencedMessage setText:messageAtRowIndex.referencedMessage.content];
        [cell.referencedMessage setFrame:CGRectMake(messageAtRowIndex.referencedMessage.authorNameWidth, cell.referencedMessage.y, self.chatTableView.width-messageAtRowIndex.authorNameWidth, cell.referencedMessage.height)];
        
        [cell.referencedProfileImage setImage:messageAtRowIndex.referencedMessage.author.profileImage];
        cell.referencedProfileImage.layer.cornerRadius = cell.referencedProfileImage.frame.size.height / 2;
        cell.referencedProfileImage.layer.masksToBounds = YES;
    }
    
    if (!messageAtRowIndex.isGrouped) {
        [cell.authorLabel setText:messageAtRowIndex.author.globalName];
        [cell.timestampLabel setText:messageAtRowIndex.prettyTimestamp];
        [cell.timestampLabel setFrame:CGRectMake(messageAtRowIndex.authorNameWidth, cell.timestampLabel.y, self.chatTableView.width-messageAtRowIndex.authorNameWidth, cell.timestampLabel.height)];
    }
	
	[cell.contentTextView setText:messageAtRowIndex.content];
	
	[cell.contentTextView setHeight:[cell.contentTextView sizeThatFits:CGSizeMake(cell.contentTextView.width, MAXFLOAT)].height];
	
    if (!messageAtRowIndex.isGrouped) {
        if(messageAtRowIndex.author.avatarDecoration) {
            [cell.avatarDecoration setImage:messageAtRowIndex.author.avatarDecoration];
            cell.avatarDecoration.layer.hidden = NO;
            cell.avatarDecoration.opaque = NO;
        } else {
            cell.avatarDecoration.layer.hidden = YES;
        }
        [cell.profileImage setImage:messageAtRowIndex.author.profileImage];
        cell.profileImage.layer.cornerRadius = cell.profileImage.frame.size.height / 2;
        cell.profileImage.layer.masksToBounds = YES;
    }
	
	[cell.contentView setBackgroundColor:messageAtRowIndex.pingingUser? [UIColor orangeColor] : [UIColor clearColor]];
    
    cell.contentView.layer.cornerRadius = 4;
    cell.contentView.layer.masksToBounds = YES;
	
	for (UIView *subView in cell.subviews) {
		if ([subView isKindOfClass:[UIImageView class]]) {
			[subView removeFromSuperview];
		}
	}
	
	int imageViewOffset = cell.contentTextView.height + (messageAtRowIndex.isGrouped ? 12 : 36);
	
	for(UIImage* image in messageAtRowIndex.embeddedImages){
		UIImageView* imageView = UIImageView.new;
		[imageView setFrame:CGRectMake(11, imageViewOffset, self.chatTableView.width - 22, 200)];
		[imageView setImage:image];
		imageViewOffset += 210;
		
		[imageView setContentMode: UIViewContentModeScaleAspectFit];
		
		UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedImage:)];
		singleTap.numberOfTapsRequired = 1;
        imageView.userInteractionEnabled = YES;
        
        imageView.layer.cornerRadius = 8;
        imageView.layer.masksToBounds = YES;
        imageView.layer.shouldRasterize = YES;
        imageView.layer.rasterizationScale = 2;
        
		[imageView addGestureRecognizer:singleTap];
		
		[cell addSubview:imageView];
	}
	return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	DCMessage* messageAtRowIndex = [self.messages objectAtIndex:indexPath.row];
    
	return messageAtRowIndex.contentHeight + messageAtRowIndex.embeddedImageCount * 224;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	self.selectedMessage = self.messages[indexPath.row];
	
	if([self.selectedMessage.author.snowflake isEqualToString: DCServerCommunicator.sharedInstance.snowflake]){
		UIActionSheet *messageActionSheet = [[UIActionSheet alloc] initWithTitle:self.selectedMessage.content delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
		[messageActionSheet setTag:1];
		[messageActionSheet setDelegate:self];
		[messageActionSheet showInView:self.view];
	}
}


- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == 0)
		[self.selectedMessage deleteMessage];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	self.viewingPresentTime = (scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.height - 10);
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{return 1;}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{return self.messages.count;}


- (void)keyboardWillShow:(NSNotification *)notification {
	
	//thx to Pierre Legrain
	//http://pyl.io/2015/08/17/animating-in-sync-with-ios-keyboard/
	
	int keyboardHeight = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
	float keyboardAnimationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	int keyboardAnimationCurve = [[notification.userInfo objectForKey: UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:keyboardAnimationDuration];
	[UIView setAnimationCurve:keyboardAnimationCurve];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[self.chatTableView setHeight:self.view.height - keyboardHeight - self.toolbar.height];
	[self.toolbar setY:self.view.height - keyboardHeight - self.toolbar.height];
	[UIView commitAnimations];
	
	
	if(self.viewingPresentTime)
		[self.chatTableView setContentOffset:CGPointMake(0, self.chatTableView.contentSize.height - self.chatTableView.frame.size.height) animated:NO];
}


- (void)keyboardWillHide:(NSNotification *)notification {
	
	float keyboardAnimationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	int keyboardAnimationCurve = [[notification.userInfo objectForKey: UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:keyboardAnimationDuration];
	[UIView setAnimationCurve:keyboardAnimationCurve];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[self.chatTableView setHeight:self.view.height - self.toolbar.height];
	[self.toolbar setY:self.view.height - self.toolbar.height];
	[UIView commitAnimations];
}

- (IBAction)sendMessage:(id)sender {
	if(![self.inputField.text isEqual: @""]){
		[DCServerCommunicator.sharedInstance.selectedChannel sendMessage:self.inputField.text];
		[self.inputField setText:@""];
        self.inputFieldPlaceholder.hidden = NO;
        lastTimeInterval = 0;
	}else
		[self.inputField resignFirstResponder];
	
	if(self.viewingPresentTime)
		[self.chatTableView setContentOffset:CGPointMake(0, self.chatTableView.contentSize.height - self.chatTableView.frame.size.height) animated:YES];
}

- (void)tappedImage:(UITapGestureRecognizer *)sender {
	[self.inputField resignFirstResponder];
	self.selectedImage = ((UIImageView*)sender.view).image;
	[self performSegueWithIdentifier:@"Chat to Gallery" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"Chat to Gallery"]){
		
		DCImageViewController	*imageViewController = [segue destinationViewController];
		
		if ([imageViewController isKindOfClass:DCImageViewController.class]){
			dispatch_async(dispatch_get_main_queue(), ^{
				[imageViewController.imageView setImage:self.selectedImage];
			});
		}
	}
}


- (IBAction)chooseImage:(id)sender {
	
	[self.inputField resignFirstResponder];
	
	UIImagePickerController *picker = UIImagePickerController.new;
	
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	
	[picker setDelegate:self];
	
	[self presentModalViewController:picker animated:YES];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	
	[picker dismissModalViewControllerAnimated:YES];
	
	UIImage* originalImage = [info objectForKey:UIImagePickerControllerEditedImage];
	
	if(originalImage==nil)
		originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
	
	if(originalImage==nil)
		originalImage = [info objectForKey:UIImagePickerControllerCropRect];
	
	[DCServerCommunicator.sharedInstance.selectedChannel sendImage:originalImage];
}


-(void)get50MoreMessages:(UIRefreshControl *)control {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self getMessages:50 beforeMessage:[self.messages objectAtIndex:0]];
    });
}
@end
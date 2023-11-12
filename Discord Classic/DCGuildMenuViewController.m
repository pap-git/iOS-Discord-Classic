//
//  DCGuildMenuViewController.m
//  Discord Classic
//
//  Created by Defne on 12/11/23.
//  Copyright (c) 2023 Julian Triveri. All rights reserved.
//

#import "DCGuildMenuViewController.h"
#import "DCGuild.h"
#import "DCTools.h"
//#import "DCClient.h"
#import "DCChannel.h"
#import "DCChatViewController.h"
//#import "RBGuildStore.h"
//#import "RBNotificationEvent.h"
#import "DCChatViewController.h"
#import "DCServerCommunicator.h"

@interface DCGuildMenuViewController ()

@property (weak, nonatomic) IBOutlet UITableView *guildTableView;
@property (strong, nonatomic) IBOutlet UILabel *channelLabel;
@property (weak, nonatomic) IBOutlet UITableView *channelTableView;
@property DCGuild *selectedGuild;
@property DCChannel *selectedChannel;

@property NSOperationQueue* serverIconImageQueue;

@end

@implementation DCGuildMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad{
	[super viewDidLoad];
	
	//Go to settings if no token is set
	if(!DCServerCommunicator.sharedInstance.token.length)
		[self performSegueWithIdentifier:@"to Settings" sender:self];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleReady) name:@"READY" object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleReady) name:@"MESSAGE ACK" object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleReady) name:@"RELOAD GUILD LIST" object:nil];
    
    
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if(tableView == self.guildTableView){
		self.selectedGuild = [DCServerCommunicator.sharedInstance.guilds objectAtIndex:indexPath.row];
		[self.channelTableView reloadData];
	}
    
    if(tableView == self.channelTableView){
        self.selectedChannel = (DCChannel*)[self.selectedGuild.channels objectAtIndex:indexPath.row];
        DCServerCommunicator.sharedInstance.selectedChannel = [self.selectedGuild.channels objectAtIndex:indexPath.row];
        
        //Mark channel messages as read and refresh the channel object accordingly
        [DCServerCommunicator.sharedInstance.selectedChannel ackMessage:DCServerCommunicator.sharedInstance.selectedChannel.lastMessageId];
        [DCServerCommunicator.sharedInstance.selectedChannel checkIfRead];
        
        //Remove the blue indicator since the channel has been read
        [[self.channelTableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [self performSegueWithIdentifier:@"guilds to chat" sender:self];
        
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}

- (void)handleReady {
	//Refresh tableView data on READY notification
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.guildTableView reloadData];
        
        /*if(VERSION_MIN(@"6.0") && !self.refreshControl){
            self.refreshControl = UIRefreshControl.new;
            self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Reauthenticate"];
            
            [self.tableView addSubview:self.refreshControl];
            
            [self.refreshControl addTarget:self action:@selector(reconnect) forControlEvents:UIControlEventValueChanged];
        }*/
    });
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell;
	
	if(tableView == self.guildTableView){
        
        //Sorts guilds alphabetically, Note that this code may not yield the best results, and should be modified in the future. It can crash the app sometimes.
        DCServerCommunicator.sharedInstance.guilds = [[DCServerCommunicator.sharedInstance.guilds sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSString *first = [(DCGuild*)a name];
            NSString *second = [(DCGuild*)b name];
            if([first compare:@"Direct Messages"] == 0) return false; // DMs at the top
            return [first compare:second];
        }] mutableCopy];

        
        DCGuild* guildAtRowIndex = [DCServerCommunicator.sharedInstance.guilds objectAtIndex:indexPath.row];
		cell = [tableView dequeueReusableCellWithIdentifier:@"guild" forIndexPath:indexPath];
		cell.textLabel.text = @"";
        [cell.imageView setImage:guildAtRowIndex.icon];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        cell.imageView.clipsToBounds = YES;
        
        // make guild icons a fixed size
        cell.imageView.layer.cornerRadius = cell.imageView.frame.size.height / 2;
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.frame = CGRectMake(2.0, 2.0, 40, 40);
        [cell.imageView setNeedsDisplay];
	}
	
	if(tableView == self.channelTableView){
        DCChannel* channelAtRowIndex = [self.selectedGuild.channels objectAtIndex:indexPath.row];
        
		cell = [tableView dequeueReusableCellWithIdentifier:@"channel" forIndexPath:indexPath];
		[cell.textLabel setText:channelAtRowIndex.name];
        
        if(channelAtRowIndex.unread)
            [cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
        else
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
	return cell;
}




#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if(tableView == self.guildTableView)
		{return DCServerCommunicator.sharedInstance.guilds.count;}
	
    if(tableView == self.channelTableView)
        return self.selectedGuild.channels.count;
    
    return 0;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.destinationViewController class] == [DCChatViewController class]){
        if ([segue.identifier isEqualToString:@"guilds to chat"]){
            DCChatViewController *chatViewController = [segue destinationViewController];
            
            if ([chatViewController isKindOfClass:DCChatViewController.class]){
                
                //Initialize messages
                chatViewController.messages = NSMutableArray.new;
                
                //Add a '#' if appropriate to the chanel name in the navigation bar
                NSString* formattedChannelName;
                if(DCServerCommunicator.sharedInstance.selectedChannel.type == 0)
                    formattedChannelName = [@"#" stringByAppendingString:DCServerCommunicator.sharedInstance.selectedChannel.name];
                else
                    formattedChannelName = DCServerCommunicator.sharedInstance.selectedChannel.name;
                [chatViewController.navigationItem setTitle:formattedChannelName];
                
                //Populate the message view with the last 50 messages
                
                [chatViewController getMessages:50 beforeMessage:nil];
                
                //Chat view is watching the present conversation (auto scroll with new messages)
                [chatViewController setViewingPresentTime:true];
            }
        }
        
    }
}

- (IBAction)joinGuildPrompt:(id)sender{
	UIAlertView *joinPrompt = [[UIAlertView alloc] initWithTitle:@"Enter invite code"
                                                         message:nil
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Join", nil];
	
	[joinPrompt setAlertViewStyle:UIAlertViewStylePlainTextInput];
	[joinPrompt setDelegate:self];
	[joinPrompt show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Join"])
		[DCTools joinGuild:[alertView textFieldAtIndex:0].text];
}

- (void)reconnect {
	[DCServerCommunicator.sharedInstance reconnect];
    /*if (VERSION_MIN(@"6.0"))
        [self.refreshControl endRefreshing];*/
}

@end

//
//  DCWelcomeController.m
//  Discord Classic
//
//  Created by bag.xml on 27/01/24.
//  Copyright (c) 2024 Julian Triveri. All rights reserved.
//

#import "DCWelcomeController.h"

@interface DCWelcomeController ()

@end

@implementation DCWelcomeController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	self.navigationItem.hidesBackButton = YES;
    
    NSString *token = [NSUserDefaults.standardUserDefaults objectForKey:@"token"];
    
    if(token){
        self.tokenTextField.text = token;
    }else{
        self.tokenTextField.text = UIPasteboard.generalPasteboard.string;
    }
    
}

- (IBAction)loginButtonWasClicked {
//DCServerCommunicator
	[self.loginIndicator startAnimating];
	[self.loginIndicator setHidden:false];
    [self.loginButton setHidden:true];
    
    [self performSelector:@selector(checkAuth) withObject:nil afterDelay:10];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.textColor = [UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0];
    header.textLabel.shadowOffset = CGSizeMake(0, 0);
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    footer.textLabel.textColor = [UIColor colorWithRed:116.0/255.0 green:116.0/255.0 blue:116.0/255.0 alpha:1.0];
    footer.textLabel.shadowOffset = CGSizeMake(0, 0);
}

@end

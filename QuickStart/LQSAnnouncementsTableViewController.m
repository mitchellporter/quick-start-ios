//
//  LQSAnnouncementsTableViewController.m
//  QuickStart
//
//  Created by Layer on 6/18/15.
//  Copyright (c) 2015 Abir Majumdar. All rights reserved.
//

#import "LQSAnnouncementsTableViewController.h"
#import <LayerKit/LayerKit.h>
#import <LayerKit/LYRAnnouncement.h>
#import "LQSViewController.h"
#import "LQSAnnouncementsTableViewCell.h"
#import "LQSChatMessageCell.h"

@interface LQSAnnouncementsTableViewController () <LYRQueryControllerDelegate>

@property (nonatomic) BOOL shouldScrollAfterFirstAppearance;
@property (nonatomic) BOOL shouldScrollAfterUpdates;
@property (strong,nonatomic) NSOrderedSet *announcements;
@property (nonatomic, retain) LYRQueryController *queryController;

@end

@implementation LQSAnnouncementsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSError *error = nil;
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRAnnouncement class]];
    query.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:NO]];
    
    _queryController = [self.layerClient queryControllerWithQuery:query];
    _queryController.delegate = self;
    [_queryController execute:&error];
    
    if (self.queryController.count <= 0) {
        
        UIView *empty_view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
        empty_view.backgroundColor = [UIColor whiteColor];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Announcements"
                                                        message:@"You currently have no announcements. Would you like to learn about announcements?"
                                                       delegate:self
                                              cancelButtonTitle:@"NO"
                                              otherButtonTitles:@"Yes",nil];
        [alert show];
        

        UILabel *label = [[UILabel alloc]initWithFrame: CGRectMake(10, 50, 500, 500)];
        [label setFont:[UIFont fontWithName:@"Helvetica Neue" size:17]];
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.text = @"You currently have no announcements!";

        [empty_view addSubview:label];
        self.view = empty_view;
    
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSURL *ourURL = [[NSURL alloc]initWithString:@"https://developer.layer.com/docs/platform#send-an-announcement"];
    if (buttonIndex ==1) {
        [[UIApplication sharedApplication] openURL:ourURL];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _queryController.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LYRAnnouncement *announcement = [_queryController objectAtIndexPath:indexPath];
    [announcement markAsRead:nil];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"cell";
    LQSAnnouncementsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (!cell) {
        cell = [[LQSAnnouncementsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    LYRAnnouncement *announcementsInfo = [self.queryController objectAtIndexPath:indexPath];
    LYRMessage *message = [self.queryController objectAtIndexPath:indexPath];
    
    LYRMessagePart *messagePart = message.parts[0];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    
    NSString *announcementMessage = [[NSString alloc]initWithData:messagePart.data encoding:NSUTF8StringEncoding];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    [cell updateDate:[NSString stringWithFormat:@"%@",[dateFormat stringFromDate:announcementsInfo.sentAt]]];
    [cell updateSenderName:announcementsInfo.sender.name];
    [cell updateMessageLabel:announcementMessage];
    
    if (announcementsInfo.isUnread) {
        cell.indicatorLabel.hidden = NO;
    }else {
        cell.indicatorLabel.hidden = YES;
    }
    
    return cell;
}

#pragma mark - Query controller delegate implementation

- (void)queryController:(LYRQueryController *)controller didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(LYRQueryControllerChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    
    switch (type) {
        case LYRQueryControllerChangeTypeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case LYRQueryControllerChangeTypeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (controller.count >= newIndexPath.row) {
                self.shouldScrollAfterUpdates = YES;
            }
            break;
        case LYRQueryControllerChangeTypeMove:
            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
        case LYRQueryControllerChangeTypeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
    
}

- (void)queryControllerWillChangeContent:(LYRQueryController *)queryController
{
    [self.tableView beginUpdates];
}

- (void)queryControllerDidChangeContent:(LYRQueryController *)queryController
{
    [self.tableView endUpdates];
    if (self.shouldScrollAfterUpdates) {
        [self scrollToBottomAnimated:YES];
    }
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    if (self.queryController.count) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.queryController.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }
}


@end

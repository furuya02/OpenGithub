//
//  BranchSelectView.m
//  OpenGithub
//
//  Created by hirauchi.shinichi on 2016/02/18.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

#import "BranchSelectView.h"

@interface BranchSelectView ()

@property (weak) IBOutlet NSPopUpButton *pulldown;
@property NSArray *urls;
@end

@implementation BranchSelectView


- (void)windowDidLoad {
    [super windowDidLoad];


    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)initWithBranches:(NSArray*)branches urls:(NSArray *)urls
{
    self.urls = urls;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.pulldown removeAllItems];
        [self.pulldown addItemsWithTitles:branches];
    });
}



- (IBAction)tapOkButton:(id)sender {
    int index = [self.pulldown indexOfSelectedItem];

[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self.urls objectAtIndex:index]]];

    [self close];
}

- (IBAction)tapCancelButton:(id)sender {
    [self close];
}

@end

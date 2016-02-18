//
//  BranchSelectView.h
//  OpenGithub
//
//  Created by hirauchi.shinichi on 2016/02/18.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BranchSelectView : NSWindowController

- (void)initWithBranches:(NSArray*)branches urls:(NSArray *)urls;

@end

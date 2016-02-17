//
//  OpenGithub.h
//  OpenGithub
//
//  Created by hirauchi.shinichi on 2016/02/17.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

#import <AppKit/AppKit.h>

@class OpenGithub;

static OpenGithub *sharedPlugin;

@interface OpenGithub : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end
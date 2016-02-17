//
//  NSObject_Extension.m
//  OpenGithub
//
//  Created by hirauchi.shinichi on 2016/02/17.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//


#import "NSObject_Extension.h"
#import "OpenGithub.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[OpenGithub alloc] initWithBundle:plugin];
        });
    }
}
@end

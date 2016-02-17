//
//  OpenGithub.m
//  OpenGithub
//
//  Created by hirauchi.shinichi on 2016/02/17.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

#import "OpenGithub.h"

@interface OpenGithub()

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@property (nonatomic, assign) NSUInteger startLine;
@property (nonatomic, assign) NSUInteger endLine;

@end

@implementation OpenGithub

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{

    if (self = [super init]) {

        self.bundle = plugin;

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];


        [nc addObserver:self
               selector:@selector(didApplicationFinishLaunchingNotification:)
                   name:NSApplicationDidFinishLaunchingNotification
                 object:nil];

//        [nc addObserver:self
//               selector:@selector(fetchActiveIDEWorkspaceWindow:)
//                   name:NSWindowDidUpdateNotification
//                 object:nil];

        [nc addObserver:self
               selector:@selector(sourceTextViewSelectionDidChange:)
                   name:NSTextViewDidChangeSelectionNotification
                 object:nil];
        
        
    }
    return self;

}


- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    //removeObserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    // Create menu items, initialize UI, etc.
    // Sample Menu Item:
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Do Action" action:@selector(doMenuAction) keyEquivalent:@""];
        //[actionMenuItem setKeyEquivalentModifierMask:NSAlphaShiftKeyMask | NSControlKeyMask];
        [actionMenuItem setTarget:self];
        [[menuItem submenu] addItem:actionMenuItem];
    }
}

- (void)sourceTextViewSelectionDidChange:(NSNotification *)notification
{
    id view = [notification object];
    if ([view isKindOfClass:[NSTextView class]]) {
        NSString *selectedText = [[view string] substringWithRange:NSMakeRange(0, [view selectedRange].location)];
        self.startLine = [[selectedText componentsSeparatedByCharactersInSet:
                                          [NSCharacterSet newlineCharacterSet]] count];

        selectedText = [[view string] substringWithRange:[view selectedRange]];
        NSUInteger selectedLines = [[selectedText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count];
        self.endLine = self.startLine + (selectedLines > 1 ? selectedLines - 2 : 0);
    }
}

- (NSURL *)doMenuAction
{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];

    for (id controller in workspaceWindowControllers) {
        id window = [controller performSelector:@selector(window)];
        if ( [window isEqual:[NSApp keyWindow]]) {
            id workSpace = [controller valueForKey:@"_workspace"];
            id filePath = [workSpace performSelector:@selector(representingFilePath)];
            NSString *workspacePath = [filePath performSelector:@selector(pathString)];
            id editorArea = [controller performSelector:@selector(editorArea)];
            id document = [editorArea performSelector:@selector(primaryEditorDocument)];
            NSString *fileName = [document fileURL];
            NSLog(@"%@",fileName);
        }
    }

    NSTask *task = [[NSTask alloc] init];
    NSPipe *pipe = [[NSPipe alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    [task setArguments: [NSArray arrayWithObjects: @"-c", @"cd /Users/hirauchishinichi/Documents/work3/OpenGithub; git status", nil]];
    [task setStandardOutput:pipe];
    [task launch];

    NSFileHandle *handle = [pipe fileHandleForReading];
    NSData *data = [handle  readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSLog(@"===============================");
    NSLog(string);
    NSLog(@"===============================");

    return nil;
}




// Sample Action, for menu item:
//- (void)doMenuAction
//{
//    NSAlert *alert = [[NSAlert alloc] init];
//    [alert setMessageText:@"Hello, World"];
//    [alert runModal];
//}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

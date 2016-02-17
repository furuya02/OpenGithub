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
    
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open Github" action:@selector(doAction) keyEquivalent:@""];
        //[actionMenuItem setKeyEquivalentModifierMask:NSAlphaShiftKeyMask | NSControlKeyMask];
        [actionMenuItem setKeyEquivalentModifierMask: NSAlternateKeyMask];
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

- (NSURL *)doAction
{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];

    NSString *directory = nil;
    NSString *fileName = @"";

    for (id controller in workspaceWindowControllers) {
        id window = [controller performSelector:@selector(window)];
        if ( [window isEqual:[NSApp keyWindow]]) {
            id workSpace = [controller valueForKey:@"_workspace"];


            id filePath = [workSpace performSelector:@selector(representingFilePath)];
            NSString *workspacePath = [filePath performSelector:@selector(pathString)];

            directory = [workspacePath stringByDeletingLastPathComponent];


            id editorArea = [controller performSelector:@selector(editorArea)];
            id document = [editorArea performSelector:@selector(primaryEditorDocument)];
            fileName = [document fileURL];
        }
    }

    if(directory!=nil){
//        NSMutableArray *array = ;
        for (NSString *text in [self shell:directory :@"git branch -r"]) {

            NSRange searchResult = [text rangeOfString: @"HEAD"];
            if(searchResult.location == NSNotFound){ // HEADの無い行だけ採用
                // 空白、改行を削除
                NSString *tmp = [(NSString*)text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                // 先頭の「origin/」を削除
                tmp = [tmp substringFromIndex:(NSUInteger)7];
                NSLog(tmp);

            }
        }
        for (NSString *text in [self shell:directory :@"git remote -v"]) {
            NSRange searchResult = [text rangeOfString: @"(fetch)"]; // (fetch)のある行だけ採用
            if(searchResult.location != NSNotFound){
                NSString *tmp = [(NSString*)text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                

                NSLog(tmp);
            }
        }
    }
    return nil;
}

- (NSMutableArray *)shell:(NSString *)directory :(NSString *)command {

    NSString *str = [NSString stringWithFormat:@"cd %@;%@",directory,command];
    NSTask *task = [[NSTask alloc] init];
    NSPipe *pipe = [[NSPipe alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    [task setArguments: [NSArray arrayWithObjects: @"-c", str, nil]];
    [task setStandardOutput:pipe];
    [task launch];

    NSFileHandle *handle = [pipe fileHandleForReading];
    NSData *data = [handle  readDataToEndOfFile];
    NSString *lines = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];


    NSMutableArray *array = [NSMutableArray array]; // 空の配列

    NSUInteger lineEnd = 0;
    while (lineEnd < [lines length]){
        NSRange currentRange = [lines lineRangeForRange:NSMakeRange(lineEnd, 0)];
        NSString *currentLine = [lines substringWithRange:currentRange];
        [array addObject:currentLine];
        lineEnd = currentRange.location + currentRange.length;
    }

    return array;
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

//
//  OpenGithub.m
//  OpenGithub
//
//  Created by hirauchi.shinichi on 2016/02/17.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

#import "OpenGithub.h"
#import "BranchSelectView.h"


@interface OpenGithub()

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@property (nonatomic, assign) NSUInteger startLine;
@property (nonatomic, assign) NSUInteger endLine;

@property (nonatomic) BranchSelectView *branchSelectView;

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

        // ブランチの選択時に表示されるビューの初期化
        self.branchSelectView = [[BranchSelectView alloc] initWithWindowNibName:@"BranchSelectView"];
    }
    return self;

}


- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    //removeObserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"View"];
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Github" action:@selector(doAction) keyEquivalent:@"g"];
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
    // ディスク上のディレクトリとアクテブトなっているファイル名の取得
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
            NSString *fileFullName = [document fileURL];
            fileName = [fileFullName lastPathComponent];
        }
    }

    // ペースURLとブランチの取得
    NSMutableArray *branches = [NSMutableArray array];
    NSString *baseUrl = @"";
    if(directory!=nil){
        for (NSString *text in [self shell:directory :@"git branch -r"]) {
            NSRange searchResult = [text rangeOfString: @"HEAD"];
            if(searchResult.location == NSNotFound){ // HEADの無い行だけ採用
                // 空白、改行を削除
                NSString *tmp = [(NSString*)text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                // 先頭の「origin/」を削除
                tmp = [tmp substringFromIndex:(NSUInteger)7];
                [branches addObject:tmp];
            }
        }
        for (NSString *text in [self shell:directory :@"git remote -v"]) {
            NSRange searchResult = [text rangeOfString: @"(fetch)"]; // (fetch)のある行だけ採用
            if(searchResult.location != NSNotFound){
                NSString *tmp = [(NSString*)text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                NSCharacterSet *spr = [NSCharacterSet characterSetWithCharactersInString:@" \t"];
                NSArray *arry = [tmp componentsSeparatedByCharactersInSet:spr];
                if (arry.count == 3 ){
                    baseUrl = [arry objectAtIndex:1];
                }
            }
        }
    }
    // アクセスURLの編集
    NSMutableArray *urls = [NSMutableArray array];
    NSString *projectName = [baseUrl lastPathComponent];
    for (NSString *branch in branches) {
        NSString *url = [NSString stringWithFormat:@"%@/blob/%@/%@/%@",baseUrl,branch,projectName,fileName];
        [urls addObject:url];
    }


    // ブランチを選択するビューの表示
    [self.branchSelectView initWithBranches:branches urls:urls];
    [self.branchSelectView showWindow:self];


    return nil;
}

// コマンド実行して、その出力を行単位で取得する
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

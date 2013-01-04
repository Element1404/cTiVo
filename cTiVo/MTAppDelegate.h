//
//  MTAppDelegate.h
//  myTivo
//
//  Created by Scott Buchanan on 12/6/12.
//  Copyright (c) 2012 Scott Buchanan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MTTiVoManager.h"
#import "MTProgramList.h"
#import "MTDownloadList.h"
#import "MTMainWindowController.h"
#import "MTSubscriptionList.h"

@interface MTAppDelegate : NSObject <NSApplicationDelegate> {
	MTTiVoManager *tiVoManager;
	MTMainWindowController *mainWindowController;
}

@property (assign) IBOutlet NSWindow *window;

@end

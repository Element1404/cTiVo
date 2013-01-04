//
//  MTMainWindowController.m
//  cTiVo
//
//  Created by Scott Buchanan on 12/13/12.
//  Copyright (c) 2012 Scott Buchanan. All rights reserved.
//

#import "MTMainWindowController.h"
#import "MTCheckBox.h"

@interface MTMainWindowController ()

@end

@implementation MTMainWindowController

@synthesize tiVoShowTable,subscriptionTable, downloadQueueTable;

-(id)initWithWindowNibName:(NSString *)windowNibName
{
	self = [super initWithWindowNibName:windowNibName];
	if (self) {
		tiVoManager = [MTTiVoManager sharedTiVoManager];
		_selectedFormat = tiVoManager.selectedFormat;
//		_selectedTiVo = tiVoManager.selectedTiVo;
		_formatList = tiVoManager.formatList;
		_tiVoList = tiVoManager.tiVoList;
	}
	return self;
}

-(void)awakeFromNib
{
//Connect displays to data sources
//    tiVoShowTable.tiVoShows = tiVoManager.tiVoShows; 
//    downloadQueueTable.downloadQueue = tiVoManager.downloadQueue; 
//    subscriptionTable.subscribedShows = tiVoManager.subscribedShows;
    self.selectedTiVo = nil;
	[self refreshFormatListPopup];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[tiVoListPopUp removeAllItems];
	[tiVoListPopUp addItemWithTitle:@"Searching for TiVos..."];
    downloadDirectory.stringValue = tiVoManager.downloadDirectory;
 	tiVoManager.tiVoShowTableView = tiVoShowTable;
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTiVoListPopup) name:kMTNotificationTiVoListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFormatListPopup) name:kMTNotificationFormatListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadProgramData) name:kMTNotificationTiVoShowsUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:downloadQueueTable selector:@selector(updateTable) name:kMTNotificationDownloadQueueUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:downloadQueueTable selector:@selector(updateProgress) name:kMTNotificationProgressUpdated object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkSubscription:) name: kMTNotificationDetailsLoaded object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:loadingProgramListIndicator selector:@selector(startAnimation:) name:kMTNotificationShowListUpdating object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:loadingProgramListIndicator selector:@selector(stopAnimation:) name:kMTNotificationShowListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableSelectionChanged:) name:NSTableViewSelectionDidChangeNotification object:nil];
    [tiVoManager addObserver:self forKeyPath:@"programLoadingString" options:0 context:nil];
    [tiVoManager addObserver:self forKeyPath:@"selectedFormat" options:NSKeyValueObservingOptionInitial context:nil];
    

}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath compare:@"programLoadingString"] == NSOrderedSame) {
        loadingProgramListLabel.stringValue = tiVoManager.programLoadingString;
    }
    if ([keyPath compare:@"selectedFormat"] == NSOrderedSame) {
        _selectedFormat = tiVoManager.selectedFormat;
        BOOL caniTune = [[_selectedFormat objectForKey:@"iTunes"] boolValue];
        [addToiTunesButton setEnabled:caniTune];
        if (caniTune) {
            BOOL wantsiTunes = [[NSUserDefaults standardUserDefaults] boolForKey:kMTiTunesEncode];
            if (wantsiTunes) {
                [addToiTunesButton setState:NSOnState];
				tiVoManager.addToItunes = YES;
            } else {
                [addToiTunesButton setState:NSOffState];
				tiVoManager.addToItunes = NO;
            }
       } else {
           [addToiTunesButton setState:NSOffState];
		   tiVoManager.addToItunes = YES;
        }

        BOOL canSimulEncode = ![[_selectedFormat objectForKey:@"mustDownloadFirst"] boolValue];
        [simultaneousEncodeButton setEnabled:canSimulEncode];
        if (canSimulEncode) {
            BOOL wantsSimul = [[NSUserDefaults standardUserDefaults] boolForKey:kMTSimultaneousEncode];
            if (wantsSimul) {
                [simultaneousEncodeButton setState:NSOnState];
				tiVoManager.simultaneousEncode = YES;
            } else {
                [simultaneousEncodeButton setState:NSOffState];
				tiVoManager.simultaneousEncode = NO;
            }
        } else {
            [simultaneousEncodeButton setState:NSOffState];
			tiVoManager.simultaneousEncode = NO;
        }
    }
}

-(void)reloadProgramData
{
	[tiVoShowTable reloadData];
}

-(void)setFormatList:(NSMutableArray *)formatList
{
	_formatList = formatList;
    [self refreshFormatListPopup];
}


-(void)setTiVoList:(NSMutableArray *)tiVoList
{
	_tiVoList = tiVoList;
}


#pragma mark - Notification Responsders

-(void)refreshFormatListPopup
{
	[formatListPopUp removeAllItems];
//    if (_selectedFormat) {
//        mediaKeyLabel.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:[_selectedFormat objectForKey:@"name"]];
//    }
	for (NSDictionary *fl in _formatList) {
		[formatListPopUp addItemWithTitle:[fl objectForKey:@"name"]];
        [[formatListPopUp lastItem] setRepresentedObject:fl];
		if (_selectedFormat && [[fl objectForKey:@"name"] compare:[_selectedFormat objectForKey:@"name"]] == NSOrderedSame) {
			[formatListPopUp selectItem:[formatListPopUp lastItem]];
		}
		
	}
}

-(void)refreshTiVoListPopup
{
    if (!_selectedTiVo) {
        self.selectedTiVo = [[NSUserDefaults standardUserDefaults] objectForKey:kMTSelectedTiVo];
        if (!_selectedTiVo) {
            self.selectedTiVo = kMTAllTiVos;
        }
    }
	[tiVoListPopUp removeAllItems];
	for (NSNetService *ts in tiVoManager.tiVoList) {
		[tiVoListPopUp addItemWithTitle:ts.name];
        [[tiVoListPopUp lastItem] setRepresentedObject:ts];
		if ([ts.name compare:_selectedTiVo] == NSOrderedSame) {
			[tiVoListPopUp selectItem:[tiVoListPopUp lastItem]];
//            _myTiVos.selectedTiVo = ts;
//            _selectedTiVo = ts;
		}
		
	}
    if (tiVoManager.tiVoList.count == 1) {
        [tiVoListPopUp selectItem:[tiVoListPopUp lastItem]];
    } else {
        [tiVoListPopUp addItemWithTitle:kMTAllTiVos];
        if ([kMTAllTiVos compare:_selectedTiVo] == NSOrderedSame) {
            [tiVoListPopUp selectItem:[tiVoListPopUp lastItem]];
        }
    }
}

#pragma mark - UI Actions

//-(IBAction)selectTivo:(id)sender
//{
//    NSPopUpButton *thisButton = (NSPopUpButton *)sender;
//    _selectedTiVo = [[thisButton selectedItem] title];
//    NSString * possibleKey =[[[NSUserDefaults standardUserDefaults]  objectForKey:kMTMediaKeys] objectForKey:_selectedTiVo];
//	[[NSUserDefaults standardUserDefaults] setObject:_selectedTiVo forKey:kMTSelectedTiVo];
//}
//
-(IBAction)selectFormat:(id)sender
{
    if (sender == formatListPopUp) {
        NSPopUpButton *thisButton = (NSPopUpButton *)sender;
        tiVoManager.selectedFormat = [[thisButton selectedItem] representedObject];
    //    _selectedFormat = _myTiVos.selectedFormat;
        [[NSUserDefaults standardUserDefaults] setObject:[_selectedFormat objectForKey:@"name"] forKey:kMTSelectedFormat];
    } else {
        MTPopUpButton *thisButton = (MTPopUpButton *)sender;
        NSMutableDictionary *owner = (NSMutableDictionary *)(thisButton.owner);
        NSDictionary *format = [[thisButton selectedItem] representedObject];
       [owner setObject:[thisButton selectedItem].title forKey:kMTSubscribedSeriesFormat];
        [[NSUserDefaults standardUserDefaults] setObject:tiVoManager.subscribedShows forKey:kMTSubscriptionList];
        //Check to make sure simultaneou is OK with new selection
        if([owner[kMTSimultaneousEncode] boolValue]) {
            if ([format[@"mustDownloadFirst"] boolValue]) { //We can't have a simulateous encode with this format
                [owner setObject:[NSNumber numberWithBool:NO] forKey:kMTSimultaneousEncode];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationSubscriptionsUpdated object:nil];
    }
	
}

#pragma mark - Subscription Management
//-(void) checkSubscriptionShow:(MTTiVoShow *) show {
//	if([subscriptionTable isSubscribed:show] && ([show.downloadStatus intValue] == kMTStatusNew)) {
//		[self downloadthisShow:show];
//		[[NSNotificationCenter defaultCenter ] postNotificationName:  kMTNotificationDownloadQueueUpdated object:self];
//	}
//}
//
//-(void) checkSubscription: (NSNotification *) notification {
//	[self checkSubscriptionShow: (MTTiVoShow *) notification.object];
//}
//
//-(void) checkSubscriptionsAll {
//	for (MTTiVoShow * show in tiVoManager.tiVoShows.reverseObjectEnumerator) {
//		[self checkSubscriptionShow:show];
//	}
//}

-(IBAction)subscribe:(id) sender {
	BOOL anySubscribed = NO;
    for (int i = 0; i < tiVoManager.tiVoShows.count; i++) {
        if ([tiVoShowTable isRowSelected:i]) {
			anySubscribed = YES;
			MTTiVoShow *thisShow = [tiVoManager.tiVoShows objectAtIndex:i];
			[tiVoManager addSubscription:thisShow];
		}
	}
	if (anySubscribed) {
		[tiVoManager checkSubscriptionsAll];
		[[NSNotificationCenter defaultCenter ] postNotificationName:  kMTNotificationDownloadQueueUpdated object:self];
		[subscriptionTable reloadData];
	}
}

-(void) downloadthisShow:(MTTiVoShow*) thisShow {
	thisShow.addToiTunesWhenEncoded = NO;
	if (addToiTunesButton.state == NSOnState && [[_selectedFormat objectForKey:@"iTunes"] boolValue]) {
		thisShow.addToiTunesWhenEncoded  = YES;
	}
	thisShow.simultaneousEncode = YES;
	if (simultaneousEncodeButton.state == NSOffState) {
		thisShow.simultaneousEncode = NO;
	}
	thisShow.isQueued = YES;
     [tiVoManager addProgramToDownloadQueue:thisShow];
}

-(IBAction)downloadSelectedShows:(id)sender
{
	NSIndexSet *selectedRows = [tiVoShowTable selectedRowIndexes];
	NSArray *displayedShows = tiVoShowTable.sortedShows;
    for (int i = 0; i < tiVoManager.tiVoShows.count; i++) {
        if([selectedRows containsIndex:i]) {
            [self downloadthisShow:[displayedShows objectAtIndex:i]];
        }
    }
	[tiVoShowTable deselectAll:nil];
	[downloadQueueTable deselectAll:nil];
//    [tiVoShowTable reloadData];
	[[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationDownloadQueueUpdated object:nil];
}

-(IBAction)removeFromDownloadQueue:(id)sender
{
	NSIndexSet *selectedRows = [downloadQueueTable selectedRowIndexes];
	NSMutableArray *itemsToRemove = [NSMutableArray array];
    for (int i = 0; i <  tiVoManager.downloadQueue.count; i++) {
        if ([selectedRows containsIndex:i]) {
            MTTiVoShow *programToRemove = [tiVoManager.downloadQueue objectAtIndex:i];
            if ([programToRemove cancel]) {
                [itemsToRemove addObject:programToRemove];
            }
       }
    }
	for (id i in itemsToRemove) {
        ((MTTiVoShow *)i).isQueued = NO;
		[tiVoManager.downloadQueue removeObject:i];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationTiVoShowsUpdated object:nil];
	}
//    [tiVoShowTable reloadData];
	[tiVoShowTable deselectAll:nil];
	[downloadQueueTable deselectAll:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kMTNotificationDownloadQueueUpdated object:nil];
}

-(IBAction)getDownloadDirectory:(id)sender
{
	NSOpenPanel *myOpenPanel = [NSOpenPanel openPanel];
	[myOpenPanel setCanChooseDirectories:YES];
	[myOpenPanel setCanChooseFiles:NO];
	[myOpenPanel setAllowsMultipleSelection:NO];
	NSInteger ret = [myOpenPanel runModal];
	if (ret == NSFileHandlingPanelOKButton) {
		NSString *dir = [myOpenPanel.URL.absoluteString substringFromIndex:16];
		downloadDirectory.stringValue = dir;
        tiVoManager.downloadDirectory = dir;
		[[NSUserDefaults standardUserDefaults] setObject:dir forKey:kMTDownloadDirectory];
        downloadDirectory.toolTip = dir;
	}
}

-(IBAction)changeSimultaneous:(id)sender
{
    MTCheckBox *checkbox = sender;
    if (sender == simultaneousEncodeButton) {
        [[NSUserDefaults standardUserDefaults] setBool:checkbox.state forKey:kMTSimultaneousEncode];
    } else if ([checkbox.owner isKindOfClass:[MTTiVoShow class]]){
        if (((MTTiVoShow *)checkbox.owner).simultaneousEncode) {
            ((MTTiVoShow *)checkbox.owner).simultaneousEncode = NO;
        } else {
            ((MTTiVoShow *)checkbox.owner).simultaneousEncode = YES;
        }
    } else if ([checkbox.owner isKindOfClass:[NSMutableDictionary class]]){
		NSMutableDictionary *d = (NSMutableDictionary *)(checkbox.owner);
		if ([d[kMTSimultaneousEncode] boolValue]) {
			d[kMTSimultaneousEncode] = [NSNumber numberWithBool:NO];
		} else {
			d[kMTSimultaneousEncode] = [NSNumber numberWithBool:YES];
		}
        [[NSUserDefaults standardUserDefaults] setObject:tiVoManager.subscribedShows forKey:kMTSubscriptionList];
   }
}

-(IBAction)changeiTunes:(id)sender
{     
    MTCheckBox *checkbox = sender;
    if (sender == addToiTunesButton) {
        [[NSUserDefaults standardUserDefaults] setBool:checkbox.state forKey:kMTiTunesEncode];
    } else if ([checkbox.owner isKindOfClass:[MTTiVoShow class]]){
        //updating an individual show in download queue
        if (((MTTiVoShow *)checkbox.owner).addToiTunesWhenEncoded) {
            ((MTTiVoShow *)checkbox.owner).addToiTunesWhenEncoded = NO;
        } else {
            ((MTTiVoShow *)checkbox.owner).addToiTunesWhenEncoded = YES;
        }
    } else if ([checkbox.owner isKindOfClass:[NSMutableDictionary class]]){
		NSMutableDictionary *d = (NSMutableDictionary *)(checkbox.owner);
		if ([d[kMTiTunesEncode] boolValue]) {
			d[kMTiTunesEncode] = [NSNumber numberWithBool:NO];
		} else {
			d[kMTiTunesEncode] = [NSNumber numberWithBool:YES];
		}
        [[NSUserDefaults standardUserDefaults] setObject:tiVoManager.subscribedShows forKey:kMTSubscriptionList];
    }
}

#pragma mark - Table View Notification Handling

-(void)tableSelectionChanged:(NSNotification *)notification
{
    [addToQueueButton setEnabled:NO];
    [removeFromQueueButton setEnabled:NO];
	[subscribeButton setEnabled:NO];
    if ([downloadQueueTable numberOfSelectedRows]) {
        [removeFromQueueButton setEnabled:YES];
    }
    if ([tiVoShowTable numberOfSelectedRows]) {
        [addToQueueButton setEnabled:YES];
        [subscribeButton setEnabled:YES];
    }
}

#pragma mark - Memory Management

-(void)dealloc
{
    self.selectedTiVo = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


#pragma mark - Text Editing Delegate

-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if (control == downloadDirectory) {
        tiVoManager.downloadDirectory = control.stringValue;
		[[NSUserDefaults standardUserDefaults] setObject:control.stringValue forKey:kMTDownloadDirectory];
    }
	return YES;
}



@end

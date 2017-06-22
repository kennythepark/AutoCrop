//
//  ViewController.h
//  AutoCrop
//
//  Created by KP on 22/06/2017.
//  Copyright © 2017 KP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak) IBOutlet NSPopUpButtonCell *photoRatios;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (strong) NSImage *selectedPhoto; // deprecate it please
@property (strong, nonatomic) NSArray *photos;

@property int referenceNum;

@end


//
//  ViewController.h
//  AutoCrop
//
//  Created by KP on 22/06/2017.
//  Copyright © 2017 KP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController <NSTextFieldDelegate>

@property (weak) IBOutlet NSPopUpButtonCell *photoRatios;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (strong, nonatomic) NSArray *photos;
@property (weak) IBOutlet NSTextField *widthLabel;
@property (weak) IBOutlet NSTextField *heightLabel;
@property (weak) IBOutlet NSTextField *dpiLabel;

@property int referenceNum;
@property CGFloat width;
@property CGFloat height;
@property int dpiNum;

@end


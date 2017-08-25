//
//  ViewController.m
//  AutoCrop
//
//  Created by KP on 22/06/2017.
//  Copyright © 2017 KP. All rights reserved.
//

#import "ViewController.h"
#import <Quartz/Quartz.h>

typedef NS_ENUM(NSInteger, StatusMsg) {
    WelcomeMsg
};

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupPopUpButton];
    
    self.statusLabel.stringValue = @"Welcome, start by filling in the metrics. Then, select a photo!";
    self.referenceNum = 1000;
    self.width = 0.;
    self.height = 0.;
    self.dpiNum = 600; // Default DPI
    
    [self.widthLabel setDelegate:self];
    [self.heightLabel setDelegate:self];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self.view.window setTitle:@"AutoCrop"];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (void)setupPopUpButton {
    [self.photoRatios removeAllItems];
    [self.photoRatios addItemsWithTitles:@[@"1",@"2",@"3",@"4",@"5"]];
    [self.photoRatios selectItemAtIndex:0];
}

- (void)controlTextDidChange:(NSNotification *)obj {
    NSTextField *textField = [obj object];
    
    if (textField == self.widthLabel) {
        self.width = [textField doubleValue];
    } else if (textField == self.heightLabel) {
        self.height = [textField doubleValue];
    } else if (textField == self.dpiLabel) {
        self.dpiNum = [textField intValue];
    }
}

#pragma mark - Select Photo

- (IBAction)selectPhoto:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:YES];
    [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"png", @"PNG", nil]];
    
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSFileHandlingPanelOKButton) {
        NSMutableArray *photos = [[NSMutableArray alloc] init];
        
        for (NSURL *url in [panel URLs]) {
            NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
            [photos addObject:image];
        }
        
        self.photos = [NSArray arrayWithArray:photos];
        self.statusLabel.stringValue = (self.photos.count > 1) ? @"Photos selected!" : @"Photo selected!";
    } else {
        self.statusLabel.stringValue = @"Choose photo(s).";
    }
}

#pragma mark - Crop

- (IBAction)initializeCrop:(id)sender {
    for (NSImage *photo in self.photos) {
        [self cropPhoto:photo];
    }
}

- (void)cropPhoto:(NSImage *)photo {
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)[photo TIFFRepresentation], NULL);
    CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
    
    // Initializations of variables
    BOOL cropSuccess = false;
    CGRect cropArea = CGRectZero;
    int totalNumOfCrops = (int) self.photoRatios.indexOfSelectedItem + 1;
    
    for (int i=0; i<totalNumOfCrops; i++) {
        cropArea = [self calculateCropPhotoArea:cropArea withIndex:i];
        
        CGImageRef croppedImage = CGImageCreateWithImageInRect(imageRef, cropArea);
        NSLog(@"%@", NSStringFromRect(cropArea));
        
        NSString *urlString = [NSString stringWithFormat:@"~/Desktop/%i.png", self.referenceNum++];
        NSURL *saveUrl = [NSURL fileURLWithPath:[urlString stringByExpandingTildeInPath]];
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)saveUrl, kUTTypePNG, 1, NULL);
        
        if (!destination) {
            NSLog(@"Failed to create CGImageDestinatioRef for %@", urlString);
            break;
        } else {
            CGImageDestinationAddImage(destination, croppedImage, nil);
            
            if (!CGImageDestinationFinalize(destination)) {
                NSLog(@"Failed to write image to %@", saveUrl);
                break;
            }
            cropSuccess = true;
        }
        
        CFRelease(croppedImage);
        CFRelease(destination);
    }
    
    if(cropSuccess) self.statusLabel.stringValue = @"Crop Success!";
    
    CFRelease(source);
    CFRelease(imageRef);
}

- (CGRect)calculateCropPhotoArea:(CGRect)previousArea withIndex:(int)index {
    // Default buffers
    CGFloat buffer = 15.;
    CGFloat spaceBtwPhoto = 10.;
    CGFloat b3 = buffer*3 + spaceBtwPhoto;
    CGFloat b5 = buffer*5 + spaceBtwPhoto*2;
    
    // W&H is based on the SCANNED image, not the ACTUAL image
    CGFloat wh = [self calculatePixelsFromCentimeters:self.width] - buffer*2;
    CGFloat ht = [self calculatePixelsFromCentimeters:self.height] - buffer*2;
    
    // Default cropArea for all initial-index cases.
    CGRect cropArea = CGRectMake(buffer, buffer, wh, ht);
    
    if (self.photoRatios.indexOfSelectedItem != 0 && index != 0) {
        switch (self.photoRatios.indexOfSelectedItem) {
            case 1: {
                if (index == 1) {
                    // Make new crop area, make sure y-axis is transitioned down image's height + 3*buffer
                    // (3*buffer because two for the previous cropped area + one for the newly adjusted y position)
                    cropArea = CGRectMake(buffer, b3 + ht, wh, ht);
                }
            }   break;
            case 2: {
                switch (index) {
                    case 1: {
                        cropArea = CGRectMake(b3 + wh, buffer, wh, ht);
                    }   break;
                    case 2: {
                        // For this case, the width and height are reversed.
                        cropArea = CGRectMake(buffer, b3 + ht, ht, wh);
                    }   break;
                    default:
                        break;
                }
            }   break;
            case 3: {
                switch (index) {
                    case 1: {
                        cropArea = CGRectMake(b3 + wh, buffer, wh, ht);
                    }   break;
                    case 2: {
                        cropArea = CGRectMake(buffer, b3 + ht, wh, ht);
                    }   break;
                    case 3: {
                        cropArea = CGRectMake(b3 + wh, b3 + ht, wh, ht);
                    }   break;
                    default:
                        break;
                }
            }   break;
            case 4: {
                switch (index) {
                    case 1: {
                        cropArea = CGRectMake(buffer, b3 + ht, wh, ht);
                    }   break;
                    case 2: {
                        cropArea = CGRectMake(buffer, b5 + ht*2, wh, ht);
                    }   break;
                    case 3: {
                        cropArea = CGRectMake(b3 + wh, buffer, ht, wh);
                    }   break;
                    case 4: {
                        cropArea = CGRectMake(b3 + wh, b3 + wh, ht, wh);
                    }   break;
                    default:
                        break;
                }
            }   break;
            default:
                break;
        }
    }
    
    return cropArea;
}

#pragma mark - Helper Methods

- (CGFloat)calculatePixelsFromCentimeters:(CGFloat)cm {
    return cm * self.dpiNum / 2.54; // 2.54 centimeters per inch
}

@end

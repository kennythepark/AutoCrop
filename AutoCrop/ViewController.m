//
//  ViewController.m
//  AutoCrop
//
//  Created by KP on 22/06/2017.
//  Copyright © 2017 KP. All rights reserved.
//

#import "ViewController.h"
#import <Quartz/Quartz.h>

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
    CGFloat width = previousArea.size.width;
    CGFloat height = previousArea.size.height;
    CGFloat buffer = 15.;
    
    CGRect cropArea = CGRectZero;
    
    switch (self.photoRatios.indexOfSelectedItem) {
        case 0: {
            // No need for next crop area since total number of crop(s) is 1.
            // 6x8 ratio gets cropped initially from the HP Easy Scan program,
            // thus no need for extra buffers.
            width = 3600. - buffer*2;
            height = 4800.;
            cropArea = CGRectMake(0, 0, width, height);
        } break;
        case 1: {
            switch (index) {
                case 0: {
                    width = 4197. - buffer*2;
                    height = 2985. - buffer*2;
                    cropArea = CGRectMake(buffer, buffer, width, height);
                } break;
                case 1: {
                    // Make new crop area, make sure y-axis is transitioned down image's height + 3*buffer
                    // (3*buffer because two for the previous cropped area + one for the newly adjusted y position)
                    cropArea = CGRectMake(buffer, buffer*3 + height, width, height);
                } break;
                default:
                    break;
            }
        } break;
        case 2: {
            switch (index) {
                case 0: {
                    // W&H is based on the SCANNED image, not the ACTUAL image
                    width = 2440. - buffer*2;
                    height = 3573. - buffer*2;
                    cropArea = CGRectMake(buffer, buffer, width, height);
                } break;
                case 1: {
                    cropArea = CGRectMake(buffer*3 + width, buffer, width, height);
                } break;
                case 2: {
                    // For this case, the width and height are reversed.
                    cropArea = CGRectMake(buffer, buffer*3 + height, height, width);
                } break;
                default:
                    break;
            }
        } break;
        case 3: {
        
        } break;
        case 4: {
            
        } break;
        default:
            break;
    }
    
    return cropArea;
}

#pragma mark - Helper Methods

- (CGFloat)calculatePixelsFromCentimeters:(CGFloat)cm {
    return cm * self.dpiNum / 2.54; // 2.54 centimeters per inch
}

@end

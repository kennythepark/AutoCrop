//
//  ViewController.m
//  AutoCrop
//
//  Created by KP on 22/06/2017.
//  Copyright © 2017 KP. All rights reserved.
//

#import "ViewController.h"
#import <Quartz/Quartz.h>

typedef NS_ENUM(NSInteger, Ratio) {
    Ratio3x5,
    Ratio4x6,
    Ratio5x7,
    Ratio6x8
};

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupPopUpButton];
    
    self.statusLabel.stringValue = @"Welcome, start by selecting a photo!";
    self.referenceNum = 2;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (void)setupPopUpButton {
    [self.photoRatios removeAllItems];
    [self.photoRatios addItemsWithTitles:@[@"3x5",@"4x6",@"5x7",@"6x8"]];
    [self.photoRatios selectItemAtIndex:0];
}

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
    int totalNumOfCrops = [self totalNumberOfCropsByRatio];
    
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
        case Ratio3x5: {
        } break;
        case Ratio4x6: {
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
        case Ratio5x7: {
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
        case Ratio6x8: {
            // No need for next crop area since total number of crop(s) is 1.
            // 6x8 ratio gets cropped initially from the HP Easy Scan program,
            // thus no need for extra buffers.
            width = 3600. - buffer*2;
            height = 4800.;
            cropArea = CGRectMake(0, 0, width, height);
        } break;
        default:
            break;
    }
    
    return cropArea;
}

- (int)totalNumberOfCropsByRatio {
    int totalNumOfCrops = 0;
    
    switch (self.photoRatios.indexOfSelectedItem) {
        case Ratio3x5: {
            totalNumOfCrops = 5;
        } break;
        case Ratio4x6: {
            totalNumOfCrops = 3;
        } break;
        case Ratio5x7: {
            totalNumOfCrops = 2;
        } break;
        case Ratio6x8: {
            totalNumOfCrops = 1;
        } break;
        default:
            break;
    }
    
    return totalNumOfCrops;
}

@end

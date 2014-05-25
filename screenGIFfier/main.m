//
//  main.m
//  ScreenGIFfier
//
//  Created by Alex Manzella on 20/05/14.
//
//


#import <Foundation/Foundation.h>
#import "MobileDeviceAccess.h"
#import <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>

#include <signal.h>

static bool keepRunning = true;
static CGFloat scaleFactor=.25;

void intHandler() {
    keepRunning = false;
}


#define TIME_TO_WAIT 0.05

@interface MPListener : NSObject<MobileDeviceAccessListener>

@end

void exportAnimatedGifFromImages(NSArray *images);
id resizedImage(NSImage* image);

int main(int argc, char * const argv[])
{
    
    @autoreleasepool {
        
        signal(SIGINT, intHandler);
        
        
        MPListener *listener=[[[MPListener alloc] init] autorelease];
        [[MobileDeviceAccess singleton] setListener:listener];
        [[MobileDeviceAccess singleton] waitForConnection];
        
        for(AMDevice *device in [[MobileDeviceAccess singleton] devices]){
            AMScreenshotService* screenshotService=[device newAMScreenshotService];
            NSMutableArray *arr=[[[NSMutableArray alloc] init] autorelease];
            while (keepRunning) {
                NSLog(@"image captured %lu\n PRESS Control+C to stop and create the GIF",arr.count+1);
                NSImage *screen=[screenshotService getScreenshot];
                if(screen)
                    [arr addObject:screen];
                sleep(TIME_TO_WAIT);
            }
            exportAnimatedGifFromImages(arr);
        }
        //
        //    dispatch_semaphore_wait(dispatch_semaphore_create(0), DISPATCH_TIME_FOREVER);
        
    }
    return 0;
}

#import <ImageIO/ImageIO.h>

void exportAnimatedGifFromImages(NSArray *images)
{
    if (!images) {
        return;
    }
    NSString *path = [NSString stringWithFormat:[@"~/Desktop/screen%@.gif" stringByExpandingTildeInPath],[NSDate date]];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path],
                                                                        kUTTypeGIF,
                                                                        images.count,
                                                                        NULL);
    
    NSDictionary *frameProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:TIME_TO_WAIT] forKey:(NSString *)kCGImagePropertyGIFDelayTime]
                                                                forKey:(NSString *)kCGImagePropertyGIFDictionary];
    NSDictionary *gifProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCGImagePropertyGIFLoopCount]
                                                              forKey:(NSString *)kCGImagePropertyGIFDictionary];
    
    for (NSImage *image in images) {
        
        image=(NSImage *)resizedImage(image);
        
        CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)[image TIFFRepresentation], NULL);
        CGImageRef maskRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CGImageDestinationAddImage(destination, maskRef, (CFDictionaryRef)frameProperties);
        
        CFRelease(source);
        CFRelease(maskRef);
    }
    
    
    CGImageDestinationSetProperties(destination, (CFDictionaryRef)gifProperties);
    CGImageDestinationFinalize(destination);
    CFRelease(destination);
    NSLog(@"Animated GIF file created at %@", path);
}

id resizedImage(NSImage* image)
{
    NSImage *sourceImage = image;
    
    CGSize scaledSize=CGSizeMake(image.size.width*scaleFactor, image.size.height*scaleFactor);

    NSRect targetFrame = NSMakeRect(0, 0, scaledSize.width, scaledSize.height);
    NSImage* targetImage = nil;
    NSImageRep *sourceImageRep =
    [sourceImage bestRepresentationForRect:targetFrame
                                   context:nil
                                     hints:nil];
    
    targetImage = [[NSImage alloc] initWithSize:scaledSize];
    
    [targetImage lockFocus];
    [sourceImageRep drawInRect: targetFrame];
    [targetImage unlockFocus];
    
    return targetImage;
}

@implementation MPListener



- (void)deviceConnected:(AMDevice*)device{
    NSLog(@"%@",[[MobileDeviceAccess singleton] devices]);
    
}
- (void)deviceDisconnected:(AMDevice*)device{
    NSLog(@"%@",[[MobileDeviceAccess singleton] devices]);
    
}

@end
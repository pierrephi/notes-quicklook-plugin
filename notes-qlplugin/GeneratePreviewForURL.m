//  Created by Pierre-Philippe di Costanzo on 01/11/13.
//  Copyright (c) 2013 pierrephi.net. All rights reserved.

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import "Cocoa/Cocoa.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
 Generate a preview for file
 
 This function's job is to create preview for designated file
 ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    @autoreleasepool {
        
        // Stored as a plist, parse it into a NSDictionary
        
        NSURL* nsurl =  (__bridge NSURL *)(url);
        NSData* data = [NSData dataWithContentsOfURL:nsurl];
        NSDictionary* plist = [NSPropertyListSerialization propertyListWithData: data
                                                                        options: NSPropertyListImmutable
                                                                         format: NULL
                                                                          error: nil];
        
        if (!plist) return noErr;
        
        // Prepare format attributes and output
        // using a NSAttributedString later converted to RTF format
        NSDictionary *stdAttrs =       @{ NSFontAttributeName : [NSFont fontWithName:@"Helvetica" size:12.0]};
        NSDictionary *boldBlackAttrs = @{ NSFontAttributeName : [NSFont fontWithName:@"Helvetica-Bold" size:12.0] };
        NSDictionary *boldAttrs =      @{ NSFontAttributeName : [NSFont fontWithName:@"Helvetica-Bold" size:12.0],
                                          NSForegroundColorAttributeName : [NSColor grayColor]
                                          };
        
        NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];

        // Set up for producing attributed string output
        NSMutableAttributedString *output = [[NSMutableAttributedString alloc] init];
        
        
        NSString *uti = (__bridge NSString *)(contentTypeUTI);
        if ([uti hasSuffix:@"notes.virtual.message"]) {
            
            NSString *from = (NSString *) [plist objectForKey:@"from"];
            if (from) {
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:@"from: " attributes: boldAttrs]];
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:from attributes: boldBlackAttrs]];
                [output appendAttributedString: newline];
            }
            
            NSString *to = (NSString *) [plist objectForKey:@"to"];
            if (to) {
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:@"to: " attributes: boldAttrs]];
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:to attributes: stdAttrs]];
                [output appendAttributedString: newline];
            }
            
            NSString *cc = (NSString *) [plist objectForKey:@"cc"];
            if (cc) {
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:@"cc: " attributes: boldAttrs]];
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:cc attributes: stdAttrs]];
                [output appendAttributedString: newline];
                
            }
            
            NSString *bcc = (NSString *) [plist objectForKey:@"bcc"];
            if (bcc) {
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:@"bcc: " attributes: boldAttrs]];
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:bcc attributes: stdAttrs]];
                [output appendAttributedString: newline];
                
            }
            
            
            NSString *subject = (NSString *) [plist objectForKey:@"subject"];
            if (subject) {
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:@"subject: " attributes: boldAttrs]];
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:subject attributes: boldBlackAttrs]];
                [output appendAttributedString: newline];
                
            }
            [output appendAttributedString: newline];
            
            
            NSString *body = (NSString *) [plist objectForKey:@"com.ibm.notes.content"];
            
            [body stringByReplacingOccurrencesOfString:@"<CR>"
                                            withString:@"\n"];
            if (body) {
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:body attributes: stdAttrs]];
                [output appendAttributedString: newline];
                
            }
        } else if ([uti hasSuffix:@"notes.virtual.calendar"]) {
            
            NSString *organizer = (NSString *) [plist objectForKey:@"organizer"];
            if (organizer) {
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:@"organizer: " attributes: boldAttrs]];
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:organizer attributes: boldBlackAttrs]];
                [output appendAttributedString: newline];
            }
            
            NSString *location = (NSString *) [plist objectForKey:@"location"];
            if (location) {
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:@"location: " attributes: boldAttrs]];
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:location attributes: stdAttrs]];
                [output appendAttributedString: newline];
                
            }
            
            NSDate *startDate = (NSDate *) [plist objectForKey:@"start_date"];
            NSDate *endDate = (NSDate *) [plist objectForKey:@"end_date"];
            NSString *eventDuration = (NSString *) [plist objectForKey:@"duration"];

            // Format start, end and duration of meeting
            // last 2 optional
            // don't repeat the day in endDate if same as startDate
            
            if (startDate) {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                [dateFormatter setDateStyle:NSDateFormatterShortStyle];
                
                NSDateFormatter *dateOnlyFormatter = [[NSDateFormatter alloc] init];
                [dateOnlyFormatter setTimeStyle:NSDateFormatterNoStyle];
                [dateOnlyFormatter setDateStyle:NSDateFormatterShortStyle];
                
                NSDateFormatter *timeOnlyFormatter = [[NSDateFormatter alloc] init];
                [timeOnlyFormatter setTimeStyle:NSDateFormatterShortStyle];
                [timeOnlyFormatter setDateStyle:NSDateFormatterNoStyle];
                
                [output appendAttributedString:[[NSAttributedString alloc] initWithString: [dateFormatter stringFromDate:startDate]
                                                                               attributes: boldAttrs]];
                if (endDate) {
                    [output appendAttributedString:[[NSAttributedString alloc] initWithString: @" to " attributes: boldAttrs]];
                    if ([[dateOnlyFormatter stringFromDate:startDate] isEqualToString:[dateOnlyFormatter stringFromDate:endDate]]) {
                        [output appendAttributedString:[[NSAttributedString alloc] initWithString: [timeOnlyFormatter stringFromDate:endDate]
                                                                                       attributes: boldAttrs]];
                    } else {
                        [output appendAttributedString:[[NSAttributedString alloc] initWithString: [dateFormatter stringFromDate:endDate]
                                                                                       attributes: boldAttrs]];
                    }
                }
                if (eventDuration) {
                    double elapsedSeconds = [eventDuration intValue];
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970: elapsedSeconds];
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"HH:mm"];
                    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
                    
                    NSString *durationFmtd = [NSString stringWithFormat:@" (%@)",[formatter stringFromDate:date]];
                    [output appendAttributedString:[[NSAttributedString alloc] initWithString:durationFmtd attributes: boldAttrs]];
                }
                [output appendAttributedString: newline];
            }
            
            NSString *title = (NSString *) [plist objectForKey:@"title"];
            if (title) {
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:@"title: " attributes: boldAttrs]];
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:title attributes: boldBlackAttrs]];
                [output appendAttributedString: newline];
                
            }
            [output appendAttributedString: newline];
            
            
            NSString *body = (NSString *) [plist objectForKey:@"com.ibm.notes.content"];
            
            [body stringByReplacingOccurrencesOfString:@"<CR>"
                                            withString:@"\n"];
            if (body) {
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:body attributes: stdAttrs]];
                [output appendAttributedString: newline];
                
            }
            [output appendAttributedString: newline];

            NSString *attendees = (NSString *) [plist objectForKey:@"attendees"];
            if (attendees) {
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:@"attendees: " attributes: boldAttrs]];
                [output appendAttributedString: [[NSAttributedString alloc] initWithString:attendees attributes: stdAttrs]];
                [output appendAttributedString: newline];
            }

        } else {
            return noErr;
        }
        
        // Get RTF representation of the attributed string
        NSData *rtfData = [output RTFFromRange: NSMakeRange(0, output.length)
                            documentAttributes: nil];
        
        // Pass preview data to QuickLook
        QLPreviewRequestSetDataRepresentation(preview,
                                              (__bridge CFDataRef)rtfData,
                                              kUTTypeRTF,
                                              NULL);
    }
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}

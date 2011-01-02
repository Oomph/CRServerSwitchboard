//
//  ServerSwitchboard.h
//  ServerSwitchboard
//
//  Created by Chris Farber on 30/03/09.
//  All code is provided under the New BSD license.
//

#import <Cocoa/Cocoa.h>

@interface ServerSwitchboard : NSObject {
    CFMutableDictionaryRef connections;
    CFMutableDictionaryRef connectionsData;
    NSUserDefaults * defaults;
    NSURL * apiURL;
}

+ (NSString *)baseURL;
+ switchboard;

// these methods are asynchronous and use a callback
// the callback follows this pattern:
// - (void) requestFinishedWithData: (NSDictionary *)info error: (NSError *)error

- (void) companiesWithTarget:(id)target selector: (SEL)sel;


@end
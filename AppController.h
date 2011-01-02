//
//  AppController.h
//  ServerSwitchboard
//
//  Created by Rick Fillion on 23/07/09.
//  All code is provided under the New BSD license.
//

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
    NSArray *companies;
    BOOL updating;
}

@property (nonatomic, copy) NSArray *companies;
@property (nonatomic, assign) BOOL updating;

- (IBAction)update:(id)sender;

@end

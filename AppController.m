//
//  AppController.m
//  ServerSwitchboard
//
//  Created by Rick Fillion on 23/07/09.
//  All code is provided under the New BSD license.
//

#import "AppController.h"
#import "ServerSwitchboard.h"

@implementation AppController

@synthesize companies;
@synthesize updating;

- (void)awakeFromNib
{
    [self update: self];
}

- (void)updateCompanies:(NSDictionary *)returnData error:(NSError *)error
{
    self.updating = NO;
    if (error)
    {
        // handle the error
        return;
    }
    self.companies = [returnData valueForKey:@"companies"];
}

- (IBAction)update:(id)sender
{
    self.updating = YES;
    self.companies = [NSArray array];
    [[ServerSwitchboard switchboard] companiesWithTarget:self selector:@selector(updateCompanies:error:)];
}

@end

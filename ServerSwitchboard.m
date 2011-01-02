//
//  ServerSwitchboard.m
//  Bodega
//
//  Created by Chris Farber on 30/03/09.
//  All code is provided under the New BSD license.
//


#import "ServerSwitchboard.h"
#import "JSON.h"

static ServerSwitchboard * sharedSwitchboard =  nil;

@interface ServerSwitchboard (Private)

- (void) _sendRequest: (NSString *)verb withData: (NSDictionary *)data forPath: (NSString *)subpath
               target: (id)target selector: (SEL)sel;
- (void) _returnResponseForConnection: (NSURLConnection *)connection;
- (void) connection: (NSURLConnection *)connection didReceiveResponse: (NSHTTPURLResponse *)response;
- (void) connection: (NSURLConnection *)connection didReceiveData: (NSData *)data;
- (void) connection: (NSURLConnection *)connection didFailWithError: (NSError *)error;
- (void) connectionDidFinishLoading: (NSURLConnection *)connection; 

@end

@implementation ServerSwitchboard

+ (NSString *)baseURL
{
    return @"http://centrix.ca/";
}

+ switchboard
{
    if (!sharedSwitchboard) [self new];
    return sharedSwitchboard;
}

- init
{
    [super init];
    if (sharedSwitchboard) {
        [self release];
        return sharedSwitchboard;
    }
    connections = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks,
                                            &kCFTypeDictionaryValueCallBacks);
    connectionsData = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks,
                                                &kCFTypeDictionaryValueCallBacks);
    apiURL = [[NSURL alloc] initWithString: [NSString stringWithFormat:@"%@/code/", [ServerSwitchboard baseURL]]];
    defaults = [NSUserDefaults standardUserDefaults];
    sharedSwitchboard = self;
    return self;
}

- (void)dealloc
{
    [defaults release];
    CFRelease(connections);
    CFRelease(connectionsData);
    [apiURL release];
    [super dealloc];
}

- (void) companiesWithTarget:(id)target selector: (SEL)sel
{
    [self _sendRequest: @"GET"
              withData: nil
               forPath: @"sample.json"
                target: target
              selector: sel];
}



@end

@implementation ServerSwitchboard (Private)

- (void)_sendRequest: (NSString *)verb withData: (NSDictionary *)data forPath: (NSString *)subpath
              target: (id)target selector: (SEL)sel
{
    NSURL * requestURL = [NSURL URLWithString: subpath relativeToURL: apiURL];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL: requestURL];
    [request setHTTPMethod: verb];
    if (data) {
        [request setValue: @"application/json" forHTTPHeaderField: @"Content-Type"];
        [request setHTTPBody: [[data JSONRepresentation] dataUsingEncoding: NSUTF8StringEncoding]];
        //NSLog(@"json rep = %@", [data JSONRepresentation]);
    }
    NSURLConnection * connection = [[NSURLConnection alloc]
                                    initWithRequest: request delegate: self];
    if (!connection) {
        NSError * error = [NSError errorWithDomain: @"ServerSwitchboardError"
                                              code: 1
                                          userInfo: nil];
        [target performSelector: sel withObject: nil withObject: error];
        return;
    }
    CFDictionarySetValue(connectionsData, connection, [NSMutableData data]);
    NSValue * selector = [NSValue value: &sel withObjCType: @encode(SEL)];
    NSDictionary * targetInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 selector, @"selector",
                                 target, @"target",
                                 nil];
    CFDictionarySetValue(connections, connection, targetInfo);
}

- (void) connection: (NSURLConnection *)connection didReceiveResponse: (NSHTTPURLResponse *)response
{
    NSMutableDictionary * targetInfo = (id)CFDictionaryGetValue(connections, connection);
    [targetInfo setValue: response forKey: @"response"];
}

- (void) connection: (NSURLConnection *)connection didReceiveData: (NSData *)data
{
    NSMutableData * connectionData = (id)CFDictionaryGetValue(connectionsData, connection);
    [connectionData appendData: data];
}

- (void) connection: (NSURLConnection *)connection didFailWithError: (NSError *)error
{
    NSMutableDictionary * targetInfo = (id)CFDictionaryGetValue(connections, connection);
    [targetInfo setValue: error forKey: @"error"];
    [self _returnResponseForConnection: connection];
}

- (void) connectionDidFinishLoading: (NSURLConnection *)connection
{
    [self _returnResponseForConnection: connection];
}

- (void) _returnResponseForConnection: (NSURLConnection *)connection
{
    NSMutableDictionary * targetInfo = (id)CFDictionaryGetValue(connections, connection);
    NSMutableData * data = (id)CFDictionaryGetValue(connectionsData, connection);
    id target = [targetInfo valueForKey: @"target"];
    SEL selector;
    [[targetInfo valueForKey: @"selector"] getValue: &selector];
    NSError * error = [targetInfo valueForKey: @"error"];
    if (!error) {
        NSHTTPURLResponse * response = [targetInfo valueForKey: @"response"];
        NSInteger status = [response statusCode];
        if (status != 200) error = [NSError errorWithDomain: @"APIError" code: status userInfo: nil];
    }
    NSDictionary * dataDictionary = nil;
    if ([data length] && [error code] != 401) {
        NSString * json = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
        NSLog(@"got response: %@", json);
        dataDictionary = [json JSONValue];
    }
    [target performSelector: selector withObject: dataDictionary withObject: error];
    CFDictionaryRemoveValue(connections, connection);
    CFDictionaryRemoveValue(connectionsData, connection);
    [connection release];
}


@end
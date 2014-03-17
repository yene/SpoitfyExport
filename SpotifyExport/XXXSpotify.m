//
//  XXXSpotify.m
//  SpotifyExport
//
//  Created by Yannick Weiss on 17/03/14.
//  Copyright (c) 2014 Yannick Weiss. All rights reserved.
//

#import "XXXSpotify.h"
#import <SocketRocket/SRWebSocket.h>

NSString *const AuthServer = @"play.spotify.com";
NSString *const AuthUrl = @"/xhr/json/auth.php";
NSString *const LandingUrl = @"/";
NSString *const UserAgent = @"Mozilla/5.0 (Chrome/13.37 compatible-ish) spotify-web/1";
NSString *const SourceUrl = @"https://d3rt1990lpmkn.cloudfront.net";

@interface XXXSpotify () {
  NSString *csrftoken;
  NSString *trackingId;
  NSString *username;
  NSString *password;
  NSString *type;
  NSDictionary *settings;
  SRWebSocket *webSocket;
}
@end

@implementation XXXSpotify

- (void)loginWithUsername:(NSString *)ausername password:(NSString *)apassword;
{
  username = ausername;
  password = apassword;
  type = @"sp";
  
  [self makeLandingPageRequest];
}

- (void)makeLandingPageRequest;
{
  NSString *url = [NSString stringWithFormat:@"https://%@%@", AuthServer, LandingUrl];
  NSLog(@"GET %@", url);
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
  
  [request setHTTPMethod: @"GET"];
  [request addValue:UserAgent forHTTPHeaderField:@"User-Agent"];
  
  NSError *requestError;
  NSHTTPURLResponse *urlResponse = nil;
  
  
  NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
  
  if([urlResponse statusCode] != 200){
    NSLog(@"Error getting %@, HTTP status code %i", url, [urlResponse statusCode]);
    return;
  }
  
  if (requestError) {
    NSLog(@"failed to get the landing page, please check your internet"); // TODO show user dialog
  } else {
    [self getSecret:response];
  }
}

- (void)getSecret:(NSData *)responseData;
{
  NSString *bla = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
  NSRange range = [bla rangeOfString:@"csrftoken"];
  range.location += range.length + 3;
  range.length = 32;
  csrftoken = [bla substringWithRange:range];
  range = [bla rangeOfString:@"trackingId"];
  range.location += range.length + 3;
  range.length = 40;
  trackingId = [bla substringWithRange:range];
  
  
  NSString *url = [NSString stringWithFormat:@"https://%@%@", AuthServer, AuthUrl];
  NSLog(@"POST to %@", url);
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
  
  [request setHTTPMethod: @"POST"];
  [request addValue:UserAgent forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"]; //
  [request setValue:@"https://play.spotify.com/" forHTTPHeaderField:@"Referer"];
  
 
  //NSString *post =[[NSString alloc] initWithFormat:@"userName=%@&password=%@",userName.text,password.text];
  
  NSString *myRequestString = [NSString stringWithFormat:@"type=%@&username=%@&password=%@&secret=%@&trackingId=%@&referrer=&landingURL=%@&cf=&f=contextual&s=direct", type, username, password, csrftoken, trackingId, AuthServer];
  
  NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
  [request setHTTPBody:myRequestData];
  
  NSError *requestError;
  NSHTTPURLResponse *urlResponse = nil;
  
  NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
  
  if([urlResponse statusCode] != 200){
    NSLog(@"Error getting %@, HTTP status code %i", url, [urlResponse statusCode]);
    return;
  }
  
  if (!requestError) {
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableContainers error:nil];
    if ([[result objectForKey:@"status"] isEqualToString:@"ERROR"] ) {
      NSLog(@"error: %@", [result objectForKey:@"error"]);
    } else {
      settings = [result objectForKey:@"config"];
      [self resolveAP];
    }
    
  }
}

- (void)resolveAP;
{
  NSDictionary *resolver = [settings valueForKeyPath:@"aps.resolver"];
  NSString *myRequestString = [NSString stringWithFormat:@"client=24:0:0:%@", [settings valueForKeyPath:@"version"]];
  if ([resolver objectForKey:@"site"] != [NSNull null]) {
    myRequestString = [NSString stringWithFormat:@"%@&site=%@", myRequestString, [resolver objectForKey:@"site"]];
  }
  
  NSString *url = [NSString stringWithFormat:@"http://%@/?%@", [resolver objectForKey:@"hostname"], myRequestString];
  NSLog(@"GET to %@", url);
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
  
  [request setHTTPMethod: @"GET"];
  [request addValue:UserAgent forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"https://play.spotify.com/" forHTTPHeaderField:@"Referer"];
  
  NSError *requestError;
  NSHTTPURLResponse *urlResponse = nil;
  
  NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
  
  if([urlResponse statusCode] != 200){
    NSLog(@"Error getting %@, HTTP status code %i", url, [urlResponse statusCode]);
    return;
  }
  
  if (!requestError) {
    [self openWebsocketWithData:response];
    
  }

}

- (void)openWebsocketWithData:(NSData *)res;
{
  NSDictionary *result = [NSJSONSerialization JSONObjectWithData:res options:NSJSONReadingMutableContainers error:nil];
  
  NSArray *ap_list =[result objectForKey:@"ap_list"];
  NSString *url = [NSString stringWithFormat:@"wss://%@/", ap_list[0]];
  
  webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:url]];
  webSocket.delegate = self;
  
  //[webSocket open];
  
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
  
}
- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
  
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
  
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
  
}

@end

//
//  XXXSpotify.m
//  SpotifyExport
//
//  Created by Yannick Weiss on 17/03/14.
//  Copyright (c) 2014 Yannick Weiss. All rights reserved.
//

#import "XXXSpotify.h"

NSString *const AuthServer = @"play.spotify.com";
NSString *const AuthUrl = @"/xhr/json/auth.php";
NSString *const LandingUrl = @"/";
NSString *const UserAgent = @"Mozilla/5.0 (Chrome/13.37 compatible-ish) spotify-web/1";
NSString *const SourceUrl = @"https://d3rt1990lpmkn.cloudfront.net";

@interface XXXSpotify () {
  
}
@end

@implementation XXXSpotify

- (void)loginWithUsername:(NSString *)username password:(NSString *)password;
{
  
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
    NSLog(@"failed to get the landing page");
  } else {
    [self getSecret:response];
  }
}

- (void)getSecret:(NSData *)responseData;
{
  NSString *bla = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
  NSLog(@"%@", bla);
  NSRange range = [bla rangeOfString:@"csrftoken"];
  range.location += range.length + 3;
  range.length = 32;
  NSString *csrftoken = [bla substringWithRange:range];
  range = [bla rangeOfString:@"trackingId"];
  range.location += range.length + 3;
  range.length = 40;
  NSString *trackingId = [bla substringWithRange:range];
  
  
  NSString *url = [NSString stringWithFormat:@"https://%@%@", AuthServer, AuthUrl];
  NSLog(@"GET %@", url);
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
  
  [request setHTTPMethod: @"POST"];
  [request addValue:UserAgent forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  
  NSDictionary *jsonDict = @{
                             @"type" : @"sp",
                             @"username" : @"yene",
                             @"password" : @"password",
                             
                               @"secret" : csrftoken,
                               @"trackingId" : trackingId,
                               @"landingURL" : AuthServer,
                               @"referrer" : @"",
                               @"cf" : @""
                               };
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonRequest = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSLog(@"jsonRequest is %@", jsonRequest);
  
  
  
  // content type  application/x-www-form-urlencoded; charset=UTF-8
  // refer https://play.spotify.com/
  [request setHTTPBody:jsonInputData];
  
  NSError *requestError;
  NSHTTPURLResponse *urlResponse = nil;
  
  
  NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
  
  if([urlResponse statusCode] != 200){
    NSLog(@"Error getting %@, HTTP status code %i", url, [urlResponse statusCode]);
    return;
  }
  
  if (requestError) {
    NSLog(@"failed to get the landing page");
  } else {
    
    
    NSString *bla = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableContainers error:nil];
    if ([[result objectForKey:@"status"] isEqualToString:@"ERROR"] ) {
      NSLog(@"error: %@", [result objectForKey:@"error"]);
    } else {
      
    }
    
  }
  
  
}

@end

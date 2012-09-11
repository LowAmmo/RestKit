//
//  RKAuthenticationTest.m
//  RestKit
//
//  Created by Blake Watters on 3/14/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKTestEnvironment.h"
#import "RKClient.h"

static NSString * const RKAuthenticationTestUsername = @"restkit";
static NSString * const RKAuthenticationTestPassword = @"authentication";
static NSString * const RKAuthenticationTestRealm = @"RestKit";

@interface RKAuthenticationTest : RKTestCase {

}

+(void)clearCredentialStorageForClient:(RKClient*)client;
+(void)clearCredentialStorageForSpace:(NSURLProtectionSpace*)protectionSpace;

@end

@implementation RKAuthenticationTest

- (void)testShouldAccessUnprotectedResourcePaths
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKClient *client = [RKTestFactory client];
    [client get:@"/authentication/none" delegate:loader];
    [loader waitForResponse];
    assertThatBool([loader.response isOK], is(equalToBool(YES)));
}

- (void)testShouldAuthenticateViaHTTPAuthBasic
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKClient *client = [RKTestFactory client];
    client.username = RKAuthenticationTestUsername;
    client.password = RKAuthenticationTestPassword;
    [client get:@"/authentication/basic" delegate:loader];
    [loader waitForResponse];
    assertThatBool([loader.response isOK], is(equalToBool(YES)));
}

- (void)testShouldFailAuthenticationWithInvalidCredentialsForHTTPAuthBasic
{
    RKTestResponseLoader *loader = [RKTestResponseLoader new];
    RKClient *client = [RKTestFactory client];
    client.username = RKAuthenticationTestUsername;
    client.password = @"INVALID";
    [client get:@"/authentication/basic" delegate:loader];
    [loader waitForResponse];
    assertThatBool([loader.response isOK], is(equalToBool(NO)));
    assertThatInteger([loader.response statusCode], is(equalToInt(0)));
    assertThatInteger([loader.error code], is(equalToInt(NSURLErrorUserCancelledAuthentication)));
    [loader.response.request cancel];
    [loader release];
}

- (void)testShouldAuthenticateViaHTTPAuthDigest
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKClient *client = [RKTestFactory client];
    client.username = RKAuthenticationTestUsername;
    client.password = RKAuthenticationTestPassword;
    [client get:@"/authentication/digest" delegate:loader];
    [loader waitForResponse];
    assertThatBool([loader.response isOK], is(equalToBool(YES)));
}

- (void)testUseCredentialStoreToAuthenticateViaHTTPAuthBasic
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKClient *client = [RKTestFactory client];
    client.authenticationType = RKRequestAuthenticationTypeHTTPBasic;
    client.username = nil;
    client.password = nil;

    NSURLCredential* credential = [NSURLCredential credentialWithUser:RKAuthenticationTestUsername
                                                             password:RKAuthenticationTestPassword
                                                          persistence:NSURLCredentialPersistenceForSession];
    NSURLProtectionSpace* protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:client.baseURL.host
                                                                                  port:client.baseURL.port.intValue
                                                                              protocol:client.baseURL.scheme
                                                                                 realm:RKAuthenticationTestRealm
                                                                  authenticationMethod:NSURLAuthenticationMethodDefault];
    [RKAuthenticationTest clearCredentialStorageForSpace:protectionSpace];
    
    [[NSURLCredentialStorage sharedCredentialStorage] setCredential:credential forProtectionSpace:protectionSpace];
    
    [client get:@"/authentication/basic" delegate:loader];
    [loader waitForResponse];
    assertThatBool([loader.response isOK], is(equalToBool(YES)));
    
    [RKAuthenticationTest clearCredentialStorageForSpace:protectionSpace];
    
    //Resets the authentication for the connection
    [client get:@"/authentication/fail" delegate:loader];
    [loader waitForResponse];
    assertThatBool([loader.response isOK], is(equalToBool(NO)));
}

- (void)testUseCredentialStoreToAuthenticateViaHTTPFormAuth
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKClient *client = [RKTestFactory client];
    client.authenticationType = RKRequestAuthenticationTypeNone;
    client.username = nil;
    client.password = nil;
    
    NSURLCredential* credential = [NSURLCredential credentialWithUser:RKAuthenticationTestUsername
                                                             password:RKAuthenticationTestPassword
                                                          persistence:NSURLCredentialPersistenceForSession];
    NSURLProtectionSpace* protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:client.baseURL.host
                                                                                  port:client.baseURL.port.intValue
                                                                              protocol:client.baseURL.scheme
                                                                                 realm:RKAuthenticationTestRealm
                                                                  authenticationMethod:NSURLAuthenticationMethodHTMLForm];
    [RKAuthenticationTest clearCredentialStorageForSpace:protectionSpace];
    
    [[NSURLCredentialStorage sharedCredentialStorage] setCredential:credential forProtectionSpace:protectionSpace];
    
    [client post:@"/authentication/form" params:nil delegate:loader];
    [loader waitForResponse];
    assertThatBool([loader.response isOK], is(equalToBool(YES)));
    
    [RKAuthenticationTest clearCredentialStorageForSpace:protectionSpace];
    
    //Resets the authentication for the connection
    [client get:@"/authentication/fail" delegate:loader];
    [loader waitForResponse];
    assertThatBool([loader.response isOK], is(equalToBool(NO)));
}


#pragma mark - Static Helpers

+(void)clearCredentialStorageForClient:(RKClient*)client
{
    NSString* authMethod = nil;
    switch (client.authenticationType)
    {
        case RKRequestAuthenticationTypeHTTPBasic:
            authMethod = NSURLAuthenticationMethodHTTPBasic;
            break;
        case RKRequestAuthenticationTypeHTTP:
        case RKRequestAuthenticationTypeNone:
        default:
            authMethod = NSURLAuthenticationMethodDefault;
            break;
    }
    
    NSURLProtectionSpace* protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:client.baseURL.host
                                                                                  port:client.baseURL.port.intValue
                                                                              protocol:client.baseURL.scheme
                                                                                 realm:RKAuthenticationTestRealm
                                                                  authenticationMethod:authMethod];
    
    [RKAuthenticationTest clearCredentialStorageForSpace:protectionSpace];
}

+(void)clearCredentialStorageForSpace:(NSURLProtectionSpace*)protectionSpace
{
    NSDictionary* credentials = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protectionSpace];
    for(NSURLCredential* credential in credentials.allValues)
    {
        [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential forProtectionSpace:protectionSpace];
    }
}

@end

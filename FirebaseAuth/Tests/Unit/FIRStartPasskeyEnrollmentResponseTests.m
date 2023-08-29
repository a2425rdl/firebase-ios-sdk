/*
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <XCTest/XCTest.h>

#import "FirebaseAuth/Sources/Public/FirebaseAuth/FIRAuthErrors.h"

#import "FirebaseAuth/Sources/Backend/FIRAuthBackend.h"
#import "FirebaseAuth/Sources/Backend/RPC/FIRStartPasskeyEnrollmentRequest.h"
#import "FirebaseAuth/Sources/Backend/RPC/FIRStartPasskeyEnrollmentResponse.h"
#import "FirebaseAuth/Sources/Utilities/FIRAuthInternalErrors.h"
#import "FirebaseAuth/Tests/Unit/FIRFakeBackendRPCIssuer.h"

/** @var kTestAPIKey
    @brief Fake API key used for testing.
 */
static NSString *const kTestAPIKey = @"APIKey";

/** @var kTestFirebaseAppID
    @brief Fake Firebase app ID used for testing.
 */
static NSString *const kTestFirebaseAppID = @"appID";

/**
 @var kIDToken
 @brief Token representing the user's identity.
 */
static NSString *const kIDToken = @"idToken";

/** @var kUsersKey
    @brief the name of the "users" property in the response.
 */
static NSString *const kUsersKey = @"users";

static NSString *const kTestRpKey = @"rp";
static NSString *const kTestChallengeKey = @"challenge";
static NSString *const kTestUserKey = @"user";
static NSString *const kTestIDKey = @"id";

static NSString *const kTestRpID = @"1234567890";
static NSString *const kTestChallenge = @"challengebytes";
static NSString *const kTestUserID = @"user-id";

@interface FIRStartPasskeyEnrollmentResponseTests : XCTestCase
@end
@implementation FIRStartPasskeyEnrollmentResponseTests {
  /**
   @brief This backend RPC issuer is used to fake network responses for each test in the suite.
   In the @c setUp method we initialize this and set @c FIRAuthBackend's RPC issuer to it.
   */
  FIRFakeBackendRPCIssuer *_RPCIssuer;

  /**
   @brief This is the request configuration used for testing.
   */
  FIRAuthRequestConfiguration *_requestConfiguration;
}

- (void)setUp {
  [super setUp];
  FIRFakeBackendRPCIssuer *RPCIssuer = [[FIRFakeBackendRPCIssuer alloc] init];
  [FIRAuthBackend setDefaultBackendImplementationWithRPCIssuer:RPCIssuer];
  _RPCIssuer = RPCIssuer;
  _requestConfiguration = [[FIRAuthRequestConfiguration alloc] initWithAPIKey:kTestAPIKey
                                                                        appID:kTestFirebaseAppID];
}

- (void)tearDown {
  _RPCIssuer = nil;
  _requestConfiguration = nil;
  [FIRAuthBackend setDefaultBackendImplementationWithRPCIssuer:nil];
  [super tearDown];
}

/** @fn testSuccessfulGetAccountInfoResponse
    @brief This test simulates a successful @c GetAccountInfo flow.
 */
- (void)testSuccessfulStartPasskeyEnrollmentResponse {
  FIRStartPasskeyEnrollmentRequest *request =
      [[FIRStartPasskeyEnrollmentRequest alloc] initWithIDToken:kIDToken
                                           requestConfiguration:_requestConfiguration];

  __block BOOL callbackInvoked;
  __block FIRStartPasskeyEnrollmentResponse *RPCResponse;
  __block NSError *RPCError;

  [FIRAuthBackend startPasskeyEnrollment:request
                                callback:^(FIRStartPasskeyEnrollmentResponse *_Nullable response,
                                           NSError *_Nullable error) {
                                  callbackInvoked = YES;
                                  RPCResponse = response;
                                  RPCError = error;
                                }];

  [_RPCIssuer respondWithJSON:@{
    @"credentialCreationOptions" : @{
      kTestChallengeKey : kTestChallenge,
      kTestRpKey : @{kTestIDKey : kTestRpID},
      kTestUserKey : @{kTestIDKey : kTestUserID},
    },
  }];

  XCTAssert(callbackInvoked);
  XCTAssertNil(RPCError);
  XCTAssertNotNil(RPCResponse);
  XCTAssertEqualObjects(RPCResponse.rpID, kTestRpID);
  XCTAssertEqualObjects(RPCResponse.challenge, kTestChallenge);
  XCTAssertEqualObjects(RPCResponse.userID, kTestUserID);
}

/** @fn testGetAccountInfoUnexpectedResponseError
    @brief This test simulates an unexpected response returned from server in @c GetAccountInfo
        flow.
 */
- (void)testStartPasskeyEnrollmentResponseMissingCreationOptionsError {
  FIRStartPasskeyEnrollmentRequest *request =
      [[FIRStartPasskeyEnrollmentRequest alloc] initWithIDToken:kIDToken
                                           requestConfiguration:_requestConfiguration];

  __block BOOL callbackInvoked;
  __block FIRStartPasskeyEnrollmentResponse *RPCResponse;
  __block NSError *RPCError;

  [FIRAuthBackend startPasskeyEnrollment:request
                                callback:^(FIRStartPasskeyEnrollmentResponse *_Nullable response,
                                           NSError *_Nullable error) {
                                  callbackInvoked = YES;
                                  RPCResponse = response;
                                  RPCError = error;
                                }];

  [_RPCIssuer respondWithJSON:@{
    @"wrongkey" : @{},
  }];
  [self errorValidationHelperWithCallbackInvoked:callbackInvoked
                                        rpcError:RPCError
                                     rpcResponse:RPCResponse];
}

- (void)testStartPasskeyEnrollmentResponseMissingRpIdError {
  FIRStartPasskeyEnrollmentRequest *request =
      [[FIRStartPasskeyEnrollmentRequest alloc] initWithIDToken:kIDToken
                                           requestConfiguration:_requestConfiguration];

  __block BOOL callbackInvoked;
  __block FIRStartPasskeyEnrollmentResponse *RPCResponse;
  __block NSError *RPCError;

  [FIRAuthBackend startPasskeyEnrollment:request
                                callback:^(FIRStartPasskeyEnrollmentResponse *_Nullable response,
                                           NSError *_Nullable error) {
                                  callbackInvoked = YES;
                                  RPCResponse = response;
                                  RPCError = error;
                                }];

  [_RPCIssuer respondWithJSON:@{
    @"credentialCreationOptions" : @{
      kTestChallengeKey : kTestChallenge,
      kTestRpKey : @{},
      kTestUserKey : @{kTestIDKey : kTestUserID},
    },
  }];
  [self errorValidationHelperWithCallbackInvoked:callbackInvoked
                                        rpcError:RPCError
                                     rpcResponse:RPCResponse];
}

- (void)testStartPasskeyEnrollmentResponseMissingUserIdError {
  FIRStartPasskeyEnrollmentRequest *request =
      [[FIRStartPasskeyEnrollmentRequest alloc] initWithIDToken:kIDToken
                                           requestConfiguration:_requestConfiguration];

  __block BOOL callbackInvoked;
  __block FIRStartPasskeyEnrollmentResponse *RPCResponse;
  __block NSError *RPCError;

  [FIRAuthBackend startPasskeyEnrollment:request
                                callback:^(FIRStartPasskeyEnrollmentResponse *_Nullable response,
                                           NSError *_Nullable error) {
                                  callbackInvoked = YES;
                                  RPCResponse = response;
                                  RPCError = error;
                                }];

  [_RPCIssuer respondWithJSON:@{
    @"credentialCreationOptions" : @{
      kTestChallengeKey : kTestChallenge,
      kTestRpKey : @{kTestIDKey : kTestRpID},
      kTestUserKey : @{},
    },
  }];
  [self errorValidationHelperWithCallbackInvoked:callbackInvoked
                                        rpcError:RPCError
                                     rpcResponse:RPCResponse];
}

- (void)testStartPasskeyEnrollmentResponseMissingChallengeError {
  FIRStartPasskeyEnrollmentRequest *request =
      [[FIRStartPasskeyEnrollmentRequest alloc] initWithIDToken:kIDToken
                                           requestConfiguration:_requestConfiguration];

  __block BOOL callbackInvoked;
  __block FIRStartPasskeyEnrollmentResponse *RPCResponse;
  __block NSError *RPCError;

  [FIRAuthBackend startPasskeyEnrollment:request
                                callback:^(FIRStartPasskeyEnrollmentResponse *_Nullable response,
                                           NSError *_Nullable error) {
                                  callbackInvoked = YES;
                                  RPCResponse = response;
                                  RPCError = error;
                                }];

  [_RPCIssuer respondWithJSON:@{
    @"credentialCreationOptions" : @{
      kTestRpKey : @{kTestIDKey : kTestRpID},
      kTestUserKey : @{kTestIDKey : kTestUserID},
    },
  }];
  [self errorValidationHelperWithCallbackInvoked:callbackInvoked
                                        rpcError:RPCError
                                     rpcResponse:RPCResponse];
}

- (void)errorValidationHelperWithCallbackInvoked:(BOOL)callbackInvoked
                                        rpcError:(NSError *)RPCError
                                     rpcResponse:(FIRStartPasskeyEnrollmentResponse *)RPCResponse {
  XCTAssert(callbackInvoked);
  XCTAssertNotNil(RPCError);
  XCTAssertEqualObjects(RPCError.domain, FIRAuthErrorDomain);
  XCTAssertEqual(RPCError.code, FIRAuthErrorCodeInternalError);
  XCTAssertNotNil(RPCError.userInfo[NSUnderlyingErrorKey]);
  NSError *underlyingError = RPCError.userInfo[NSUnderlyingErrorKey];
  XCTAssertNotNil(underlyingError);
  XCTAssertNotNil(underlyingError.userInfo[FIRAuthErrorUserInfoDeserializedResponseKey]);
  XCTAssertNil(RPCResponse);
}

@end
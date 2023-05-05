// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

public class SignUpNewUserResponse: AuthRPCResponse_NEW_ {
  /** @property IDToken
      @brief Either an authorization code suitable for performing an STS token exchange, or the
          access token from Secure Token Service, depending on whether @c returnSecureToken is set
          on the request.
   */
  public var idToken: String?

  /** @property approximateExpirationDate
      @brief The approximate expiration date of the access token.
   */
  public var approximateExpirationDate: Date?

  /** @property refreshToken
      @brief The refresh token from Secure Token Service.
   */
  public var refreshToken: String?

  public func setFields(dictionary: [String: AnyHashable]) throws {
    idToken = dictionary["idToken"] as? String
    if let approximateExpirationDate = dictionary["expiresIn"] as? String {
      self
        .approximateExpirationDate =
        Date(timeIntervalSinceNow: (approximateExpirationDate as NSString).doubleValue)
    }
    refreshToken = dictionary["refreshToken"] as? String
  }
}
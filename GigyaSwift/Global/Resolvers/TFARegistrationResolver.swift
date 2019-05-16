//
//  TFARegistrationResolver.swift
//  GigyaSwift
//
//  Created by Tal Mirmelshtein on 15/05/2019.
//  Copyright © 2019 Gigya. All rights reserved.
//

import Foundation

public protocol TFARegistrationResolverProtocol {
    
    var tfaProviders: [TFAProviderModel] { get set }
    
    func startRegistrationWithPhone(phoneNumber: String, method: String?)
    
    func startRegistrationWithTotp()
    
    func verifyCode(provider: TFAProvider, authenticationCode: String)
}

class TFARegistrationResolver<T: Codable> : TFAResolver<T>, TFARegistrationResolverProtocol {
    
    lazy var tfaProviders: [TFAProviderModel] = {
        return self.providers
    }()

    override init(originalError: NetworkError, regToken: String, businessDelegate: BusinessApiDelegate, completion: @escaping (GigyaLoginResult<T>) -> Void) {
        super.init(originalError: originalError, regToken: regToken, businessDelegate: businessDelegate, completion: completion)
    }
    
    override func forwardInitialInterruption() {
        let loginError = LoginApiError<T>(error: self.originalError, interruption: .pendingTwoFactorRegistration(resolver: self))
        self.completion(.failure(loginError))
    }
    
    public func startRegistrationWithPhone(phoneNumber: String, method: String? = "sms") {
        initTFA(tfaProvider: .gigyaPhone, mode: "register", arguments: ["phoneNumber" : phoneNumber, method: method] as! [String: Any])
    }
    
    func startRegistrationWithTotp() {
        initTFA(tfaProvider: .totp, mode: "register", arguments: [:])
    }
    
    public func verifyCode(provider: TFAProvider, authenticationCode: String) {
        var params = [String: String]()
        var api = ""
        switch provider {
        case .gigyaPhone:
            if let gigyaAssertion = self.gigyaAssertion, let phvToken = self.phvToken {
                params = ["gigyaAssertion": gigyaAssertion, "code": authenticationCode, "phvToken": phvToken]
                api = GigyaDefinitions.API.phoneCompleteVerificationTFA
                verifyAuthorizationCode(api: api, params: params)
            }
            break
        case .totp:
            verifyTotpAuthorizationCode(authorizationCode: authenticationCode)
        default:
            break
        }
        
    }
    
}

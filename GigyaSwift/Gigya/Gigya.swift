//
//  GigyaSwift.swift
//  GigyaSwift
//
//  Created by Shmuel, Sagi on 25/02/2019.
//  Copyright © 2019 Gigya. All rights reserved.
//

import Foundation
// TODO: Need to make unit test

public class Gigya {

    private static var storedInstance: GigyaInstanceProtocol?

    private static var container: IOCContainer?

    // Get container - internal sdk usage
    public static func getContainer() -> IOCContainer {
        if container == nil {
            container = IOCContainer()
            registerDependencies(with: container!)
        }

        return container!
    }

    // Get instance with default user
    @discardableResult
    public static func sharedInstance() -> GigyaCore<GigyaAccount> {
        return sharedInstance(GigyaAccount.self)
    }

    // Get instance with generic schema
    @discardableResult
    public static func sharedInstance<T: GigyaAccountProtocol>(_ dataType: T.Type) -> GigyaCore<T> {
        if storedInstance == nil {
            let container: IOCContainer = getContainer()

            let plistConfig = DecodeEncodeUtils.parsePlistConfig()
            let newInstance = GigyaCore<T>(container: container, plistConfig: plistConfig)
            storedInstance = newInstance
            return newInstance
        }

        guard let instance = storedInstance as? GigyaCore<T> else {
            GigyaLogger.error(with: self, message: "Gigya instance was originally created with a different GigyaAccountProtocol:", generic: storedInstance)
        }

        return instance
    }

    private static func registerDependencies(with container: IOCContainer) {
        container.register(service: GigyaConfig.self, isSingleton: true) { _ in GigyaConfig() }

        container.register(service: IOCNetworkAdapterProtocol.self) { resolver in
            let config = resolver.resolve(GigyaConfig.self)
            let sessionService = resolver.resolve(IOCSessionServiceProtocol.self)

            return NetworkAdapter(config: config!, sessionService: sessionService!)
        }

        container.register(service: IOCApiServiceProtocol.self) { resolver in
            let sessionService = resolver.resolve(IOCSessionServiceProtocol.self)

            return ApiService(with: resolver.resolve(IOCNetworkAdapterProtocol.self)!, session: sessionService!)
        }


        container.register(service: IOCSessionServiceProtocol.self, isSingleton: true) { resolver in
            let config = resolver.resolve(GigyaConfig.self)
            let accountService = resolver.resolve(IOCAccountServiceProtocol.self)

            return SessionService(config: config!, accountService: accountService!)
        }

        container.register(service: IOCBiometricServiceProtocol.self, isSingleton: true) { resolver in
            let config = resolver.resolve(GigyaConfig.self)
            let sessionService = resolver.resolve(IOCSessionServiceProtocol.self)

            return BiometricService(config: config!, sessionService: sessionService!)
        }

        container.register(service: BiometricServiceInternalProtocol.self, isSingleton: true) { resolver in
            let biometric = resolver.resolve(IOCBiometricServiceProtocol.self)

            return biometric as! BiometricServiceInternalProtocol
        }

        container.register(service: IOCSocialProvidersManagerProtocol.self, isSingleton: true) { resolver in
            let config = resolver.resolve(GigyaConfig.self)
            let sessionService = resolver.resolve(IOCSessionServiceProtocol.self)

            return SocialProvidersManager(sessionService: sessionService!, config: config!)
        }

        container.register(service: IOCBusinessApiServiceProtocol.self, isSingleton: true) { resolver in
            let config = resolver.resolve(GigyaConfig.self)
            let apiService = resolver.resolve(IOCApiServiceProtocol.self)
            let sessionService = resolver.resolve(IOCSessionServiceProtocol.self)
            let accountService = resolver.resolve(IOCAccountServiceProtocol.self)
            let providerFactory = resolver.resolve(IOCSocialProvidersManagerProtocol.self)
            let interruptionsHandler = resolver.resolve(IOCInterruptionResolverFactory.self)
            let biometricService = resolver.resolve(BiometricServiceInternalProtocol.self)

            return BusinessApiService(config: config!,
                                      apiService: apiService!,
                                      sessionService: sessionService!,
                                      accountService: accountService!,
                                      providerFactory: providerFactory!,
                                      interruptionsHandler: interruptionsHandler!,
                                      biometricService: biometricService!)
        }

        container.register(service: IOCAccountServiceProtocol.self, isSingleton: true) { _ in
            return AccountService()
        }

        container.register(service: IOCInterruptionResolverFactory.self) { _ in
            return InterruptionResolverFactory()
        }
    }

    #if DEBUG
    internal static func removeStoredInstance() {
        storedInstance = nil
    }
    #endif
}

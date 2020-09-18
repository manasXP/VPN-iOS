//
//  Credentials.swift
//  SimpleVpn
//
//  Created by Dmitry Gordin on 12/23/16.
//  Copyright © 2016 Dmitry Gordin. All rights reserved.
//

import Foundation

class Configuration {
    static let SERVER_KEY = "SERVER_KEY"
    static let ACCOUNT_KEY = "ACCOUNT_KEY"
    static let PASSWORD_KEY = "PASSWORD_KEY"
    static let ONDEMAND_KEY = "ONDEMAND_KEY"
    static let PSK_KEY = "PSK_KEY"
    
    static let KEYCHAIN_PASSWORD_KEY = "KEYCHAIN_PASSWORD_KEY"
    static let KEYCHAIN_PSK_KEY = "KEYCHAIN_PSK_KEY"
    
    static let FIRST_DNS_KEY = "FIRST_DNS_KEY"
    static let SECOND_DNS_KEY = "SECOND_DNS_KEY"
    
    public let server: String
    public let account: String
    public let password: String
    public let onDemand: Bool
    public let psk: String?
    public var pskEnabled: Bool {
        return psk != nil
    }
    public let firstDNSEndpoint: String?
    public let secondDNSEndpoint: String?
    public var isDNSEnabled: Bool {
        return firstDNSEndpoint != nil && secondDNSEndpoint != nil
    }
    
    init(server: String, account: String, password: String, onDemand: Bool = false, psk: String? = nil,
         firstDNSEndpoint: String? = nil, secondDNSEndpoint: String? = nil) {
        self.server = server
        self.account = account
        self.password = password
        self.onDemand = onDemand
        self.psk = psk
        self.firstDNSEndpoint = firstDNSEndpoint
        self.secondDNSEndpoint = secondDNSEndpoint
    }
    
    func getPasswordRef() -> Data? {
        KeychainWrapper.standard.set(password, forKey: Configuration.KEYCHAIN_PASSWORD_KEY)
        return KeychainWrapper.standard.dataRef(forKey: Configuration.KEYCHAIN_PASSWORD_KEY)
    }
    
    func getPSKRef() -> Data? {
        if psk == nil { return nil }
        
        KeychainWrapper.standard.set(psk!, forKey: Configuration.KEYCHAIN_PSK_KEY)
        return KeychainWrapper.standard.dataRef(forKey: Configuration.KEYCHAIN_PSK_KEY)
    }
    
    static func loadFromDefaults() -> Configuration {
        let def = UserDefaults.standard
        let server = def.string(forKey: Configuration.SERVER_KEY) ?? Constants.serverAddress
        let account = def.string(forKey: Configuration.ACCOUNT_KEY) ?? Constants.vpnUser
        let password = def.string(forKey: Configuration.PASSWORD_KEY) ?? Constants.vpnPassword
        let onDemand = def.bool(forKey: Configuration.ONDEMAND_KEY)
        let psk = def.string(forKey: Configuration.PSK_KEY)
        let firstDNS = def.string(forKey: Configuration.FIRST_DNS_KEY)
        let secondDNS = def.string(forKey: Configuration.SECOND_DNS_KEY)
        return Configuration(
            server: server,
            account: account,
            password: password,
            onDemand: onDemand,
            psk: psk,
            firstDNSEndpoint: firstDNS,
            secondDNSEndpoint: secondDNS
        )
    }
    
    func saveToDefaults() {
        let def = UserDefaults.standard
        def.set(server, forKey: Configuration.SERVER_KEY)
        def.set(account, forKey: Configuration.ACCOUNT_KEY)
        def.set(password, forKey: Configuration.PASSWORD_KEY)
        def.set(onDemand, forKey: Configuration.ONDEMAND_KEY)
        def.set(psk, forKey: Configuration.PSK_KEY)
        def.set(firstDNSEndpoint, forKey: Configuration.FIRST_DNS_KEY)
        def.set(secondDNSEndpoint, forKey: Configuration.SECOND_DNS_KEY)
    }
}

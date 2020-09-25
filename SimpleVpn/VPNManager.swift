import Foundation
import NetworkExtension

final class VPNManager: NSObject {
    private let passwordKey = "VPN_password"
    
    static let shared: VPNManager = {
        let instance = VPNManager()
        instance.manager.localizedDescription = Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
        instance.loadProfile(callback: nil)
        return instance
    }()

    let manager: NEVPNManager = { NEVPNManager.shared() }()
    public var isDisconnected: Bool {
        return (status == .disconnected)
            || (status == .reasserting)
            || (status == .invalid)
    }
    public var status: NEVPNStatus { get { return manager.connection.status } }
    public let statusEvent = Subject<NEVPNStatus>()
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(VPNManager.VPNStatusDidChange(_:)),
            name: NSNotification.Name.NEVPNStatusDidChange,
            object: nil)
    }
    
    public func disconnect(completionHandler: (()->Void)? = nil) {
        manager.onDemandRules = []
        manager.isOnDemandEnabled = false
        manager.saveToPreferences { _ in
            self.manager.connection.stopVPNTunnel()
            completionHandler?()
        }
    }
    
    @objc private func VPNStatusDidChange(_: NSNotification?){
        statusEvent.notify(status)
    }
    
    private func loadProfile(callback: ((Bool)->Void)?) {
        manager.protocolConfiguration = nil
        manager.loadFromPreferences { error in
            if let error = error {
                NSLog("Failed to load preferences: \(error.localizedDescription)")
                callback?(false)
            } else {
                callback?(self.manager.protocolConfiguration != nil)
            }
        }
    }
    
    private func saveProfile(callback: ((Bool)->Void)?) {
        manager.saveToPreferences { error in
            if let error = error {
                NSLog("Failed to save profile: \(error.localizedDescription)")
                callback?(false)
            } else {
                callback?(true)
            }
        }
    }
    
    public func connectIKEv2(onError: @escaping (String)->Void) {
        KeychainWrapper.standard.set(VPNConstants.vpnPassword, forKey: passwordKey)

        
        let p = NEVPNProtocolIKEv2()
        
        p.authenticationMethod = NEVPNIKEAuthenticationMethod.none
        p.serverAddress = VPNConstants.serverAddress
        p.disconnectOnSleep = false
        p.username = VPNConstants.vpnUser
        p.passwordReference = KeychainWrapper.standard.dataRef(forKey: passwordKey)
        p.deadPeerDetectionRate = .medium
        p.disableMOBIKE = false
        p.disableRedirect = false
        p.enableRevocationCheck = false
        p.useExtendedAuthentication = true
        p.useConfigurationAttributeInternalIPSubnet = false
        
        p.childSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
        p.childSecurityAssociationParameters.integrityAlgorithm = .SHA384
        p.childSecurityAssociationParameters.diffieHellmanGroup = .group20
        p.childSecurityAssociationParameters.lifetimeMinutes = 1440
        
        p.ikeSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
        p.ikeSecurityAssociationParameters.integrityAlgorithm = .SHA384
        p.ikeSecurityAssociationParameters.diffieHellmanGroup = .group20
        p.ikeSecurityAssociationParameters.lifetimeMinutes = 1440
        
        // two lines bellow may depend of your server configuration
        p.remoteIdentifier = VPNConstants.serverAddress
        p.localIdentifier = VPNConstants.vpnUser
        loadProfile { _ in
            self.manager.protocolConfiguration = p
            self.manager.isEnabled = true
            self.saveProfile { success in
                if !success {
                    onError("Unable to save vpn profile")
                    return
                }
                self.loadProfile() { success in
                    if !success {
                        onError("Unable to load profile")
                        return
                    }
                    let result = self.startVPNTunnel()
                    if !result {
                        onError("Can't connect")
                    }
                }
            }
        }
    }
    private func startVPNTunnel() -> Bool {
        do {
            try self.manager.connection.startVPNTunnel()
            return true
        } catch NEVPNError.configurationInvalid {
            NSLog("Failed to start tunnel (configuration invalid)")
        } catch NEVPNError.configurationDisabled {
            NSLog("Failed to start tunnel (configuration disabled)")
        } catch {
            NSLog("Failed to start tunnel (other error)")
        }
        return false
    }
}

import NetworkExtension
import Dnscryptproxy

class DNSManager {
    
    var vpnStatusObserver: NSObjectProtocol?
    private lazy var vpnStatusObserverSet: Bool = {
        return false
    }()
    public var statusEvent = Subject<NEVPNStatus>()
    public var isDisconnected: Bool {
        return (status == .disconnected)
            || (status == .reasserting)
            || (status == .invalid)
    }
    
    private var status = NEVPNStatus.disconnected

    static func queryLogPath() -> String? {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
        let path = url.appendingPathComponent("dnscrypt/logs/query.log").path
        if FileManager.default.fileExists(atPath: path) {
            return path
        }
        return nil
    }
    
    static func clearQueryLog() {
        guard let path = queryLogPath() else {
            return
        }
        try? FileManager.default.removeItem(atPath: path)
    }
    
    func startExt(completion: @escaping (Result<AnyObject?, Error>) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences() { managers, error in
            if let managers = managers, managers.count > 0 {
                let manager = managers[0]
                let start = {
                    do {
                        self.startStatusMonitors()
                        if manager.connection.status == .connected {
                        } else {
                            try manager.connection.startVPNTunnel()
                            completion(.success(nil))
                        }
                    } catch let error {
                        print("Error: Could not start manager: \(error)")
                        completion(.failure(error))
                        return
                    }
                }
                
                if manager.isEnabled {
                    start()
                } else {
                    manager.isEnabled = true
                    manager.saveToPreferences() { error in
                        if let error = error {
                            print("Error: Could not enable manager: \(error)")
                            completion(.failure(error))
                            return
                        }
                        start()
                    }
                }
            }
        }
    }
    
    func stopExt() {
        NETunnelProviderManager.loadAllFromPreferences() { managers, error in
            if let managers = managers, managers.count > 0 {
                let manager = managers[0]
                if manager.connection.status != .disconnected {
                    manager.connection.stopVPNTunnel()
                }
            }
        }
    }
    
    func getStatus(completion: @escaping (Result<NEVPNStatus, Error>) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences() { [weak self] managers, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let managers = managers, managers.count > 0 {
                let manager = managers[0]
                self?.status = manager.connection.status
                completion(.success(manager.connection.status))
            } else {
                completion(.success(.disconnected))
            }
        }
    }
    
    func requestPermission(completion: @escaping (Result<AnyObject?, Error>) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences() { managers, error in
            if let managers = managers, managers.count > 0 {
                completion(.success(nil))
            } else {
                let config = NETunnelProviderProtocol()
                config.providerConfiguration = ["l": 1]
                config.serverAddress = "SimpleVpn"
                config.disconnectOnSleep = false
                
                let manager = NETunnelProviderManager()
                manager.protocolConfiguration = config
                manager.isEnabled = true
                
                let connectRule = NEOnDemandRuleConnect()
                manager.onDemandRules = [connectRule]
                manager.saveToPreferences() { error in
                    if let error = error as? NEVPNError, error.code == .configurationReadWriteFailed {
                        print(error)
                        completion(.failure(error))
                    } else {
                        completion(.success(nil))
                    }
                }
            }
        }
    }
    
    func doWithAppVPNManager(completionHandler: @escaping (NETunnelProviderManager) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences() { managers, error in
            if let managers = managers, managers.count > 0 {
                completionHandler(managers[0])
            }
        }
    }
    
    func startStatusMonitors() {
        guard self.vpnStatusObserver == nil else { return }
        guard !self.vpnStatusObserverSet else { return }
        
        doWithAppVPNManager() { (manager) in
            self.vpnStatusObserverSet = true
            self.vpnStatusObserver = NotificationCenter.default.addObserver(forName: Notification.Name.NEVPNStatusDidChange, object: manager.connection, queue: OperationQueue.main) { [weak self] note in
                guard let session = note.object as? NETunnelProviderSession else {
                    return
                }
                self?.status = session.status
                self?.statusEvent.notify(session.status)
            }
        }
    }
}

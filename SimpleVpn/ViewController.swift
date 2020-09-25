import UIKit
import NetworkExtension

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var vpnSwitch: UISwitch!
    @IBOutlet weak var dohSwitch: UISwitch!
    @IBOutlet weak var statusLabel: UILabel!

    private let dnsManager = DNSManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        vpnStateChanged(status: VPNManager.shared.status)
        VPNManager.shared.statusEvent.attach(self, ViewController.vpnStateChanged)
        
        dnsManager.statusEvent.attach(self, ViewController.dohStateChanged)
        dnsManager.startStatusMonitors()
        dnsManager.getStatus { [weak self] result in
            switch result {
            case .failure(_):
                self?.dohSwitch.isOn = false
            case .success(let status):
                self?.dohStateChanged(status: status)
            }
        }
    }
    
    func vpnStateChanged(status: NEVPNStatus) {
        let isDisconnected = VPNManager.shared.isDisconnected
        dohSwitch.isEnabled = isDisconnected
        var statusText = ""
        switch status {
        case .disconnected, .invalid, .reasserting:
            statusText = "Disconnected from VPN"
            vpnSwitch.isOn = false
            vpnSwitch.isEnabled = true
        case .connected:
            statusText = "Connected to VPN"
            vpnSwitch.isOn = true
            vpnSwitch.isEnabled = true
        case .connecting:
            statusText = "Connecting to VPN..."
            vpnSwitch.isOn = true
            vpnSwitch.isEnabled = false
        case .disconnecting:
            statusText = "Disconnecting from VPN..."
            vpnSwitch.isOn = false
            vpnSwitch.isEnabled = false
        @unknown default:
            statusText = "Unknown status"
        }
        statusLabel.text = statusText
    }
    
    func dohStateChanged(status: NEVPNStatus) {
        var statusText = ""
        switch status {
        case .disconnected, .invalid, .reasserting:
            statusText = "Disconnected from DoH"
            dohSwitch.isOn = false
            dohSwitch.isEnabled = true
            vpnSwitch.isEnabled = true
        case .connected:
            statusText = "Connected to DoH"
            dohSwitch.isOn = true
            dohSwitch.isEnabled = true
            vpnSwitch.isEnabled = false
        case .connecting:
            statusText = "Connecting to DoH..."
            dohSwitch.isOn = true
            dohSwitch.isEnabled = false
            vpnSwitch.isEnabled = false
        case .disconnecting:
            statusText = "Disconnecting from DoH..."
            dohSwitch.isOn = false
            dohSwitch.isEnabled = false
            vpnSwitch.isEnabled = false
        @unknown default:
            statusText = "Unknown status"
        }
        statusLabel.text = statusText
    }
    
    @IBAction func vpnSwitchChanged(_ sender: UISwitch) {
        dohSwitch.isEnabled = false
        vpnSwitch.isEnabled = false
        connectVPN()
    }
    
    @IBAction func dohSwitchChanged(_ sender: UISwitch) {
        dohSwitch.isEnabled = false
        vpnSwitch.isEnabled = false
        connectDoH()
    }
    
    private func connectDoH() {
        if dnsManager.isDisconnected {
            dnsManager.requestPermission { [weak self] result in
                switch result {
                case .success(_):
                    self?.dnsManager.startExt(completion: { [weak self] result in
                        switch result {
                        case .success(_): break
                        case .failure(let error):
                            self?.showErrorAlert(with: error.localizedDescription)
                        }
                    })
                case .failure(let error):
                    self?.showErrorAlert(with: error.localizedDescription)
                }
            }
        } else {
            dnsManager.stopExt()
        }
    }
    
    private func connectVPN() {
        if VPNManager.shared.isDisconnected {
            VPNManager.shared.connectIKEv2 { [weak self] error in
                self?.showErrorAlert(with: error)
            }
        } else {
            VPNManager.shared.disconnect()
        }
    }
    
    private func showErrorAlert(with errorDescription: String) {
        let alert = UIAlertController(title: "Error", message: errorDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}

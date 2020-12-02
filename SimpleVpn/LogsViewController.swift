//
//  LogsViewController.swift
//  SimpleVpn
//
//  Created by Manas Pradhan on 26.09.2020.
//  Copyright © 2020 VPN. All rights reserved.
//

import UIKit


extension UIScrollView {
    func scrollsToBottom(animated: Bool) {
        let bottomOffset = CGPoint(x: 0, y: contentSize.height - bounds.size.height)
        setContentOffset(bottomOffset, animated: animated)
    }
}

final class LogsViewController: UIViewController {
    
    @IBOutlet private var textView: UITextView!
    private var updateTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = "No logs..."
        updateLogs()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5,
                                           repeats: true,
                                           block: { [weak self] _ in
                                            self?.updateLogs()
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateTimer?.invalidate()
    }
    
    private func updateLogs() {
        guard let applogsPath = DNSManager.appLogPath(),
              let alog = try? String(contentsOfFile: applogsPath) else {
            return
        }
        guard let querylogsPath = DNSManager.queryLogPath(),
              let qlog = try? String(contentsOfFile: querylogsPath) else {
            return
        }
        
        // Show app log appended with query log
        textView.text = alog+"\n\n\n\n"+qlog
    }

}

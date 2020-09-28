//
//  LogsViewController.swift
//  SimpleVpn
//
//  Created by Maxim MAMEDOV on 26.09.2020.
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
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2,
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
        guard let logsPath = DNSManager.queryLogPath(),
              let log = try? String(contentsOfFile: logsPath) else {
            return
        }
        textView.text = log
    }

}


import UIKit
import Foundation
import WebKit

class BHWebViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!

    private let progressView = UIProgressView(progressViewStyle: .default)
    private var estimatedProgressObserver: NSKeyValueObservation?

    var infoLink: BHInfoLink?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = infoLink?.title ?? "Info"
        navigationItem.largeTitleDisplayMode = .never

        setupProgressView()
        setupEstimatedProgressObserver()

        if let validUrlString = infoLink?.url, let validUrl = URL(string: validUrlString) {
            setupWebview(url: validUrl)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideProgressView()
    }

    // MARK: - Private
    
    private func setupProgressView() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        progressView.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(progressView)

        progressView.isHidden = true
        progressView.tintColor = .accent()

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),

            progressView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4.0)
        ])
    }
    
    private func hideProgressView() {
        progressView.removeFromSuperview()
    }

    private func setupEstimatedProgressObserver() {
        estimatedProgressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            self?.progressView.progress = Float(webView.estimatedProgress)
        }
    }

    private func setupWebview(url: URL) {
        let request = URLRequest(url: url)

        webView.navigationDelegate = self
        webView.load(request)
    }
}

// MARK: - WKNavigationDelegate

extension BHWebViewController: WKNavigationDelegate {

    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {

        if progressView.isHidden {
            progressView.isHidden = false
        }

        UIView.animate(withDuration: 0.33,
                       animations: {
                           self.progressView.alpha = 1.0
        })
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        UIView.animate(withDuration: 0.33,
                       animations: {
                           self.progressView.alpha = 0.0
                       },
                       completion: { isFinished in
                           self.progressView.isHidden = isFinished
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: "Web page loaded: \(self.webView.title ?? "Untitled")")
            }
        }
    }
}




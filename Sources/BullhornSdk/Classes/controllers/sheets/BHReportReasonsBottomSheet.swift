
import UIKit
import Foundation

class BHReportReasonsBottomSheet: BHBottomSheetController {
    
    var tableView: UITableView!
    
    var reasons: [String] = []
    var selectReasonClosure: ((String)->())?

    var heightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openReportReasons)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func loadView() {
        super.loadView()

        tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .cardBackground()
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .divider()
        stackView.addArrangedSubview(tableView)
        
        let maxTableViewHeight: CGFloat = CGFloat(reasons.count) * Constants.panelHeight
        heightConstraint = NSLayoutConstraint(item: tableView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: maxTableViewHeight)
        heightConstraint.isActive = true

        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHReportReasonsBottomSheet: UITableViewDataSource, UITableViewDelegate {
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reasons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
        let reason = reasons[indexPath.row]
        cell.textLabel?.text = reason
        cell.textLabel?.font = .settingsPrimaryText()
        cell.textLabel?.textColor = .primary()
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = reason
        cell.contentView.backgroundColor = .cardBackground()

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectReasonClosure?(reasons[indexPath.row])
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.panelHeight
    }
}



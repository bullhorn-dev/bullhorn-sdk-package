import Foundation
import UIKit

class BHBulletinTilePollView: BHBulletinTileBaseView {
    
    let tableView = UITableView()

    override init(with tile: BHBulletinTile) {
        super.init(with: tile)
                
        let bundle = Bundle(for: Self.self)
        let nib = UINib(nibName: "BHPollVariantCell", bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: BHPollVariantCell.reusableIndentifer)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
                
        addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.widthAnchor.constraint(equalToConstant: 240),
            tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260),
            tableView.centerXAnchor.constraint(equalTo: centerXAnchor),
            tableView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

// MARK: - UITableViewDelegate

extension BHBulletinTilePollView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }
}

// MARK: - UITableViewDataSource

extension BHBulletinTilePollView: UITableViewDataSource {
  
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tile.pollVariants?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let pollVariant = tile.pollVariants?[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BHPollVariantCell", for: indexPath) as! BHPollVariantCell

        cell.delegate = self
        cell.pollVariant = pollVariant
        cell.totalAnswers = tile.totalPollAnswersCount()
        cell.isWinner = tile.isPollVariantWinner(pollVariant)
        cell.isVoted = tile.isVoted()

        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let titleLabel = UILabel()
        titleLabel.text = tile.description
        titleLabel.textColor = .playerOnDisplayBackground()
        titleLabel.font = .fontWithName(.robotoMedium, size: 18)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        
        return titleLabel
    }
}

// MARK: - BHPollVariantCellDelegate

extension BHBulletinTilePollView: BHPollVariantCellDelegate {
    
    func pollVariantDidChange(_ cell: BHPollVariantCell, variant: BHBulletinPollVariant) {
        BHBulletinManager.shared.getBulletinTile(tile.id) { response in
            switch response {
            case .success(tile: let tile):
                DispatchQueue.main.async {
                    self.tile = tile
                    self.delegate?.tilePollView(self, didChangeTile: tile)
                    self.tableView.reloadData()
                }
            case .failure(error: let e):
                BHLog.w("Get tile failed \(e.localizedDescription)")
            }
        }
    }
}


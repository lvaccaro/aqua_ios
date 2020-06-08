import UIKit

class AddAssetCell: UITableViewCell {
    @IBOutlet weak var assetNameLabel: UILabel!
    @IBOutlet weak var tickerLabel: UILabel!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var assetIconImageView: UIImageView!

    func configure(with asset: Asset) {
        backgroundColor = .aquaBackgroundBlue
        assetNameLabel.text = asset.name ?? ""
        tickerLabel.text = asset.ticker ?? ""
        assetIconImageView.image = asset.icon ?? UIImage(named: "asset_unknown")
    }
}

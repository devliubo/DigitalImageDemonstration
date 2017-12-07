/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Popover view controller for choosing virtual objects to place in the AR scene.
*/

import UIKit

// MARK: - ObjectCell

class ObjectCell: UITableViewCell {
    
    static let reuseIdentifier = "ObjectCell"
    
    var objectTitleLabel: UILabel!
    var objectImageView: UIImageView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        objectTitleLabel = UILabel(frame: CGRect(x: 53, y: 10, width: 200, height: 30))
        objectImageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        
        contentView.addSubview(objectTitleLabel)
        contentView.addSubview(objectImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
        
    var object: VirtualObjectDefinition? {
        didSet {
            objectTitleLabel.text = object?.displayName
            objectImageView.image = object?.thumbImage
        }
    }
}

// MARK: - VirtualObjectSelectionViewControllerDelegate

protocol VirtualObjectSelectionViewControllerDelegate: class {
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didSelectObjectAt index: Int)
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didDeselectObjectAt index: Int)
}

class VirtualObjectSelectionViewController: UITableViewController {

    private var selectedVirtualObjectRows = IndexSet()
    weak var delegate: VirtualObjectSelectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .light))
        tableView.register(ObjectCell.self, forCellReuseIdentifier: ObjectCell.reuseIdentifier)
    }
    
    override func viewWillLayoutSubviews() {
        preferredContentSize = CGSize(width: 250, height: tableView.contentSize.height)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Check if the current row is already selected, then deselect it.
        if selectedVirtualObjectRows.contains(indexPath.row) {
            delegate?.virtualObjectSelectionViewController(self, didDeselectObjectAt: indexPath.row)
        } else {
            delegate?.virtualObjectSelectionViewController(self, didSelectObjectAt: indexPath.row)
        }
        self.dismiss(animated: true, completion: nil)
    }
        
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return VirtualObjectManager.availableObjects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ObjectCell.reuseIdentifier, for: indexPath) as? ObjectCell else {
            fatalError("Expected `ObjectCell` type for reuseIdentifier \(ObjectCell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        
        cell.object = VirtualObjectManager.availableObjects[indexPath.row]

        if selectedVirtualObjectRows.contains(indexPath.row) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.clear
    }

}

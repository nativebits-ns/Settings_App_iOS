//
//  SettingsListCell.swift
//  Settings
//
//  Created by Nachiket Shilwant on 28/08/26.
//


import UIKit

class SettingsListCell: UICollectionViewListCell {
    var item: SettingsItem? {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        var content = UIListContentConfiguration.valueCell().updated(for: state)
        
        if let item = item {
            content.text = item.title
            content.textProperties.font = .systemFont(ofSize: 16, weight: .regular)
            content.textProperties.color = .label
        }
        
        contentConfiguration = content
    }
}

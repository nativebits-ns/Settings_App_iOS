//
//  SettingsHeaderCell.swift
//  Settings
//
//  Created by Nachiket Shilwant on 28/08/26.
//

import UIKit

class SettingsHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "SettingsHeaderView"
    
    var onAddItemTapped: (() -> Void)?
    var onHeaderTapped: (() -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Item", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupGesture()
    }
    
    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
    }
    
    private func setupViews() {
        addSubview(titleLabel)
        addSubview(addButton)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            addButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            addButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
        ])
    }
    
    func configure(title: String, isExpanded: Bool, onAdd: @escaping () -> Void, onToggle: @escaping () -> Void) {
        titleLabel.text = title
        self.onAddItemTapped = onAdd
        self.onHeaderTapped = onToggle
    }
    
    @objc private func headerTapped(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self)
        if addButton.frame.contains(location) { return }
        onHeaderTapped?()
    }
    
    @objc private func addButtonTapped() {
        onAddItemTapped?()
    }
}

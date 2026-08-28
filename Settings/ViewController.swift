//
//  ViewController.swift
//  Settings
//
//  Created by Nachiket Shilwant on 28/08/26.
//

import UIKit

struct SettingsSection: Hashable {
    let id = UUID()
    let sectionTitle: String
    var items: [SettingsItem]
    var isExpanded: Bool = true
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SettingsSection, rhs: SettingsSection) -> Bool {
        lhs.id == rhs.id
    }
}

struct SettingsItem: Hashable {
    let id = UUID()
    let title: String
}

var settingsOptions: [SettingsSection] = [
    SettingsSection(sectionTitle: "Profile", items: [
        SettingsItem(title: "Apple Account")
    ]),
    SettingsSection(sectionTitle: "Wireless & Connectivity", items: [
        SettingsItem(title: "Airplane Mode"),
        SettingsItem(title: "Wi-Fi"),
        SettingsItem(title: "Bluetooth"),
        SettingsItem(title: "Cellular")
    ]),
    SettingsSection(sectionTitle: "Notifications & Sounds", items: [
        SettingsItem(title: "Notifications"),
        SettingsItem(title: "Sounds & Haptics"),
        SettingsItem(title: "Focus"),
        SettingsItem(title: "Screen Time")
    ]),
    SettingsSection(sectionTitle: "General & Privacy", items: [
        SettingsItem(title: "General"),
        SettingsItem(title: "Control Centre"),
        SettingsItem(title: "Display & Brightness"),
        SettingsItem(title: "Accessibility"),
        SettingsItem(title: "Privacy & Security")
    ])
]

class ViewController: UIViewController, UISearchBarDelegate, UICollectionViewDelegate {
    
    var currentSettingsData: [SettingsSection] = settingsOptions
    var dataSource: UICollectionViewDiffableDataSource<SettingsSection, SettingsItem>!
    
    let searchBox: UISearchBar = {
        let search = UISearchBar()
        search.placeholder = "Search settings..."
        search.translatesAutoresizingMaskIntoConstraints = false
        search.backgroundImage = UIImage()
        return search
    }()
    
    let addSectionButton: UIButton = {
        let addButton = UIButton(type: .system)
        addButton.setTitle("Add Section", for: .normal)
        addButton.setTitleColor(.black, for: .normal)
        addButton.backgroundColor = .systemGray5
        addButton.layer.cornerRadius = 8
        addButton.translatesAutoresizingMaskIntoConstraints = false
        return addButton
    }()
    
    let settingsView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    let refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.tintColor = .systemGray
        refresh.attributedTitle = NSAttributedString(string: "Updating Settings...")
        return refresh
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        addLayoutToCollectionView()
        addSectionButton.addTarget(self, action: #selector(addSection), for: .touchUpInside)
        
        view.addSubview(searchBox)
        view.addSubview(addSectionButton)
        view.addSubview(settingsView)
        
        searchBox.delegate = self
        settingsView.delegate = self
        
        NSLayoutConstraint.activate([
            searchBox.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            searchBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            addSectionButton.leadingAnchor.constraint(equalTo: searchBox.trailingAnchor, constant: 8),
            addSectionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addSectionButton.centerYAnchor.constraint(equalTo: searchBox.centerYAnchor),
            addSectionButton.widthAnchor.constraint(equalToConstant: 95),
            addSectionButton.heightAnchor.constraint(equalToConstant: 36),
            
            settingsView.topAnchor.constraint(equalTo: searchBox.bottomAnchor, constant: 10),
            settingsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        configData()
    }
    
    func addLayoutToCollectionView() {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        
        config.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let self = self else {
                return UISwipeActionsConfiguration(actions: [])
            }
            
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
                self.deleteItem(at: indexPath)
                completion(true)
            }
            deleteAction.image = UIImage(systemName: "trash")
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
        
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        settingsView.collectionViewLayout = layout
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        settingsView.refreshControl = refreshControl
    }
    
    func configData(){
        let cellRegistration = UICollectionView.CellRegistration<SettingsListCell, SettingsItem> { cell, indexPath, item in
            cell.item = item
        }
        
        dataSource = UICollectionViewDiffableDataSource<SettingsSection, SettingsItem>(collectionView: settingsView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<SettingsHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] headerView, elementKind, indexPath in
            guard let self = self,
                  let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { return }
            
            headerView.configure(
                title: section.sectionTitle,
                isExpanded: section.isExpanded,
                onAdd: { [weak self] in
                    self?.addItemToSection(section)
                },
                onToggle: { [weak self] in
                    self?.toggleSection(section)
                }
            )
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        
        applySnapshot(animatingDifferences: false)
    }
    
    private func toggleSection(_ section: SettingsSection) {
        guard let sectionIndex = currentSettingsData.firstIndex(where: { $0.id == section.id }) else { return }
        currentSettingsData[sectionIndex].isExpanded.toggle()
        applySnapshot(animatingDifferences: true)
    }
    
    func deleteItem(at indexPath: IndexPath) {
        var snapshot = dataSource.snapshot()
        guard let itemToDelete = dataSource.itemIdentifier(for: indexPath) else { return }
        
        if let targetSection = dataSource.sectionIdentifier(for: indexPath.section) {
            if let sectionIndex = currentSettingsData.firstIndex(where: { $0.id == targetSection.id }) {
                currentSettingsData[sectionIndex].items.removeAll { $0.id == itemToDelete.id }
            }
        }
        
        snapshot.deleteItems([itemToDelete])
        
        if let section = dataSource.sectionIdentifier(for: indexPath.section),
           snapshot.numberOfItems(inSection: section) == 0 {
            snapshot.deleteSections([section])
            if let index = currentSettingsData.firstIndex(where: { $0.id == section.id }) {
                currentSettingsData.remove(at: index)
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<SettingsSection, SettingsItem>()
        
        for section in currentSettingsData {
            snapshot.appendSections([section])
            if section.isExpanded {
                snapshot.appendItems(section.items, toSection: section)
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            currentSettingsData = settingsOptions
        } else {
            currentSettingsData = settingsOptions.map { section in
                let filteredItems = section.items.filter { item in
                    item.title.localizedCaseInsensitiveContains(searchText)
                }
                var modifiedSection = SettingsSection(sectionTitle: section.sectionTitle, items: filteredItems)
                modifiedSection.isExpanded = true
                return modifiedSection
            }
        }
        
        applySnapshot(animatingDifferences: true)
    }
    
    @objc private func handleRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            self.currentSettingsData = settingsOptions
            self.searchBox.text = ""
            self.applySnapshot(animatingDifferences: true)
            self.refreshControl.endRefreshing()
        }
    }
    
    @objc private func addSection() {
        let alert = UIAlertController(title: "New Section", message: "Enter section name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Section Name"
            textField.autocapitalizationType = .words
        }
        
        let confirmAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alert.textFields?.first,
                  let sectionName = textField.text,
                  !sectionName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            
            let newSection = SettingsSection(sectionTitle: sectionName, items: [], isExpanded: true)
            
            self.currentSettingsData.append(newSection)
            self.applySnapshot()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        DispatchQueue.main.async { [weak self] in
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
    private func addItemToSection(_ section: SettingsSection) {
        guard let sectionIndex = currentSettingsData.firstIndex(where: { $0.id == section.id }) else { return }
        let targetSection = currentSettingsData[sectionIndex]
        
        let alert = UIAlertController(
            title: "Add Item",
            message: "Enter item title for \(targetSection.sectionTitle)",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Item Title"
            textField.autocapitalizationType = .words
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alert.textFields?.first,
                  let itemTitle = textField.text,
                  !itemTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            
            let newItem = SettingsItem(title: itemTitle)
            self.currentSettingsData[sectionIndex].items.append(newItem)
            self.currentSettingsData[sectionIndex].isExpanded = true
            self.applySnapshot(animatingDifferences: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

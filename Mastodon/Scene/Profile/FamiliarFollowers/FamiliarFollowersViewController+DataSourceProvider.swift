//
//  FamiliarFollowersViewController+DataSourceProvider.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-17.
//

import UIKit
import MastodonSDK

extension FamiliarFollowersViewController: DataSourceProvider {
    func item(from source: DataSourceItem.Source) async -> DataSourceItem? {
        var _indexPath = source.indexPath
        if _indexPath == nil, let cell = source.tableViewCell {
            _indexPath = await self.indexPath(for: cell)
        }
        guard let indexPath = _indexPath else { return nil }
        
        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        switch item {
        case .user(let record):
            return .user(record: record)
        default:
            return nil
        }
    }
    
    func update(status: MastodonStatus) {
        assertionFailure("Implement not required in this class")
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}

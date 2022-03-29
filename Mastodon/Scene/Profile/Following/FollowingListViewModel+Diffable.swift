//
//  FollowingListViewModel+Diffable.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-2.
//

import UIKit
import MastodonAsset
import MastodonLocalization

extension FollowingListViewModel {
    func setupDiffableDataSource(
        tableView: UITableView,
        userTableViewCellDelegate: UserTableViewCellDelegate?
    ) {
        diffableDataSource = UserSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: UserSection.Configuration(
                userTableViewCellDelegate: userTableViewCellDelegate
            )
        )
        
        // workaround to append loader wrong animation issue
        // set empty section to make update animation top-to-bottom style
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems([.bottomLoader], toSection: .main)
        if #available(iOS 15.0, *) {
            diffableDataSource?.applySnapshotUsingReloadData(snapshot, completion: nil)
        } else {
            // Fallback on earlier versions
            diffableDataSource?.apply(snapshot, animatingDifferences: false)
        }
        
        userFetchedResultsController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
                snapshot.appendSections([.main])
                let items = records.map { UserItem.user(record: $0) }
                snapshot.appendItems(items, toSection: .main)
                
                if let currentState = self.stateMachine.currentState {
                    switch currentState {
                    case is State.Idle, is State.Loading, is State.Fail:
                        snapshot.appendItems([.bottomLoader], toSection: .main)
                    case is State.NoMore:
                        guard let activeMastodonAuthenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value,
                              let userID = self.userID.value,
                              userID != activeMastodonAuthenticationBox.userID
                        else { break }
                        let text = L10n.Scene.Following.footer
                        snapshot.appendItems([.bottomHeader(text: text)], toSection: .main)
                    default:
                        break
                    }
                }
                
                diffableDataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &disposeBag)
    }
}

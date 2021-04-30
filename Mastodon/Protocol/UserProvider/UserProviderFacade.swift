//
//  UserProviderFacade.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

enum UserProviderFacade { }

extension UserProviderFacade {
    
    static func toggleUserFollowRelationship(
        provider: UserProvider
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        // prepare authentication
        guard let activeMastodonAuthenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else {
            assertionFailure()
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }

        return _toggleUserFollowRelationship(
            context: provider.context,
            activeMastodonAuthenticationBox: activeMastodonAuthenticationBox,
            mastodonUser: provider.mastodonUser().eraseToAnyPublisher()
        )
    }
    
    private static func _toggleUserFollowRelationship(
        context: AppContext,
        activeMastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox,
        mastodonUser: AnyPublisher<MastodonUser?, Never>
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        mastodonUser
            .compactMap { mastodonUser -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>? in
                guard let mastodonUser = mastodonUser else {
                    return nil
                }
                
                return context.apiService.toggleFollow(
                    for: mastodonUser,
                    activeMastodonAuthenticationBox: activeMastodonAuthenticationBox,
                    needFeedback: true
                )
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
}

extension UserProviderFacade {
    
    static func toggleUserBlockRelationship(
        provider: UserProvider,
        cell: UITableViewCell?,
        indexPath: IndexPath?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        // prepare authentication
        guard let activeMastodonAuthenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else {
            assertionFailure()
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }
        if let cell = cell, let indexPath = indexPath {
            return _toggleUserBlockRelationship(
                context: provider.context,
                activeMastodonAuthenticationBox: activeMastodonAuthenticationBox,
                mastodonUser: provider.mastodonUser(for: cell, indexPath: indexPath).eraseToAnyPublisher()
            )
        } else {
            return _toggleUserBlockRelationship(
                context: provider.context,
                activeMastodonAuthenticationBox: activeMastodonAuthenticationBox,
                mastodonUser: provider.mastodonUser().eraseToAnyPublisher()
            )
        }
    }
    
    private static func _toggleUserBlockRelationship(
        context: AppContext,
        activeMastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox,
        mastodonUser: AnyPublisher<MastodonUser?, Never>
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        mastodonUser
            .compactMap { mastodonUser -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>? in
                guard let mastodonUser = mastodonUser else {
                    return nil
                }
                
                return context.apiService.toggleBlock(
                    for: mastodonUser,
                    activeMastodonAuthenticationBox: activeMastodonAuthenticationBox
                )
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
}

extension UserProviderFacade {
    
    static func toggleUserMuteRelationship(
        provider: UserProvider,
        cell: UITableViewCell?,
        indexPath: IndexPath?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        // prepare authentication
        guard let activeMastodonAuthenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else {
            assertionFailure()
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }
        if let cell = cell, let indexPath = indexPath {
            return _toggleUserMuteRelationship(
                context: provider.context,
                activeMastodonAuthenticationBox: activeMastodonAuthenticationBox,
                mastodonUser: provider.mastodonUser(for: cell, indexPath: indexPath).eraseToAnyPublisher()
            )
        } else {
            return _toggleUserMuteRelationship(
                context: provider.context,
                activeMastodonAuthenticationBox: activeMastodonAuthenticationBox,
                mastodonUser: provider.mastodonUser().eraseToAnyPublisher()
            )
        }
    }
    
    private static func _toggleUserMuteRelationship(
        context: AppContext,
        activeMastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox,
        mastodonUser: AnyPublisher<MastodonUser?, Never>
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error> {
        mastodonUser
            .compactMap { mastodonUser -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>? in
                guard let mastodonUser = mastodonUser else {
                    return nil
                }
                
                return context.apiService.toggleMute(
                    for: mastodonUser,
                    activeMastodonAuthenticationBox: activeMastodonAuthenticationBox
                )
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
}

extension UserProviderFacade {
    
    static func createProfileActionMenu(
        for mastodonUser: MastodonUser,
        isMuting: Bool,
        isBlocking: Bool,
        canReport: Bool,
        isInSameDomain: Bool,
        isDomainBlocking: Bool,
        provider: UserProvider,
        cell: UITableViewCell?,
        indexPath: IndexPath?,
        sourceView: UIView?,
        barButtonItem: UIBarButtonItem?,
        shareUser: MastodonUser?,
        shareStatus: Status?
    ) -> UIMenu {
        var children: [UIMenuElement] = []
        let name = mastodonUser.displayNameWithFallback
        
        // mute
        let muteAction = UIAction(
            title: isMuting ? L10n.Common.Controls.Firendship.unmuteUser(name) : L10n.Common.Controls.Firendship.mute,
            image: isMuting ? UIImage(systemName: "speaker") : UIImage(systemName: "speaker.slash"),
            discoverabilityTitle: isMuting ? nil : L10n.Common.Controls.Firendship.muteUser(name),
            attributes: isMuting ? [] : .destructive,
            state: .off
        ) { [weak provider] _ in
            guard let provider = provider else { return }

            UserProviderFacade.toggleUserMuteRelationship(
                provider: provider,
                cell: cell,
                indexPath: indexPath
            )
            .sink { _ in
                // do nothing
            } receiveValue: { _ in
                // do nothing
            }
            .store(in: &provider.context.disposeBag)
        }
        if isMuting {
            children.append(muteAction)
        } else {
            let muteMenu = UIMenu(title: L10n.Common.Controls.Firendship.muteUser(name), image: UIImage(systemName: "speaker.slash"), options: [], children: [muteAction])
            children.append(muteMenu)
        }
        
        // block
        let blockAction = UIAction(
            title: isBlocking ? L10n.Common.Controls.Firendship.unblockUser(name) : L10n.Common.Controls.Firendship.block,
            image: isBlocking ? UIImage(systemName: "hand.raised.slash") : UIImage(systemName: "hand.raised"),
            discoverabilityTitle: isBlocking ? nil : L10n.Common.Controls.Firendship.blockUser(name),
            attributes: isBlocking ? [] : .destructive,
            state: .off
        ) { [weak provider] _ in
            guard let provider = provider else { return }

            UserProviderFacade.toggleUserBlockRelationship(
                provider: provider,
                cell: cell,
                indexPath: indexPath
            )
            .sink { _ in
                // do nothing
            } receiveValue: { _ in
                // do nothing
            }
            .store(in: &provider.context.disposeBag)
        }
        if isBlocking {
            children.append(blockAction)
        } else {
            let blockMenu = UIMenu(title: L10n.Common.Controls.Firendship.blockUser(name), image: UIImage(systemName: "hand.raised"), options: [], children: [blockAction])
            children.append(blockMenu)
        }
        if canReport {
            let reportAction = UIAction(title: L10n.Common.Controls.Actions.reportUser(name), image: UIImage(systemName: "flag"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak provider] _ in
                guard let provider = provider else { return }
                guard let authenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else {
                    return
                }
                let viewModel = ReportViewModel(
                    context: provider.context,
                    domain: authenticationBox.domain,
                    user: mastodonUser,
                    status: nil)
                provider.coordinator.present(
                    scene: .report(viewModel: viewModel),
                    from: provider,
                    transition: .modal(animated: true, completion: nil)
                )
            }
            children.append(reportAction)
        }
        
        if !isInSameDomain {
            if isDomainBlocking {
                let unblockDomainAction = UIAction(title: L10n.Common.Controls.Actions.unblockDomain(mastodonUser.domainFromAcct), image: UIImage(systemName: "nosign"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak provider] _ in
                    guard let provider = provider else { return }
                    BlockDomainService(userProvider: provider,
                                       cell: cell,
                                       indexPath: indexPath
                    )
                        .unblockDomain()
                }
                children.append(unblockDomainAction)
            } else {
                let blockDomainAction = UIAction(title: L10n.Common.Controls.Actions.blockDomain(mastodonUser.domainFromAcct), image: UIImage(systemName: "nosign"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak provider] _ in
                    guard let provider = provider else { return }
                    let alertController = UIAlertController(title: "", message: L10n.Common.Alerts.BlockDomain.message(mastodonUser.domainFromAcct), preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .default) { _ in

                    }
                    alertController.addAction(cancelAction)
                    let blockDomainAction = UIAlertAction(title: L10n.Common.Alerts.BlockDomain.blockEntireDomain, style: .destructive) { _ in
                        BlockDomainService(userProvider: provider,
                                           cell: cell,
                                           indexPath: indexPath
                        )
                            .blockDomain()
                    }
                    alertController.addAction(blockDomainAction)
                    provider.present(alertController, animated: true, completion: nil)
                }
                children.append(blockDomainAction)
            }
        }
        
        if let shareUser = shareUser {
            let shareAction = UIAction(title: L10n.Common.Controls.Actions.shareUser(name), image: UIImage(systemName: "square.and.arrow.up"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak provider] _ in
                guard let provider = provider else { return }
                let activityViewController = createActivityViewControllerForMastodonUser(mastodonUser: shareUser, dependency: provider)
                provider.coordinator.present(
                    scene: .activityViewController(
                        activityViewController: activityViewController,
                        sourceView: sourceView,
                        barButtonItem: barButtonItem
                    ),
                    from: provider,
                    transition: .activityViewControllerPresent(animated: true, completion: nil)
                )
            }
            children.append(shareAction)
        }
        
        if let shareStatus = shareStatus {
            let shareAction = UIAction(title: L10n.Common.Controls.Actions.sharePost, image: UIImage(systemName: "square.and.arrow.up"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak provider] _ in
                guard let provider = provider else { return }
                let activityViewController = createActivityViewControllerForMastodonUser(status: shareStatus, dependency: provider)
                provider.coordinator.present(
                    scene: .activityViewController(
                        activityViewController: activityViewController,
                        sourceView: sourceView,
                        barButtonItem: barButtonItem
                    ),
                    from: provider,
                    transition: .activityViewControllerPresent(animated: true, completion: nil)
                )
            }
            children.append(shareAction)
        }
        
        return UIMenu(title: "", options: [], children: children)
    }
    
    static func createActivityViewControllerForMastodonUser(mastodonUser: MastodonUser, dependency: NeedsDependency) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: mastodonUser.activityItems,
            applicationActivities: [SafariActivity(sceneCoordinator: dependency.coordinator)]
        )
        return activityViewController
    }
    
    static func createActivityViewControllerForMastodonUser(status: Status, dependency: NeedsDependency) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: status.activityItems,
            applicationActivities: [SafariActivity(sceneCoordinator: dependency.coordinator)]
        )
        return activityViewController
    }

}

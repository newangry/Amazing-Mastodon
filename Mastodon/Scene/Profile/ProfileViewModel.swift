//
//  ProfileViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import MastodonSDK

// please override this base class
class ProfileViewModel: NSObject {
    
    typealias UserID = String
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    private var mastodonUserObserver: AnyCancellable?
    private var currentMastodonUserObserver: AnyCancellable?
    
    // input
    let context: AppContext
    let mastodonUser: CurrentValueSubject<MastodonUser?, Never>
    let currentMastodonUser = CurrentValueSubject<MastodonUser?, Never>(nil)
    let viewDidAppear = PassthroughSubject<Void, Never>()
        
    // output
    let domain: CurrentValueSubject<String?, Never>
    let userID: CurrentValueSubject<UserID?, Never>
    let bannerImageURL: CurrentValueSubject<URL?, Never>
    let avatarImageURL: CurrentValueSubject<URL?, Never>
    let name: CurrentValueSubject<String?, Never>
    let username: CurrentValueSubject<String?, Never>
    let bioDescription: CurrentValueSubject<String?, Never>
    let url: CurrentValueSubject<String?, Never>
    let statusesCount: CurrentValueSubject<Int?, Never>
    let followingCount: CurrentValueSubject<Int?, Never>
    let followersCount: CurrentValueSubject<Int?, Never>

    let protected: CurrentValueSubject<Bool?, Never>
    // let suspended: CurrentValueSubject<Bool, Never>

    let relationshipActionOptionSet = CurrentValueSubject<RelationshipActionOptionSet, Never>(.none)
    let isEditing = CurrentValueSubject<Bool, Never>(false)
    let isFollowedBy = CurrentValueSubject<Bool, Never>(false)
    let isMuting = CurrentValueSubject<Bool, Never>(false)
    let isBlocking = CurrentValueSubject<Bool, Never>(false)
    let isBlockedBy = CurrentValueSubject<Bool, Never>(false)
    
    let isRelationshipActionButtonHidden = CurrentValueSubject<Bool, Never>(true)
    let isReplyBarButtonItemHidden = CurrentValueSubject<Bool, Never>(true)
    let isMoreMenuBarButtonItemHidden = CurrentValueSubject<Bool, Never>(true)
    
    init(context: AppContext, optionalMastodonUser mastodonUser: MastodonUser?) {
        self.context = context
        self.mastodonUser = CurrentValueSubject(mastodonUser)
        self.domain = CurrentValueSubject(context.authenticationService.activeMastodonAuthenticationBox.value?.domain)
        self.userID = CurrentValueSubject(mastodonUser?.id)
        self.bannerImageURL = CurrentValueSubject(mastodonUser?.headerImageURL())
        self.avatarImageURL = CurrentValueSubject(mastodonUser?.avatarImageURL())
//        self.protected = CurrentValueSubject(twitterUser?.protected)
        self.name = CurrentValueSubject(mastodonUser?.displayNameWithFallback)
        self.username = CurrentValueSubject(mastodonUser?.acctWithDomain)
        self.bioDescription = CurrentValueSubject(mastodonUser?.note)
        self.url = CurrentValueSubject(mastodonUser?.url)
        self.statusesCount = CurrentValueSubject(mastodonUser.flatMap { Int(truncating: $0.statusesCount) })
        self.followingCount = CurrentValueSubject(mastodonUser.flatMap { Int(truncating: $0.followingCount) })
        self.followersCount = CurrentValueSubject(mastodonUser.flatMap { Int(truncating: $0.followersCount) })
        self.protected = CurrentValueSubject(mastodonUser?.locked)
        super.init()
        
        relationshipActionOptionSet
            .compactMap { $0.highPriorityAction(except: []) }
            .map { $0 == .none }
            .assign(to: \.value, on: isRelationshipActionButtonHidden)
            .store(in: &disposeBag)

        // bind active authentication
        context.authenticationService.activeMastodonAuthentication
            .sink { [weak self] activeMastodonAuthentication in
                guard let self = self else { return }
                guard let activeMastodonAuthentication = activeMastodonAuthentication else {
                    self.domain.value = nil
                    self.currentMastodonUser.value = nil
                    return
                }
                self.domain.value = activeMastodonAuthentication.domain
                self.currentMastodonUser.value = activeMastodonAuthentication.user
            }
            .store(in: &disposeBag)
        
        // query relationship
        let mastodonUserID = self.mastodonUser.map { $0?.id }
        let pendingRetryPublisher = CurrentValueSubject<TimeInterval, Never>(1)
            
        Publishers.CombineLatest3(
            mastodonUserID.removeDuplicates().eraseToAnyPublisher(),
            context.authenticationService.activeMastodonAuthenticationBox.eraseToAnyPublisher(),
            pendingRetryPublisher.eraseToAnyPublisher()
        )
        .compactMap { mastodonUserID, activeMastodonAuthenticationBox, _ -> (String, AuthenticationService.MastodonAuthenticationBox)? in
            guard let mastodonUserID = mastodonUserID, let activeMastodonAuthenticationBox = activeMastodonAuthenticationBox else { return nil }
            guard mastodonUserID != activeMastodonAuthenticationBox.userID else { return nil }
            return (mastodonUserID, activeMastodonAuthenticationBox)
        }
        .setFailureType(to: Error.self)     // allow failure
        .flatMap { mastodonUserID, activeMastodonAuthenticationBox -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Relationship]>, Error> in
            let domain = activeMastodonAuthenticationBox.domain
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] fetch for user %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUserID)

            return self.context.apiService.relationship(domain: domain, accountIDs: [mastodonUserID], authorizationBox: activeMastodonAuthenticationBox)
                //.retry(3)
                .eraseToAnyPublisher()
        }
        .sink { completion in
            switch completion {
            case .failure(let error):
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            case .finished:
                break
            }
        } receiveValue: { response in
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update success", ((#file as NSString).lastPathComponent), #line, #function)
            
            // there are seconds delay after request follow before requested -> following. Query again when needs
            guard let relationship = response.value.first else { return }
            if relationship.requested == true {
                let delay = pendingRetryPublisher.value
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let _ = self else { return }
                    pendingRetryPublisher.value = min(2 * delay, 60)
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] fetch again due to pending", ((#file as NSString).lastPathComponent), #line, #function)
                }
            }
        }
        .store(in: &disposeBag)

        setup()
    }
    
}

extension ProfileViewModel {
    private func setup() {
        Publishers.CombineLatest(
            mastodonUser.eraseToAnyPublisher(),
            currentMastodonUser.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] mastodonUser, currentMastodonUser in
            guard let self = self else { return }
            // Update view model attribute
            self.update(mastodonUser: mastodonUser)
            self.update(mastodonUser: mastodonUser, currentMastodonUser: currentMastodonUser)

            // Setup observer for user
            if let mastodonUser = mastodonUser {
                // setup observer
                self.mastodonUserObserver = ManagedObjectObserver.observe(object: mastodonUser)
                    .sink { completion in
                        switch completion {
                        case .failure(let error):
                            assertionFailure(error.localizedDescription)
                        case .finished:
                            assertionFailure()
                        }
                    } receiveValue: { [weak self] change in
                        guard let self = self else { return }
                        guard let changeType = change.changeType else { return }
                        switch changeType {
                        case .update:
                            self.update(mastodonUser: mastodonUser)
                            self.update(mastodonUser: mastodonUser, currentMastodonUser: currentMastodonUser)
                        case .delete:
                            // TODO:
                            break
                        }
                    }

            } else {
                self.mastodonUserObserver = nil
            }

            // Setup observer for user
            if let currentMastodonUser = currentMastodonUser {
                // setup observer
                self.currentMastodonUserObserver = ManagedObjectObserver.observe(object: currentMastodonUser)
                    .sink { completion in
                        switch completion {
                        case .failure(let error):
                            assertionFailure(error.localizedDescription)
                        case .finished:
                            assertionFailure()
                        }
                    } receiveValue: { [weak self] change in
                        guard let self = self else { return }
                        guard let changeType = change.changeType else { return }
                        switch changeType {
                        case .update:
                            self.update(mastodonUser: mastodonUser, currentMastodonUser: currentMastodonUser)
                        case .delete:
                            // TODO:
                            break
                        }
                    }
            } else {
                self.currentMastodonUserObserver = nil
            }
        }
        .store(in: &disposeBag)
    }
    
    private func update(mastodonUser: MastodonUser?) {
        self.userID.value = mastodonUser?.id
        self.bannerImageURL.value = mastodonUser?.headerImageURL()
        self.avatarImageURL.value = mastodonUser?.avatarImageURL()
        self.name.value = mastodonUser?.displayNameWithFallback
        self.username.value = mastodonUser?.acctWithDomain
        self.bioDescription.value = mastodonUser?.note
        self.url.value = mastodonUser?.url
        self.statusesCount.value = mastodonUser.flatMap { Int(truncating: $0.statusesCount) }
        self.followingCount.value = mastodonUser.flatMap { Int(truncating: $0.followingCount) }
        self.followersCount.value = mastodonUser.flatMap { Int(truncating: $0.followersCount) }
        self.protected.value = mastodonUser?.locked
    }
    
    private func update(mastodonUser: MastodonUser?, currentMastodonUser: MastodonUser?) {
        guard let mastodonUser = mastodonUser,
              let currentMastodonUser = currentMastodonUser else {
            // set relationship
            self.relationshipActionOptionSet.value = .none
            self.isFollowedBy.value = false
            self.isMuting.value = false
            self.isBlocking.value = false
            self.isBlockedBy.value = false
            
            // set bar button item state
            self.isReplyBarButtonItemHidden.value = true
            self.isMoreMenuBarButtonItemHidden.value = true
            return
        }
        
        if mastodonUser == currentMastodonUser {
            self.relationshipActionOptionSet.value = [.edit]
            // set bar button item state
            self.isReplyBarButtonItemHidden.value = true
            self.isMoreMenuBarButtonItemHidden.value = true
        } else {
            // set with follow action default
            var relationshipActionSet = RelationshipActionOptionSet([.follow])
            
            let isFollowing = mastodonUser.followingBy.flatMap { $0.contains(currentMastodonUser) } ?? false
            if isFollowing {
                relationshipActionSet.insert(.following)
            }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isFollowing: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isFollowing.description)
            
            let isPending = mastodonUser.followRequestedBy.flatMap { $0.contains(currentMastodonUser) } ?? false
            if isPending {
                relationshipActionSet.insert(.pending)
            }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isPending: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isPending.description)
            
            let isFollowedBy = currentMastodonUser.followingBy.flatMap { $0.contains(mastodonUser) } ?? false
            self.isFollowedBy.value = isFollowedBy
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isFollowedBy: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isFollowedBy.description)
            
            let isMuting = mastodonUser.mutingBy.flatMap { $0.contains(currentMastodonUser) } ?? false
            if isMuting {
                relationshipActionSet.insert(.muting)
            }
            self.isMuting.value = isMuting
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isMuting: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isMuting.description)
            
            let isBlocking = mastodonUser.blockingBy.flatMap { $0.contains(currentMastodonUser) } ?? false
            if isBlocking {
                relationshipActionSet.insert(.blocking)
            }
            self.isBlocking.value = isBlocking
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isBlocking: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isBlocking.description)
            
            let isBlockedBy = currentMastodonUser.blockingBy.flatMap { $0.contains(mastodonUser) } ?? false
            if isBlockedBy {
                relationshipActionSet.insert(.blocked)
            }
            self.isBlockedBy.value = isBlockedBy
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isBlockedBy: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isBlockedBy.description)
            
            self.relationshipActionOptionSet.value = relationshipActionSet
            
            // set bar button item state
            self.isReplyBarButtonItemHidden.value = isBlocking || isBlockedBy
            self.isMoreMenuBarButtonItemHidden.value = false
        }
    }

}

extension ProfileViewModel {
    
    enum RelationshipAction: Int, CaseIterable {
        case none       // set hide from UI
        case follow
        case pending
        case following
        case muting
        case blocking
        case blocked
        case edit
        case editing
        
        var option: RelationshipActionOptionSet {
            return RelationshipActionOptionSet(rawValue: 1 << rawValue)
        }
    }
    
    // construct option set on the enum for safe iterator
    struct RelationshipActionOptionSet: OptionSet {
        let rawValue: Int
        
        static let none = RelationshipAction.none.option
        static let follow = RelationshipAction.follow.option
        static let pending = RelationshipAction.pending.option
        static let following = RelationshipAction.following.option
        static let muting = RelationshipAction.muting.option
        static let blocking = RelationshipAction.blocking.option
        static let blocked = RelationshipAction.blocked.option
        static let edit = RelationshipAction.edit.option
        static let editing = RelationshipAction.editing.option
        
        static let editOptions: RelationshipActionOptionSet = [.edit, .editing]
        
        func highPriorityAction(except: RelationshipActionOptionSet) -> RelationshipAction? {
            let set = subtracting(except)
            for action in RelationshipAction.allCases.reversed() where set.contains(action.option) {
                return action
            }
            
            return nil
        }

        var title: String {
            guard let highPriorityAction = self.highPriorityAction(except: []) else {
                assertionFailure()
                return " "
            }
            switch highPriorityAction {
            case .none: return " "
            case .follow: return L10n.Common.Controls.Firendship.follow
            case .pending: return L10n.Common.Controls.Firendship.pending
            case .following: return L10n.Common.Controls.Firendship.following
            case .muting: return L10n.Common.Controls.Firendship.muted
            case .blocking: return L10n.Common.Controls.Firendship.blocked
            case .blocked: return L10n.Common.Controls.Firendship.follow   // blocked by user
            case .edit: return L10n.Common.Controls.Firendship.editInfo
            case .editing: return L10n.Common.Controls.Actions.done
            }
        }
        
        var backgroundColor: UIColor {
            guard let highPriorityAction = self.highPriorityAction(except: []) else {
                assertionFailure()
                return Asset.Colors.Button.normal.color
            }
            switch highPriorityAction {
            case .none: return Asset.Colors.Button.normal.color
            case .follow: return Asset.Colors.Button.normal.color
            case .pending: return Asset.Colors.Button.normal.color
            case .following: return Asset.Colors.Button.normal.color
            case .muting: return Asset.Colors.Background.alertYellow.color
            case .blocking: return Asset.Colors.Background.danger.color
            case .blocked: return Asset.Colors.Button.disabled.color
            case .edit: return Asset.Colors.Button.normal.color
            case .editing: return Asset.Colors.Button.normal.color
            }
        }

    }
}

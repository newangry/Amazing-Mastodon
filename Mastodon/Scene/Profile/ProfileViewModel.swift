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
import MastodonMeta
import MastodonAsset
import MastodonLocalization

// please override this base class
class ProfileViewModel: NSObject {
    
    let logger = Logger(subsystem: "ProfileViewModel", category: "ViewModel")
    
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
    let fields: CurrentValueSubject<[MastodonField], Never>
    let emojiMeta: CurrentValueSubject<MastodonContent.Emojis, Never>

    // fulfill this before editing
    let accountForEdit = CurrentValueSubject<Mastodon.Entity.Account?, Never>(nil)

    let protected: CurrentValueSubject<Bool?, Never>
    let suspended: CurrentValueSubject<Bool, Never>

    let isEditing = CurrentValueSubject<Bool, Never>(false)
    let isUpdating = CurrentValueSubject<Bool, Never>(false)
    
    let relationshipActionOptionSet = CurrentValueSubject<RelationshipActionOptionSet, Never>(.none)
    let isFollowedBy = CurrentValueSubject<Bool, Never>(false)
    let isMuting = CurrentValueSubject<Bool, Never>(false)
    let isBlocking = CurrentValueSubject<Bool, Never>(false)
    let isBlockedBy = CurrentValueSubject<Bool, Never>(false)
    
    let isRelationshipActionButtonHidden = CurrentValueSubject<Bool, Never>(true)
    let isReplyBarButtonItemHidden = CurrentValueSubject<Bool, Never>(true)
    let isMoreMenuBarButtonItemHidden = CurrentValueSubject<Bool, Never>(true)
    let isMeBarButtonItemsHidden = CurrentValueSubject<Bool, Never>(true)

    let needsPagePinToTop = CurrentValueSubject<Bool, Never>(false)
    let needsPagingEnabled = CurrentValueSubject<Bool, Never>(true)
    let needsImageOverlayBlurred = CurrentValueSubject<Bool, Never>(false)
    
    init(context: AppContext, optionalMastodonUser mastodonUser: MastodonUser?) {
        self.context = context
        self.mastodonUser = CurrentValueSubject(mastodonUser)
        self.domain = CurrentValueSubject(context.authenticationService.activeMastodonAuthenticationBox.value?.domain)
        self.userID = CurrentValueSubject(mastodonUser?.id)
        self.bannerImageURL = CurrentValueSubject(mastodonUser?.headerImageURL())
        self.avatarImageURL = CurrentValueSubject(mastodonUser?.avatarImageURL())
        self.name = CurrentValueSubject(mastodonUser?.displayNameWithFallback)
        self.username = CurrentValueSubject(mastodonUser?.acctWithDomain)
        self.bioDescription = CurrentValueSubject(mastodonUser?.note)
        self.url = CurrentValueSubject(mastodonUser?.url)
        self.statusesCount = CurrentValueSubject(mastodonUser.flatMap { Int($0.statusesCount) })
        self.followingCount = CurrentValueSubject(mastodonUser.flatMap { Int($0.followingCount) })
        self.followersCount = CurrentValueSubject(mastodonUser.flatMap { Int($0.followersCount) })
        self.protected = CurrentValueSubject(mastodonUser?.locked)
        self.suspended = CurrentValueSubject(mastodonUser?.suspended ?? false)
        self.fields = CurrentValueSubject(mastodonUser?.fields ?? [])
        self.emojiMeta = CurrentValueSubject(mastodonUser?.emojis.asDictionary ?? [:])
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
        let userRecord = self.mastodonUser.map { user -> ManagedObjectRecord<MastodonUser>? in
            user.flatMap { ManagedObjectRecord<MastodonUser>(objectID: $0.objectID) }
        }
        let pendingRetryPublisher = CurrentValueSubject<TimeInterval, Never>(1)
        
        // observe friendship
        Publishers.CombineLatest3(
            userRecord,
            context.authenticationService.activeMastodonAuthenticationBox,
            pendingRetryPublisher
        )
        .sink { [weak self] userRecord, authenticationBox, _ in
            guard let self = self else { return }
            guard let userRecord = userRecord,
                  let authenticationBox = authenticationBox
            else { return }
            Task {
                do {
                    let response = try await self.updateRelationship(
                        record: userRecord,
                        authenticationBox: authenticationBox
                    )
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
                } catch {
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Relationship] update user relationship failure: \(error.localizedDescription)")
                }
            }
        }
        .store(in: &disposeBag)
    
        let isBlockingOrBlocked = Publishers.CombineLatest(
            isBlocking,
            isBlockedBy
        )
        .map { $0 || $1 }
        .share()

        isBlockingOrBlocked
            .map { !$0 }
            .assign(to: \.value, on: needsPagingEnabled)
            .store(in: &disposeBag)

        isBlockingOrBlocked
            .map { $0 }
            .assign(to: \.value, on: needsImageOverlayBlurred)
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
        self.statusesCount.value = mastodonUser.flatMap { Int($0.statusesCount) }
        self.followingCount.value = mastodonUser.flatMap { Int($0.followingCount) }
        self.followersCount.value = mastodonUser.flatMap { Int($0.followersCount) }
        self.protected.value = mastodonUser?.locked
        self.suspended.value = mastodonUser?.suspended ?? false
        self.fields.value = mastodonUser?.fields ?? []
        self.emojiMeta.value = mastodonUser?.emojis.asDictionary ?? [:]
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
            self.isMeBarButtonItemsHidden.value = true
            return
        }
        
        if mastodonUser == currentMastodonUser {
            self.relationshipActionOptionSet.value = [.edit]
            // set bar button item state
            self.isReplyBarButtonItemHidden.value = true
            self.isMoreMenuBarButtonItemHidden.value = true
            self.isMeBarButtonItemsHidden.value = false
        } else {
            // set with follow action default
            var relationshipActionSet = RelationshipActionOptionSet([.follow])
            
            if mastodonUser.locked {
                relationshipActionSet.insert(.request)
            }
            
            if mastodonUser.suspended {
                relationshipActionSet.insert(.suspended)
            }
            
            let isFollowing = mastodonUser.followingBy.contains(currentMastodonUser)
            if isFollowing {
                relationshipActionSet.insert(.following)
            }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isFollowing: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isFollowing.description)
            
            let isPending = mastodonUser.followRequestedBy.contains(currentMastodonUser)
            if isPending {
                relationshipActionSet.insert(.pending)
            }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isPending: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isPending.description)
            
            let isFollowedBy = currentMastodonUser.followingBy.contains(mastodonUser)
            self.isFollowedBy.value = isFollowedBy
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isFollowedBy: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isFollowedBy.description)
            
            let isMuting = mastodonUser.mutingBy.contains(currentMastodonUser)
            if isMuting {
                relationshipActionSet.insert(.muting)
            }
            self.isMuting.value = isMuting
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isMuting: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isMuting.description)
            
            let isBlocking = mastodonUser.blockingBy.contains(currentMastodonUser)
            if isBlocking {
                relationshipActionSet.insert(.blocking)
            }
            self.isBlocking.value = isBlocking
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isBlocking: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isBlocking.description)
            
            let isBlockedBy = currentMastodonUser.blockingBy.contains(mastodonUser)
            if isBlockedBy {
                relationshipActionSet.insert(.blocked)
            }
            self.isBlockedBy.value = isBlockedBy
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Relationship] update %s isBlockedBy: %s", ((#file as NSString).lastPathComponent), #line, #function, mastodonUser.id, isBlockedBy.description)
            
            self.relationshipActionOptionSet.value = relationshipActionSet
            
            // set bar button item state
            self.isReplyBarButtonItemHidden.value = isBlocking || isBlockedBy
            self.isMoreMenuBarButtonItemHidden.value = false
            self.isMeBarButtonItemsHidden.value = true
        }
    }

}

extension ProfileViewModel {

    // fetch profile info before edit
    func fetchEditProfileInfo() -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        guard let currentMastodonUser = currentMastodonUser.value,
              let mastodonAuthentication = currentMastodonUser.mastodonAuthentication else {
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }

        let authorization = Mastodon.API.OAuth.Authorization(accessToken: mastodonAuthentication.userAccessToken)
        return context.apiService.accountVerifyCredentials(domain: currentMastodonUser.domain, authorization: authorization)
    }
    
    private func updateRelationship(
        record: ManagedObjectRecord<MastodonUser>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Relationship]> {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Relationship] update user relationship...")
        let response = try await context.apiService.relationship(
            records: [record],
            authenticationBox: authenticationBox
        )
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Relationship] did update MastodonUser relationship")
        return response
    }

}

extension ProfileViewModel {
    
    enum RelationshipAction: Int, CaseIterable {
        case none       // set hide from UI
        case follow
        case request
        case pending
        case following
        case muting
        case blocked
        case blocking
        case suspended
        case edit
        case editing
        case updating
        
        var option: RelationshipActionOptionSet {
            return RelationshipActionOptionSet(rawValue: 1 << rawValue)
        }
    }
    
    // construct option set on the enum for safe iterator
    struct RelationshipActionOptionSet: OptionSet {
        let rawValue: Int
        
        static let none = RelationshipAction.none.option
        static let follow = RelationshipAction.follow.option
        static let request = RelationshipAction.request.option
        static let pending = RelationshipAction.pending.option
        static let following = RelationshipAction.following.option
        static let muting = RelationshipAction.muting.option
        static let blocked = RelationshipAction.blocked.option
        static let blocking = RelationshipAction.blocking.option
        static let suspended = RelationshipAction.suspended.option
        static let edit = RelationshipAction.edit.option
        static let editing = RelationshipAction.editing.option
        static let updating = RelationshipAction.updating.option
        
        static let editOptions: RelationshipActionOptionSet = [.edit, .editing, .updating]
        
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
            case .follow: return L10n.Common.Controls.Friendship.follow
            case .request: return L10n.Common.Controls.Friendship.request
            case .pending: return L10n.Common.Controls.Friendship.pending
            case .following: return L10n.Common.Controls.Friendship.following
            case .muting: return L10n.Common.Controls.Friendship.muted
            case .blocked: return L10n.Common.Controls.Friendship.follow   // blocked by user
            case .blocking: return L10n.Common.Controls.Friendship.blocked
            case .suspended: return L10n.Common.Controls.Friendship.follow
            case .edit: return L10n.Common.Controls.Friendship.editInfo
            case .editing: return L10n.Common.Controls.Actions.done
            case .updating: return " "
            }
        }
        
        var backgroundColor: UIColor {
            guard let highPriorityAction = self.highPriorityAction(except: []) else {
                assertionFailure()
                return Asset.Colors.brandBlue.color
            }
            switch highPriorityAction {
            case .none: return Asset.Colors.brandBlue.color
            case .follow: return Asset.Colors.brandBlue.color
            case .request: return Asset.Colors.brandBlue.color
            case .pending: return Asset.Colors.brandBlue.color
            case .following: return Asset.Colors.brandBlue.color
            case .muting: return Asset.Colors.alertYellow.color
            case .blocked: return Asset.Colors.brandBlue.color
            case .blocking: return Asset.Colors.danger.color
            case .suspended: return Asset.Colors.brandBlue.color
            case .edit: return Asset.Colors.brandBlue.color
            case .editing: return Asset.Colors.brandBlue.color
            case .updating: return Asset.Colors.brandBlue.color
            }
        }

    }
}

extension ProfileViewModel {
    func updateProfileInfo(
        headerProfileInfo: ProfileHeaderViewModel.ProfileInfo,
        aboutProfileInfo: ProfileAboutViewModel.ProfileInfo
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Account> {
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            throw APIService.APIError.implicit(.badRequest)
        }
        
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let _image: UIImage? = {
            guard let image = headerProfileInfo.avatarImage else { return nil }
            guard image.size.width <= ProfileHeaderViewModel.avatarImageMaxSizeInPixel.width else {
                return image.af.imageScaled(to: ProfileHeaderViewModel.avatarImageMaxSizeInPixel)
            }
            return image
        }()
        
        let fieldsAttributes = aboutProfileInfo.fields.map { field in
            Mastodon.Entity.Field(name: field.name.value, value: field.value.value)
        }
        
        let query = Mastodon.API.Account.UpdateCredentialQuery(
            discoverable: nil,
            bot: nil,
            displayName: headerProfileInfo.name,
            note: headerProfileInfo.note,
            avatar: _image.flatMap { Mastodon.Query.MediaAttachment.png($0.pngData()) },
            header: nil,
            locked: nil,
            source: nil,
            fieldsAttributes: fieldsAttributes
        )
        return try await context.apiService.accountUpdateCredentials(
            domain: domain,
            query: query,
            authorization: authorization
        )
    }
}

//
//  SettingService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import MastodonSDK

final class SettingService {
    
    var disposeBag = Set<AnyCancellable>()
    
    private var currentSettingUpdateSubscription: AnyCancellable?
 
    // input
    weak var apiService: APIService?
    weak var authenticationService: AuthenticationService?
    weak var notificationService: NotificationService?
    
    // output
    let settingFetchedResultController: SettingFetchedResultController
    let currentSetting = CurrentValueSubject<Setting?, Never>(nil)
    
    init(
        apiService: APIService,
        authenticationService: AuthenticationService,
        notificationService: NotificationService
    ) {
        self.apiService = apiService
        self.authenticationService = authenticationService
        self.notificationService = notificationService
        self.settingFetchedResultController = SettingFetchedResultController(
            managedObjectContext: authenticationService.managedObjectContext,
            additionalPredicate: nil
        )

        // create setting (if non-exist) for authenticated users
        authenticationService.mastodonAuthenticationBoxes
            .compactMap { [weak self] mastodonAuthenticationBoxes -> AnyPublisher<[AuthenticationService.MastodonAuthenticationBox], Never>? in
                guard let self = self else { return nil }
                guard let authenticationService = self.authenticationService else { return nil }
                guard let activeMastodonAuthenticationBox = mastodonAuthenticationBoxes.first else { return nil }
                
                let domain = activeMastodonAuthenticationBox.domain
                let userID = activeMastodonAuthenticationBox.userID
                return authenticationService.backgroundManagedObjectContext.performChanges {
                    _ = APIService.CoreData.createOrMergeSetting(
                        into: authenticationService.backgroundManagedObjectContext,
                        property: Setting.Property(
                            domain: domain,
                            userID: userID,
                            appearanceRaw: SettingsItem.AppearanceMode.automatic.rawValue
                        )
                    )
                }
                .map { _ in mastodonAuthenticationBoxes }
                .eraseToAnyPublisher()
            }
            .sink { _ in
                // do nothing
            }
            .store(in: &disposeBag)
        
        // bind current setting
        Publishers.CombineLatest(
            authenticationService.activeMastodonAuthenticationBox,
            settingFetchedResultController.settings
        )
        .sink { [weak self] activeMastodonAuthenticationBox, settings in
            guard let self = self else { return }
            guard let activeMastodonAuthenticationBox = activeMastodonAuthenticationBox else { return }
            let currentSetting = settings.first(where: { setting in
                return setting.domain == activeMastodonAuthenticationBox.domain &&
                    setting.userID == activeMastodonAuthenticationBox.userID
            })
            self.currentSetting.value = currentSetting
        }
        .store(in: &disposeBag)
        
        // observe current setting
        currentSetting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] setting in
                guard let self = self else { return }
                guard let setting = setting else {
                    self.currentSettingUpdateSubscription = nil
                    return
                }
                
                self.currentSettingUpdateSubscription = ManagedObjectObserver.observe(object: setting)
                    .sink(receiveCompletion: { _ in
                        // do nothing
                    }, receiveValue: { change in
                        guard case .update(let object) = change.changeType,
                              let setting = object as? Setting else { return }
                        
                        // observe apparance mode
                        switch setting.appearance {
                        case .automatic:    UserDefaults.shared.customUserInterfaceStyle = .unspecified
                        case .light:        UserDefaults.shared.customUserInterfaceStyle = .light
                        case .dark:         UserDefaults.shared.customUserInterfaceStyle = .dark
                        }
                    })
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest3(
            notificationService.deviceToken,
            currentSetting.eraseToAnyPublisher(),
            authenticationService.activeMastodonAuthenticationBox
        )
        .compactMap { [weak self] deviceToken, setting, activeMastodonAuthenticationBox -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error>? in
            guard let self = self else { return nil }
            guard let deviceToken = deviceToken else { return nil }
            guard let setting = setting else { return nil }
            guard let authenticationBox = activeMastodonAuthenticationBox else { return nil }
            
            guard let subscription = setting.activeSubscription else { return nil }
            
            guard setting.domain == authenticationBox.domain,
                  setting.userID == authenticationBox.userID else { return nil }
            
            let _viewModel = self.notificationService?.dequeueNotificationViewModel(
                mastodonAuthenticationBox: authenticationBox
            )
            guard let viewModel = _viewModel else { return nil }
            let queryData = Mastodon.API.Subscriptions.QueryData(
                policy: subscription.policy,
                alerts: Mastodon.API.Subscriptions.QueryData.Alerts(
                    favourite: subscription.alert.favourite,
                    follow: subscription.alert.follow,
                    reblog: subscription.alert.reblog,
                    mention: subscription.alert.mention,
                    poll: subscription.alert.poll
                )
            )
            let query = viewModel.createSubscribeQuery(
                deviceToken: deviceToken,
                queryData: queryData,
                mastodonAuthenticationBox: authenticationBox
            )
    
            return apiService.createSubscription(
                subscriptionObjectID: subscription.objectID,
                query: query,
                mastodonAuthenticationBox: authenticationBox
            )
        }
        .debounce(for: .seconds(3), scheduler: DispatchQueue.main)      // limit subscribe request emit time interval
        .sink(receiveValue: { [weak self] publisher in
            guard let self = self else { return }
            publisher
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification] subscribe failure: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    case .finished:
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification] subscribe success", ((#file as NSString).lastPathComponent), #line, #function)
                    }
                } receiveValue: { _ in
                    // do nothing
                }
                .store(in: &self.disposeBag)
        })
        .store(in: &disposeBag)
    }
    
}

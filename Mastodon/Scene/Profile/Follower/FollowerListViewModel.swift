//
//  FollowerListViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK
import MastodonCore

final class FollowerListViewModel {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    @Published var accounts: [Mastodon.Entity.Account]
    @Published var relationships: [Mastodon.Entity.Relationship]
    
    let listBatchFetchViewModel: ListBatchFetchViewModel
    
    @Published var domain: String?
    @Published var userID: String?
    
    var tableView: UITableView?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<UserSection, UserItem>?
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.Loading(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    
    init(
        context: AppContext,
        authContext: AuthContext,
        domain: String?,
        userID: String?
    ) {
        self.context = context
        self.authContext = authContext
        self.domain = domain
        self.userID = userID
        self.accounts = []
        self.relationships = []
        self.listBatchFetchViewModel = ListBatchFetchViewModel()
    }
}

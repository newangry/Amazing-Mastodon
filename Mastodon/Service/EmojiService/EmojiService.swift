//
//  EmojiService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-15.
//

import os.log
import Foundation
import Combine
import MastodonSDK

final class EmojiService {
    
    
    weak var apiService: APIService?
    
    let workingQueue = DispatchQueue(label: "org.joinmastodon.Mastodon.EmojiService.working-queue")
    private(set) var customEmojiViewModelDict: [String: CustomEmojiViewModel] = [:]
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
}

extension EmojiService {

    func dequeueCustomEmojiViewModel(for domain: String) -> CustomEmojiViewModel? {
        var _customEmojiViewModel: CustomEmojiViewModel?
        workingQueue.sync {
            if let viewModel = customEmojiViewModelDict[domain] {
                _customEmojiViewModel = viewModel
            } else {
                let viewModel = CustomEmojiViewModel(domain: domain, service: self)
                _customEmojiViewModel = viewModel
                
                // trigger loading
                viewModel.stateMachine.enter(CustomEmojiViewModel.LoadState.Loading.self)
            }
        }
        return _customEmojiViewModel
    }
    
}


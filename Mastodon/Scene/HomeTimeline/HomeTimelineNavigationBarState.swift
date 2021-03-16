//
//  HomeTimelineNavigationBarState.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/15.
//

import Combine
import Foundation
import UIKit

final class HomeTimelineNavigationBarState {
    static let errorCountMax: Int = 3
    var disposeBag = Set<AnyCancellable>()
    var errorCountDownDispose: AnyCancellable?
    var timerDispose: AnyCancellable?
    var networkErrorCountSubject = PassthroughSubject<Bool, Never>()
    
    var newTopContent = CurrentValueSubject<Bool, Never>(false)
    var hasContentBeforeFetching: Bool = true
    
    weak var viewController: HomeTimelineViewController?
    
    let timestampUpdatePublisher = Timer.publish(every: NavigationBarProgressView.progressAnimationDuration, on: .main, in: .common)
        .autoconnect()
        .share()
        .eraseToAnyPublisher()
    
    init() {
        reCountdown()
        subscribeNewContent()
        addGesture()
    }
}

extension HomeTimelineNavigationBarState {
    func showOfflineInNavigationBar() {
        HomeTimelineNavigationBarView.progressView.removeFromSuperview()
        viewController?.navigationItem.titleView = HomeTimelineNavigationBarView.offlineView
    }
    
    func showNewPostsInNavigationBar() {
        HomeTimelineNavigationBarView.progressView.removeFromSuperview()
        viewController?.navigationItem.titleView = HomeTimelineNavigationBarView.newPostsView
    }
    
    func showPublishingNewPostInNavigationBar() {
        let progressView = HomeTimelineNavigationBarView.progressView
        if let navigationBar = viewController?.navigationBar(), progressView.superview == nil {
            navigationBar.addSubview(progressView)
            NSLayoutConstraint.activate([
                progressView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
                progressView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
                progressView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
                progressView.heightAnchor.constraint(equalToConstant: 3)
            ])
        }
        progressView.layoutIfNeeded()
        progressView.progress = 0
        viewController?.navigationItem.titleView = HomeTimelineNavigationBarView.publishingLabel
        
        var times: Int = 0
        timerDispose = timestampUpdatePublisher
            .map { _ in
                times += 1
                return Double(times)
            }
            .scan(0) { value, count in
                value + 1 / pow(Double(2), count)
            }
            .receive(on: DispatchQueue.main)
            .sink { value in
                print(value)
                progressView.progress = CGFloat(value)
            }
    }
    
    func showPublishedInNavigationBar() {
        timerDispose = nil
        HomeTimelineNavigationBarView.progressView.removeFromSuperview()
        viewController?.navigationItem.titleView = HomeTimelineNavigationBarView.publishedView
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            self.showMastodonLogoInNavigationBar()
        }
    }
    
    func showMastodonLogoInNavigationBar() {
        HomeTimelineNavigationBarView.progressView.removeFromSuperview()
        viewController?.navigationItem.titleView = HomeTimelineNavigationBarView.mastodonLogoTitleView
    }
}

extension HomeTimelineNavigationBarState {
    func handleScrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetY = scrollView.contentOffset.y
        let isShowingNewPostsNew = viewController?.navigationItem.titleView === HomeTimelineNavigationBarView.newPostsView
        if !isShowingNewPostsNew {
            return
        }
        let isTop = contentOffsetY < -scrollView.contentInset.top
        if isTop {
            newTopContent.value = false
            showMastodonLogoInNavigationBar()
        }
    }
    
    func addGesture() {
        let tapGesture = UITapGestureRecognizer.singleTapGestureRecognizer
        tapGesture.addTarget(self, action: #selector(HomeTimelineNavigationBarState.newPostsNewDidPressed(_:)))
        HomeTimelineNavigationBarView.newPostsView.addGestureRecognizer(tapGesture)
    }
    
    @objc func newPostsNewDidPressed(_ sender: UITapGestureRecognizer) {
        if newTopContent.value == true {
            viewController?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
}

extension HomeTimelineNavigationBarState {
    func subscribeNewContent() {
        newTopContent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newContent in
                guard let self = self else { return }
                if self.hasContentBeforeFetching, newContent {
                    self.showNewPostsInNavigationBar()
                }
            }
            .store(in: &disposeBag)
    }

    func reCountdown() {
        errorCountDownDispose = networkErrorCountSubject
            .scan(0) { value, _ in value + 1 }
            .sink(receiveValue: { [weak self] errorCount in
                guard let self = self else { return }
                if errorCount >= HomeTimelineNavigationBarState.errorCountMax {
                    self.showOfflineInNavigationBar()
                }
            })
    }
    
    func receiveCompletion(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure:
            networkErrorCountSubject.send(false)
        case .finished:
            reCountdown()
            let isShowingOfflineView = viewController?.navigationItem.titleView === HomeTimelineNavigationBarView.offlineView
            if isShowingOfflineView {
                showMastodonLogoInNavigationBar()
            }
        }
    }
}

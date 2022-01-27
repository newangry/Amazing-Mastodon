//
//  MediaView+Configuration.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreData
import Photos

extension MediaView {
    public enum Configuration: Hashable {
        case image(info: ImageInfo)
        case gif(info: VideoInfo)
        case video(info: VideoInfo)
        
        public var aspectRadio: CGSize {
            switch self {
            case .image(let info):      return info.aspectRadio
            case .gif(let info):        return info.aspectRadio
            case .video(let info):      return info.aspectRadio
            }
        }
        
        public var assetURL: String? {
            switch self {
            case .image(let info):
                return info.assetURL
            case .gif(let info):
                return info.assetURL
            case .video(let info):
                return info.assetURL
            }
        }
        
        public var resourceType: PHAssetResourceType {
            switch self {
            case .image:
                return .photo
            case .gif:
                return .video
            case .video:
                return .video
            }
        }
        
        public struct ImageInfo: Hashable {
            public let aspectRadio: CGSize
            public let assetURL: String?
            
            public init(
                aspectRadio: CGSize,
                assetURL: String?
            ) {
                self.aspectRadio = aspectRadio
                self.assetURL = assetURL
            }
            
            public func hash(into hasher: inout Hasher) {
                hasher.combine(aspectRadio.width)
                hasher.combine(aspectRadio.height)
                assetURL.flatMap { hasher.combine($0) }
            }
        }
        
        public struct VideoInfo: Hashable {
            public let aspectRadio: CGSize
            public let assetURL: String?
            public let previewURL: String?
            public let durationMS: Int?
            
            public init(
                aspectRadio: CGSize,
                assetURL: String?,
                previewURL: String?,
                durationMS: Int?
            ) {
                self.aspectRadio = aspectRadio
                self.assetURL = assetURL
                self.previewURL = previewURL
                self.durationMS = durationMS
            }
            
            public func hash(into hasher: inout Hasher) {
                hasher.combine(aspectRadio.width)
                hasher.combine(aspectRadio.height)
                assetURL.flatMap { hasher.combine($0) }
                previewURL.flatMap { hasher.combine($0) }
                durationMS.flatMap { hasher.combine($0) }
            }
        }
    }
}


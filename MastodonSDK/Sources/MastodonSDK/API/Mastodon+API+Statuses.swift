//
//  Mastodon+API+Statuses.swift
//  
//
//  Created by MainasuK Cirno on 2021-3-12.
//

import Foundation
import Combine

extension Mastodon.API.Statuses {
 
    static func publishNewStatusEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("statuses")
    }
    
    /// Publish new status
    ///
    /// Post a new status.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/18
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `PublishStatusQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func publishStatus(
        session: URLSession,
        domain: String,
        query: PublishStatusQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error>  {
        let request = Mastodon.API.post(
            url: publishNewStatusEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct PublishStatusQuery: Codable, PostQuery {
        public let status: String?
        public let mediaIDs: [String]?
        
        enum CodingKeys: String, CodingKey {
            case status
            case mediaIDs = "media_ids"
        }
        
        public init(status: String?, mediaIDs: [String]?) {
            self.status = status
            self.mediaIDs = mediaIDs
        }
    }
    
}

//
//  Item.swift
//  ZQueue
//
//  Created by Ben Shiller on 3/7/26.
//

import Foundation
import SwiftData

@Model
final class AudioItem {
    var title: String
    var fileName: String
    var bookmarkData: Data?
    var order: Int
    var dateAdded: Date

    init(title: String, fileName: String, bookmarkData: Data? = nil, order: Int, dateAdded: Date = Date()) {
        self.title = title
        self.fileName = fileName
        self.bookmarkData = bookmarkData
        self.order = order
        self.dateAdded = dateAdded
    }

    /// Resolves the security-scoped bookmark to a usable URL.
    func resolveURL() -> URL? {
        guard let bookmarkData else { return nil }
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                // Bookmark is stale — the file may have moved
                return nil
            }
            return url
        } catch {
            return nil
        }
    }
}

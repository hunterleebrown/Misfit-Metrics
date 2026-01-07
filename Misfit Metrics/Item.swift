//
//  Item.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

//
//  CGRect+Extensions.swift
//  Crate
//
//  Created by Mike Choi on 10/17/22.
//

import UIKit
import SwiftUI

extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        [minX, minY, maxX, maxY].forEach {
            hasher.combine($0)
        }
    }
}
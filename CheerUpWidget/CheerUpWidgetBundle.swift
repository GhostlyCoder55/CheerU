//
//  CheerUpWidgetBundle.swift
//  CheerUpWidget
//
//  Created by Christopher Ogbonnaya on 2025-02-27.
//

import WidgetKit
import SwiftUI

@main
struct CheerUpWidgetBundle: WidgetBundle {
    var body: some Widget {
        CheerUpWidget()
        CheerUpWidgetControl()
        CheerUpWidgetLiveActivity()
    }
}

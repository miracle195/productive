//
//  ProductiveWidgets.swift
//  Productive - WidgetKit Bundle
//  Bundles the Lock Screen & Home Screen Daily Progress Widgets and Dynamic Island Live Activities
//

import WidgetKit
import SwiftUI

@main
struct ProductiveWidgetsBundle: WidgetBundle {
    var body: some Widget {
        DailyProgressLockScreenWidget()
        ProductiveLiveActivityWidget()
    }
}


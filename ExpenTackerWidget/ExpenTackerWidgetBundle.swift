//
//  ExpenTackerWidgetBundle.swift
//  ExpenTackerWidget
//
//  Created by 張郁眉 on 2025/10/13.
//

import WidgetKit
import SwiftUI

@main
struct ExpenTackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        ExpenTackerWidget()
        ExpenTackerWidgetControl()
        ExpenTackerWidgetLiveActivity()
    }
}

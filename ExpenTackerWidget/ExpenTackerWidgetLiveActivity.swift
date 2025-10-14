//
//  ExpenTackerWidgetLiveActivity.swift
//  ExpenTackerWidget
//
//  Created by 張郁眉 on 2025/10/13.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ExpenTackerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ExpenTackerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ExpenTackerWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ExpenTackerWidgetAttributes {
    fileprivate static var preview: ExpenTackerWidgetAttributes {
        ExpenTackerWidgetAttributes(name: "World")
    }
}

extension ExpenTackerWidgetAttributes.ContentState {
    fileprivate static var smiley: ExpenTackerWidgetAttributes.ContentState {
        ExpenTackerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ExpenTackerWidgetAttributes.ContentState {
         ExpenTackerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ExpenTackerWidgetAttributes.preview) {
   ExpenTackerWidgetLiveActivity()
} contentStates: {
    ExpenTackerWidgetAttributes.ContentState.smiley
    ExpenTackerWidgetAttributes.ContentState.starEyes
}

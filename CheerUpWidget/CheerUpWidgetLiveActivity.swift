//
//  CheerUpWidgetLiveActivity.swift
//  CheerUpWidget
//
//  Created by Christopher Ogbonnaya on 2025-02-27.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CheerUpWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct CheerUpWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CheerUpWidgetAttributes.self) { context in
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

extension CheerUpWidgetAttributes {
    fileprivate static var preview: CheerUpWidgetAttributes {
        CheerUpWidgetAttributes(name: "World")
    }
}

extension CheerUpWidgetAttributes.ContentState {
    fileprivate static var smiley: CheerUpWidgetAttributes.ContentState {
        CheerUpWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: CheerUpWidgetAttributes.ContentState {
         CheerUpWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: CheerUpWidgetAttributes.preview) {
   CheerUpWidgetLiveActivity()
} contentStates: {
    CheerUpWidgetAttributes.ContentState.smiley
    CheerUpWidgetAttributes.ContentState.starEyes
}

//
//  FocusZoneWidgetLiveActivity.swift
//  FocusZoneWidget
//
//  Created by Julio J Fils on 7/20/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FocusZoneWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FocusZoneWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusZoneWidgetAttributes.self) { context in
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

extension FocusZoneWidgetAttributes {
    fileprivate static var preview: FocusZoneWidgetAttributes {
        FocusZoneWidgetAttributes(name: "World")
    }
}

extension FocusZoneWidgetAttributes.ContentState {
    fileprivate static var smiley: FocusZoneWidgetAttributes.ContentState {
        FocusZoneWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FocusZoneWidgetAttributes.ContentState {
         FocusZoneWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FocusZoneWidgetAttributes.preview) {
   FocusZoneWidgetLiveActivity()
} contentStates: {
    FocusZoneWidgetAttributes.ContentState.smiley
    FocusZoneWidgetAttributes.ContentState.starEyes
}

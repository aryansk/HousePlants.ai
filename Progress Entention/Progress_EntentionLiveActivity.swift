//
//  Progress_EntentionLiveActivity.swift
//  Progress Entention
//
//  Created by Aryan Singh on 06/05/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Progress_EntentionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Progress_EntentionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Progress_EntentionAttributes.self) { context in
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

extension Progress_EntentionAttributes {
    fileprivate static var preview: Progress_EntentionAttributes {
        Progress_EntentionAttributes(name: "World")
    }
}

extension Progress_EntentionAttributes.ContentState {
    fileprivate static var smiley: Progress_EntentionAttributes.ContentState {
        Progress_EntentionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Progress_EntentionAttributes.ContentState {
         Progress_EntentionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Progress_EntentionAttributes.preview) {
   Progress_EntentionLiveActivity()
} contentStates: {
    Progress_EntentionAttributes.ContentState.smiley
    Progress_EntentionAttributes.ContentState.starEyes
}

//
//  Progress_ExtensionLiveActivity.swift
//  Progress Extension
//
//  Created by Aryan Singh on 06/05/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Progress_ExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Progress_ExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Progress_ExtensionAttributes.self) { context in
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
            .keylineTint(Color.red)
        }
    }
}

extension Progress_ExtensionAttributes {
    fileprivate static var preview: Progress_ExtensionAttributes {
        Progress_ExtensionAttributes(name: "World")
    }
}

extension Progress_ExtensionAttributes.ContentState {
    fileprivate static var smiley: Progress_ExtensionAttributes.ContentState {
        Progress_ExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Progress_ExtensionAttributes.ContentState {
         Progress_ExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Progress_ExtensionAttributes.preview) {
   Progress_ExtensionLiveActivity()
} contentStates: {
    Progress_ExtensionAttributes.ContentState.smiley
    Progress_ExtensionAttributes.ContentState.starEyes
}

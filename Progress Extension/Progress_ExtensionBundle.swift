//
//  Progress_ExtensionBundle.swift
//  Progress Extension
//
//  Created by Aryan Singh on 06/05/26.
//

import WidgetKit
import SwiftUI

@main
struct Progress_ExtensionBundle: WidgetBundle {
    var body: some Widget {
        Progress_Extension()
        Progress_ExtensionLiveActivity()
        if #available(iOS 18.0, *) {
            Progress_ExtensionControl()
        }
    }
}

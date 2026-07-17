//
//  Progress_EntentionBundle.swift
//  Progress Entention
//
//  Created by Aryan Singh on 06/05/26.
//

import WidgetKit
import SwiftUI

@main
struct Progress_EntentionBundle: WidgetBundle {
    var body: some Widget {
        Progress_Entention()
        Progress_EntentionLiveActivity()
        if #available(iOS 18.0, *) {
            Progress_EntentionControl()
        }
    }
}

//
//  BuildInterfaceController.swift
//  CI2Go
//
//  Created by Atsushi Nagase on 6/15/15.
//  Copyright (c) 2015 LittleApps Inc. All rights reserved.
//

import WatchKit
import WatchConnectivity

class BuildInterfaceController: SingleBuildInterfaceController {

    @IBOutlet weak var timeLabel: WKInterfaceLabel!

    override func willActivate() {
        super.willActivate()
        WCSession.defaultSession().trackScreen("Build Detail")
    }

    override func updateViews() {
        super.updateViews()
        timeLabel.setText(build?.startedAt)
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        if let buildID = context as? String {
            Build.get(buildID) { build in
                self.build = build
            }
        } else {
            Build.getList { builds in
                self.build = builds.first
            }
        }
    }

}

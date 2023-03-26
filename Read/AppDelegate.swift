//
//  AppDelegate.swift
//  Read
//
//  Created by Cooper . on 3/23/23.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let splitViewController = NSSplitViewController()
            
            let leftVC = NSViewController()
            leftVC.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 600))
            leftVC.view.wantsLayer = true
            leftVC.view.layer?.backgroundColor = NSColor.red.cgColor
            
            let rightVC = NSViewController()
            rightVC.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 600))
            rightVC.view.wantsLayer = true
            rightVC.view.layer?.backgroundColor = NSColor.blue.cgColor
            
            let splitViewItem1 = NSSplitViewItem(viewController: leftVC)
            let splitViewItem2 = NSSplitViewItem(viewController: rightVC)
            
            splitViewController.splitViewItems = [splitViewItem1, splitViewItem2]
            splitViewController.minimumThicknessForInlineSidebars = 400.0
            
            let window = NSApplication.shared.windows.first
            window?.contentView = splitViewController.view
            window?.makeKeyAndOrderFront(nil)
    }




    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

}

struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
            .padding()
    }
}



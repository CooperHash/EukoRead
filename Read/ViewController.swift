//
//  ViewController.swift
//  Read
//
//  Created by Cooper . on 3/23/23.
//

import Cocoa
import SwiftUI

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let contentView = ContentView()

        let hostingController = NSHostingController(rootView: contentView)
        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        hostingController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }


    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}


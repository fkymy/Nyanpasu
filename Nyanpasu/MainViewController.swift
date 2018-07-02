//
//  MainViewController.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/02.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

extension MainViewController: StoryboardInstance {
    static var storyboardName: String {
        return "Main"
    }
}

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func logout(_ sender: UIButton) {
        // clear user session (example only, not for production)
        UserDefaults.standard.set(false, forKey: "LOGGED_IN")
        
        // navigate to Auth
        AppDelegate.shared.rootViewController.toLogoutScreen()
    }
}

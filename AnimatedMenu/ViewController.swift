//
//  ViewController.swift
//  AnimatedMenu
//
//  Created by Thanik Cheowtirakul on 28.09.18.
//  Copyright © 2018 attempto GmbH & Co. KG. All rights reserved.
//

import UIKit
import Macaw

protocol MenuDelegate {
    func navigateTo(id: String)
}

class ViewController: UIViewController {

    @IBOutlet weak var menuView: Menu!
    @IBOutlet weak var label: UILabel!
    
    var menuIsOpen = false
    
    var delegate: MenuDelegate?
    var items = [
        ("1", 0x85B1FF),
        ("2", 0xF55B58),
        ("3", 0xFF703B),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateMenu()
        
        self.delegate = self
        
        menuView.button = MenuButton(id: "demo", image: "menu.dots", color: Color(val: 0x9F85FF))
        
        menuView.items = items.map { button in
            MenuButton(
                id: button.0,
                image: "menu.dots",
                color: Color(val: button.1)
            )
        }
        
        menuView.onItemDidClick = { button, open in
            if (!open) {
                self.menuIsOpen = false
                self.updateMenu()
                self.delegate?.navigateTo(id: button.id)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func toggleMenu(_ sender: UIBarButtonItem) {
        if (self.menuIsOpen) {
            closeMenu()
        } else {
            openMenu()
        }
    }
    
    func updateMenu() {
        if (self.menuIsOpen) {
            menuView.layer.opacity = 1.0
        } else {
            menuView.layer.opacity = 0.0
        }
    }
    
    func closeMenu() {
        menuView.close() {
            self.menuIsOpen = false
            self.updateMenu()
        }
    }
    
    func openMenu() {
        self.menuIsOpen = true
        self.updateMenu()
        menuView.open()
    }
    
}

extension ViewController: MenuDelegate {
    func navigateTo(id: String) {
        self.label.text = id.uppercased()
    }
}

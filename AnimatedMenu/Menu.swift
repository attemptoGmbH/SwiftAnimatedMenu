//
//  Menu.swift
//  AnimatedMenu
//
//  Created by Thanik Cheowtirakul on 28.09.18.
//  Copyright © 2018 attempto GmbH & Co. KG. All rights reserved.
//

import UIKit
import Macaw

public struct MenuButton {
    public let id: String
    public let image: String
    public let color: Color
    
    public init(id: String, image: String, color: Color) {
        self.id = id
        self.image = image
        self.color = color
    }
}

public class Menu: MacawView {
    
    public var duration = 0.20 {
        didSet {
            updateNode()
        }
    }
    
    public var delay = 0.05 {
        didSet {
            updateNode()
        }
    }

    public var menuOffsetX = 40.0 {
        didSet {
            updateNode()
        }
    }

    public var menuOffsetY = 40.0 {
        didSet {
            updateNode()
        }
    }
    
    public var radius = 30.0 {
        didSet {
            updateNode()
        }
    }
    
    public var button: MenuButton? {
        didSet {
            //updateNode()
        }
    }
    
    public var items: [MenuButton] = [] {
        didSet {
            updateNode()
        }
    }
    
    public var menuBackground: Color? {
        didSet {
            updateNode()
        }
    }
    
    public var onItemWillClick: ((_ button: MenuButton) -> ())?
    public var onItemDidClick: ((_ button: MenuButton, _ open: Bool) -> ())?
    
    var scene: MenuScene?
    
    public var isOpen: Bool {
        get {
            if let sceneValue = scene {
                return sceneValue.isOpen
            }
            return false
        }
    }
    
    public func open() {
        scene?.updateMenu(open: true)
    }
    
    public func close(callback: (() -> Void)? = nil) {
        scene?.updateMenu(open: false) {
            callback?()
        }
    }
    
    public func updateNode() {
        guard let _ = button else {
            self.node = Group()
            self.scene = .none
            return
        }
        
        let scene = MenuScene(menu: self)
        let node = scene.node
        node.place = Transform.move(
            dx: menuOffsetX,
            dy: menuOffsetY
        )
        self.node = node
        self.scene = scene
    }
}

class MenuScene {
    
    let menu: Menu
    
    let buttonNode: Group
    let buttonsNode: Group
    let backgroundFiller: Shape
    
    let menuCircle: Shape
    let menuIcon: Image?
    
    let node: Group
    
    init(menu: Menu) {
        self.menu = menu
        let button = menu.button!
        
        menuCircle = Shape(
            form: Circle(r: menu.radius),
            fill: button.color
        )
        
        buttonNode = [menuCircle].group()
        if !button.image.isEmpty, let uiImage = UIImage(named: button.image) {
            menuIcon = Image(
                src: button.image,
                place: Transform.move(
                    dx: -Double(uiImage.size.width) / 2,
                    dy: -Double(uiImage.size.height) / 2
                )
            )
            buttonNode.contents.append(menuIcon!)
        } else {
            menuIcon = .none
        }
        
        buttonsNode = menu.items.map {
            return MenuScene.createButtonNode(button: $0, menu: menu)
            }.group()
        
        
        backgroundFiller = Shape(
            form: Rect(x: -menu.radius, y: 0.0, w: 2 * menu.radius, h: 1)
        )
        
        if let color = menu.menuBackground {
            backgroundFiller.fill = color
        } else {
            backgroundFiller.fill = button.color.with(a: 0.2)
        }
        
        node = [backgroundFiller, buttonsNode, buttonNode].group()
        
        buttonNode.onTouchPressed { _ in
            if let animationValue = self.animation {
                if animationValue.state() != .paused {
                    return
                }
            }
            self.updateMenu(open: !self.isOpen)
        }
    }
    
    var animation: Animation?
    var isOpen: Bool = false
    
    func updateMenu(open: Bool, callback: (() -> Void)? = nil) {
        if let button = menu.button {
            self.menu.onItemWillClick?(button)
            
            self.updateState(open: open) {
                self.menu.onItemDidClick?(button, open)
                callback?()
            }
        }
    }
    
    func updateState(open: Bool, callback: @escaping () -> Void) {
        if open == isOpen {
            return callback()
        }
        
        isOpen = open
        
        let nodes = self.buttonsNode.contents.enumerated()
        let expandAnimation = nodes.map { (index, node) in
            let transform = isOpen ? self.expandPlace(index: index) : Transform.identity
            let mainAnimation =  [
                node.opacityVar.animation(to: isOpen ? 1.0 : 0.0, during: menu.duration),
                node.placeVar.animation(
                    to: transform,
                    during: menu.duration
                    ).easing(Easing.easeOut)
                ].combine()
            
            let delay = menu.delay * Double(index)
            if delay == 0.0 {
                return mainAnimation
            }
            
            let filterOpacity = isOpen ? 0.0 : 1.0
            let fillerAnimation = node.opacityVar.animation(from: filterOpacity, to: filterOpacity, during: delay)
            return [fillerAnimation, mainAnimation].sequence()
        }.combine()

        let scale = isOpen ? Double(menu.items.count) * menu.radius * 2.5 : 0
        let backgroundAnimation = self.backgroundFiller.placeVar.animation(
            to: Transform.scale(sx: 1, sy: scale),
            during: menu.duration + menu.delay * Double(buttonsNode.contents.count)
        )

        // stub
        let buttonAnimation = self.buttonNode.opacityVar.animation(
            to: 1.0,
            during: menu.duration + menu.delay * Double(buttonsNode.contents.count - 1)
        )
        
        animation = [expandAnimation, backgroundAnimation, buttonAnimation].combine()
        animation?.onComplete {
            callback()
        }
        animation?.play()
    }
    
    
    class func createButtonNode(button: MenuButton, menu: Menu) -> Group {
        var contents: [Node] = [
            Shape(
                form: Circle(r: menu.radius),
                fill: button.color
            )
        ]
        if !button.image.isEmpty, let uiImage = UIImage(named: button.image) {
            let image = Image(
                src: button.image,
                place: Transform.move(
                    dx: -Double(uiImage.size.width) / 2,
                    dy: -Double(uiImage.size.height) / 2
                )
            )
            contents.append(image)
        }
        let node = Group(contents: contents)
        node.opacity = 0.0
        
        node.onTouchPressed { _ in
            menu.onItemWillClick?(button)
            
            menu.scene?.updateState(open: false) {
                menu.onItemDidClick?(button, false)
            }
        }
        return node
    }
    
    func expandPlace(index: Int) -> Transform {
        return Transform.move(
            dx: 0.0,
            dy: (Double(index) + 1.0) * menu.radius * 2.5
        )
    }
}


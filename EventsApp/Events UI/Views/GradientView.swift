//
//  GradientView.swift
//  EventsApp
//
//  Created by Bogdan on 02.08.2022.
//

import UIKit

@IBDesignable final class GradientView: UIView {
    @IBInspectable var firstColor: UIColor = .white {
        didSet { updateView() }
    }
    
    @IBInspectable var secondColor: UIColor = .black {
        didSet { updateView() }
    }
    
    override class var layerClass: AnyClass {
       get { CAGradientLayer.self }
    }
    
    private func updateView() {
        guard let gradientLayer = self.layer as? CAGradientLayer else { return }
        gradientLayer.colors = [firstColor, secondColor].map { $0.cgColor }
    }
}

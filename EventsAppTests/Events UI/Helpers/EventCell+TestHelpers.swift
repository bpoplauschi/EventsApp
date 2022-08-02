//
//  EventCell+TestHelpers.swift
//  EventsAppTests
//
//  Created by Bogdan on 02.08.2022.
//

import EventsApp
import UIKit

extension EventCell {
    var isShowingImageLoadingIndicator: Bool { imageContainer.isShimmering }
    
    var nameText: String? { nameLabel.text }
    var locationText: String? { locationLabel.text }
    var dateIntervalText: String? { dateIntervalLabel.text }
    var countText: String? { countLabel.text }
    var renderedImage: Data? { eventImageView.image?.pngData() }
}

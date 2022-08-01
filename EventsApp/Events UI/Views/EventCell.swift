//
//  EventCell.swift
//  EventsApp
//
//  Created by Bogdan on 25.07.2022.
//

import UIKit

public final class EventCell: UITableViewCell {
    @IBOutlet private(set) public var imageContainer: UIView!
    @IBOutlet private(set) public var eventImageView: UIImageView!
    @IBOutlet private(set) public var nameLabel: UILabel!
    @IBOutlet private(set) public var locationLabel: UILabel!
    @IBOutlet private(set) public var dateIntervalLabel: UILabel!
    @IBOutlet private(set) public var countLabel: UILabel!
}

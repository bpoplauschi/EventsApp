//
//  UITableView+Dequeueing.swift
//  EventsApp
//
//  Created by Bogdan on 01.08.2022.
//

import UIKit

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        let identifier = String(describing: T.self)
        return dequeueReusableCell(withIdentifier: identifier) as! T
    }
}

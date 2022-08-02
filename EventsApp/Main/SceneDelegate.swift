//
//  SceneDelegate.swift
//  EventsApp
//
//  Created by Bogdan on 14.07.2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let vividSeatsAPIURL = URL(string: "https://webservices.vividseats.com/rest/mobile/v1/home/cards")!
    private let httpClient = URLSessionHTTPClient(session: .shared)

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: scene)
        let eventsLoader = VividSeatsAPIEventsLoader(url: vividSeatsAPIURL, httpClient: httpClient)
        let imageLoader = RemoteImageDataLoader(httpClient: httpClient)
        let eventsVC = EventsUIComposer.eventsComposedWith(eventsLoader: eventsLoader, imageLoader: imageLoader)
        window?.rootViewController = UINavigationController(rootViewController: eventsVC)
        window?.makeKeyAndVisible()
    }
}

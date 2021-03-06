//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/11/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import UIKit

// Use to check for the avaialbility of an internet connection
let kREACHABLEWITHWIFI = "ReachableWithWIFI"
let kNOTREACHABLE = "NotReachable"
let kREACHABlEWITHWWAN = "ReachableWithWWAN"

var reachability: Reachability?
var reachabilityStatus = kREACHABLEWITHWIFI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var internetReach: Reachability?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Register to get notified when network chenges
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.reachabilityChanged(_:)), name: NSNotification.Name.reachabilityChanged, object: nil)
        
        internetReach = Reachability.forInternetConnection()
        // Start listening to the reachability notifications
        internetReach?.startNotifier()
        
        if internetReach != nil {
            self.statusChangedWithReachability(internetReach!)
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        // Unregister from the "reachability did changed" notification
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.reachabilityChanged, object: nil)
    }

    // MARK: - Reachability helper functions
    
    func reachabilityChanged(_ notification: Notification) {
        reachability = notification.object as? Reachability
        self.statusChangedWithReachability(reachability!)
    }
    
    func statusChangedWithReachability(_ currentReachabilityStatus: Reachability) {
        // NotReachable = 0, ReachableViaWiFi = 1, ReachableViaWWAN = 2
        let networkStatus: NetworkStatus = currentReachabilityStatus.currentReachabilityStatus()
        
        // Change the reachability status whenever the network is changed
        if networkStatus.rawValue == NotReachable.rawValue {
            reachabilityStatus = kNOTREACHABLE
        } else if networkStatus.rawValue == ReachableViaWiFi.rawValue {
            reachabilityStatus = kREACHABLEWITHWIFI
        } else if networkStatus.rawValue == ReachableViaWWAN.rawValue {
            reachabilityStatus = kREACHABlEWITHWWAN
        }
        
    }
    
}


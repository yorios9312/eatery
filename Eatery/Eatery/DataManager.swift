//
//  DataManager.swift
//  Eatery
//
//  Created by Eric Appel on 10/8/14.
//  Copyright (c) 2014 CUAppDev. All rights reserved.
//

import Foundation
import Alamofire

let DEBUG = true
let VERBOSE = true

let separator = ":------------------------------------------"

enum Time: String {
    case Today = "today"
    case Tomorrow = "tomorrow"
}

enum MealType: String {
    case Breakfast = "breakfast"
    case Brunch = "Brunch"
    case Lunch = "Lunch"
    case Dinner = "Dinner"
}

let menuIDs = ["cook_house_dining_room", "becker_house_dining_room", "keeton_house_dining_room", "rose_house_dining_room", "jansens_dining_room,_bethe_house", "robert_purcell_marketplace_eatery", "north_star", "risley_dining", "104west", "okenshields"]

/**
Router Endpoints enum

- .Root
- .Calendars
- .Calendar
- .CalendarRange
- .Menus
- .Menu
- .MenuMeal
- .Locations
- .Location
*/
enum Router: URLStringConvertible {
    static let baseURLString = "https://eatery-web.herokuapp.com"
    case Root
    case Calendars
    case Calendar(String)
    case CalendarRange(String, Time, Time)
    case Menus
    case Menu(String)
    case MenuMeal(String, MealType)
    case Locations
    case Location(String)
    
    var URLString: String {
        let path: String = {
            switch self {
            case .Root:
                return "/"
            case .Calendars:
                return "/calendars"
            case .Calendar(let calID):
                return "/calendar/\(calID)"
            case .CalendarRange(let calID, let start, let end):
                return "/calendar/\(calID)/\(start.rawValue)/\(end.rawValue)/"
            case .Menus:
                return "/menus"
            case .Menu(let menuID):
                return "/menu/\(menuID)"
            case .MenuMeal(let menuID, let meal):
                return "/menu/\(menuID)/\(meal.rawValue)"
            case .Locations:
                return "/locations"
            case .Location(let locationID):
                return "/location/\(locationID)"
            }
        }()
        return Router.baseURLString + path
    }
}

class DataManager: NSObject {
    
    var diningHalls: [DiningHall] = []
    
    class var sharedInstance : DataManager {
        struct Static {
            static var instance: DataManager = DataManager()
        }
        return Static.instance
    }
    
    func alamoTest(completion:(error: NSError?) -> Void) {
        println("\nfunc alamoTest()")
        let parameters = [
            "foo" : "bar"
        ]
        Alamofire
            .request(.GET, "http://httpbin.org/get", parameters: parameters, encoding: .URL)
            .responseJSON { (request : NSURLRequest, response: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> Void in
                printNetworkResponse(request, response, data, error)
                if let e = error {
                    completion(error: e) // send error to completion closure
                } else {
                    if let swiftyJSON = JSON(rawValue: data!) { // if object can be converted to JSON
                        
                        println("SwiftyJSON values:")
                        if let host = swiftyJSON["headers"]["Host"].string {
                            println("host: \(host)")
                        } else {
                            println("error getting value for key: " + "swiftyJSON[\"headers\"][\"Host\"]")
                        }
                        
                        /*
                        Use .xxxValue to get the non-optional value
                        *
                        *  BEWARE:
                        *  These are the values you will get if nil (taken from SwiftyJSON github page ( https://github.com/SwiftyJSON/SwiftyJSON#non-optional-getter )
                        *
                        **    If not a Number or nil, return 0
                        **    If not a String or nil, return ""
                        **    If not a Array or nil, return []
                        **    If not a Dictionary or nil, return [:]
                        *
                        */
                        let url = swiftyJSON["url"].stringValue
                        println("url: \(url)")
                        
                        completion(error: nil) // call completion closure when request is complete
                    }
                }
        }
    }
    
    func getCalendars(completion:(error: NSError?, result: [String]?) -> Void) {
        println("\nfunc getCalendars()")
        Alamofire
            .request(.GET, Router.Calendars, parameters: nil, encoding: .URL)
            .responseJSON { (request : NSURLRequest, response: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> Void in
                if let e = error {
                    completion(error: e, result: nil)
                } else {
                    if let swiftyJSON = JSON(rawValue: data!) {
                        let diningAreas = swiftyJSON.arrayValue
                        print(diningAreas)
                        var result = diningAreas.map({ (element: JSON) -> DiningHall in
                            return DiningHall(json: element)
                        })
                        
                        self.diningHalls = result
                        
                        completion(error: nil, result: nil)
                    }
                }
            }
    }
    
    func getCalendar(id: String, completion:(error: NSError?, result: [String]?) -> Void) {
        println("\nfunc getCalendars()")
        Alamofire
            .request(.GET, Router.Calendar(id), parameters: nil, encoding: .URL)
            .responseJSON { (request : NSURLRequest, response: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> Void in
                if let e = error {
                    completion(error: e, result: nil)
                } else {
                    if let swiftyJSON = JSON(rawValue: data!) {
                        
                        self.diningHalls.append(DiningHall(json: swiftyJSON))
                        
                        completion(error: nil, result: nil)
                    }
                }
        }
    }
    
    func updateMenus() {
        for menuID in menuIDs {
            updateMenu(menuID) {if $0 != nil { print($0) }}
        }
    }
    
    func updateMenu(id: String, completion:((error: NSError?) -> Void)?) {
        if !contains(menuIDs, id) {
            completion?(error: NSError())
            return
        }
        Alamofire
            .request(.GET, Router.Menu(id), parameters: nil, encoding: .URL)
            .responseJSON { (_, _, data: AnyObject?, error: NSError?) -> Void in
                if let e = error {
                    completion?(error: e)
                } else {
                    if let swiftyJSON = JSON(rawValue: data!) {
                        
                        print("\(id):\n\(Menu(data: swiftyJSON))")
                        
                        completion?(error: nil)
                    }
                }
        }
    }
    
    func loadTestData() {
        diningHalls = [
            DiningHall(location: CLLocation(), name: "North Star", summary: "North Star Summary", paymentMethods: ["BRB", "cash", "swipe"], hours: [], id: "north_star"),
            DiningHall(location: CLLocation(), name: "104 West", summary: "104 West Summary", paymentMethods: ["BRB", "swipe"], hours: [], id: "104west"),
            DiningHall(location: CLLocation(), name: "Cascadeli", summary: "Cascadeli Summary", paymentMethods: ["cash", "swipe"], hours: [], id: "cascadeli"),
            DiningHall(location: CLLocation(), name: "okenshields", summary: "Okenshields Summary", paymentMethods: ["BRB", "cash"], hours: [], id: "okenshields"),
            DiningHall(location: CLLocation(), name: "Goldies", summary: "Goldies Summary", paymentMethods: ["BRB", "cash"], hours: [], id: "goldies"),
            DiningHall(location: CLLocation(), name: "Ivy Room", summary: "Ivy Room Summary", paymentMethods: ["BRB", "cash"], hours: [], id: "ivy_room")
        ]
    }
    
}

func printNetworkResponse(request: NSURLRequest, response: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) {
    if VERBOSE {
        if error != nil {
            println("ERROR" + separator)
            println(error)
            println("REQUEST" + separator)
            println(request)
            println("RESPONSE" + separator)
            println(response)
        } else {
            println("ERROR" + separator)
            println(error)
            println("REQUEST" + separator)
            println(request)
            println("RESPONSE" + separator)
            println(response)
            println("JSON DATA" + separator) // raw json
            println(data)
            if let swiftyJSON = JSON(rawValue: data!) { // if JSON data can be converted to swiftyJSON
                println("SWIFTY JSON" + separator) // SwiftyJSON
                println(swiftyJSON)
            }
        }
        println("end " + separator)
    }
}

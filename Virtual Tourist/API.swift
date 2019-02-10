//
//  consent.swift
//  Virtual Tourist
//
//  Created by Fatima Aljaber on 29/01/2019.
//  Copyright © 2019 Fatima. All rights reserved.
//

import Foundation
import UIKit
import SVProgressHUD

class API {
    
    static let APIBaseURL = "https://api.flickr.com/services/rest/"
   
    func getPhoto(methodParameters: [String:AnyObject],completion: @escaping ([String:AnyObject])->()){
        // reguest for photo
        
        let urlString = API.APIBaseURL + escapedParameters(methodParameters as [String : AnyObject])
        let request = URLRequest(url: URL(string: urlString)!)
        SVProgressHUD.show()

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // If there is an error
            func displayError(_ error: String) {
                self.showAlert(withTitle: "error ", withMessage: error)
            }
            guard (error == nil) else {
                displayError("There was an error with your request: \(error?.localizedDescription ?? "")")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            SVProgressHUD.dismiss()

            // let's paresd the result
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            completion(parsedResult)
        } catch {
            displayError("Could not parse the data as JSON: '\(data)'")
            return
        }
            if parsedResult["stat"] as? String == "ok" {return}
            else {
                
                displayError("Flickr API returned an error.")
            }
    }
        task.resume()

    }
    func escapedParameters(_ parameters: [String:AnyObject]) -> String {
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                let stringValue = "\(value)"
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
            }
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
    func showAlert(withTitle title: String, withMessage message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default , handler: nil))
        DispatchQueue.main.async(execute: {
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        })
    }
}

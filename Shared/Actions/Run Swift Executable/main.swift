//
//  main.swift
//  It Just Works
//
//  Created by Andrew Finke on 9/15/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

// This is the Python example 'converted' to Swift

// NOTE: The included executable is not code signed, so you'll need to follow these instructions the first time to you try to run via script:
// https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unidentified-developer-mh40616/mac

let LASTFM_API_KEY = "7a4d07b562808c8719440b8ff387e5ef"
let USERNAME = "andrewfinke"
let TIMEPERIOD = "1month"

let urlString = "http://ws.audioscrobbler.com/2.0/?method=user.gettoptracks&user=\(USERNAME)&api_key=\(LASTFM_API_KEY)&format=json&period=\(TIMEPERIOD)"

guard let url = URL(string: urlString), let data = try? Data(contentsOf: url), let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Any]] else {
    fatalError()
}

guard let tracks = json["toptracks"]?["track"] as? [[String: Any]], let track = tracks.first, let name = track["name"] as? String, let count = track["playcount"] as? String  else {
    fatalError()
}

let text = "\(USERNAME) has played \(name) \(count) times"

let process = Process()
process.launchPath = "/usr/bin/osascript"
process.arguments = [
    "-e",
    """
    display dialog "\(text.replacingOccurrences(of: "\"", with: "\\\""))"
    """
]

process.launch()

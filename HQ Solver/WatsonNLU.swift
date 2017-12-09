//
//  WatsonNLU.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/29/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Foundation

class WatsonNLU {
    let url: URL
    
    private let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    init() {
        guard let plistUrl = Bundle(for: type(of: self)).url(forResource: "Keys", withExtension: "plist"),
            let data = try? Data(contentsOf: plistUrl),
            let keys = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any] else {
            print("Missing or invalid Keys.plist")
            url = URL(string: "www.google.com")!
            return
        }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "gateway.watsonplatform.net"
        components.path = "/natural-language-understanding/api//v1/analyze"
        components.query = "version=2017-02-27"
        components.user = keys["watsonUser"] as? String
        components.password = keys["watsonPassword"] as? String
        
        url = components.url!
        print("Watson URL: \(url.absoluteString)")
    }
    
    func analyze(text: String) -> WatsonNLU.Analysis? {
        let params = Params(text: text)
        var analysis: Analysis?
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONEncoder().encode(params)
        
        let group = DispatchGroup()
        group.enter()
        dataTask?.cancel()
        dataTask = defaultSession.dataTask(with: request) { (data, response, error) in
            defer {
                group.leave()
                self.dataTask = nil
            }
            if let error = error {
                print("ERROR: Failed to post (\(error))")
            }
            guard let response = response as? HTTPURLResponse else { return }
//            print("Response \(response.statusCode)")
            analysis = try? JSONDecoder().decode(Analysis.self, from: data!)
        }
        dataTask?.resume()
        group.wait()
        
//        print(analysis)
        return analysis
        
    }
    
    struct Params: Encodable {
        let text: String
        let features = Features(entities: Features.Feature(), keywords: Features.Feature(), semantic_roles: Features.Feature())
        
        struct Features: Encodable {
            let entities: Feature
            let keywords: Feature
            let semantic_roles: Feature
            
            struct Feature: Encodable {
                let limit = 10
            }
        }
    }
    
    struct Analysis: Decodable {
        let keywords: [Keyword]
        let entities: [Entity]
        
        enum CodingKeys: String, CodingKey {
            case keywords
            case entities
        }
        
        struct Keyword: Decodable {
            let text: String
            let relevance: Float
        }
        struct Entity: Decodable {
            let type: String
            let text: String
            let relevance: Float
            
            enum CodingKeys: String, CodingKey {
                case type
                case text
                case relevance
            }
        }
    }
}

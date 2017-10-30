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
        components.user = keys["watsonUser"] as! String
        components.password = keys["watsonPassword"] as! String
        
        url = components.url!
        print("Watson URL: \(url.absoluteString)")
    }
    
    func analyzie(text: String) {
        let params = Params(text: text)
        
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
            print("Response \(response.statusCode)")
            print(String(data: data!, encoding: .utf8))
            let analysis = try! JSONDecoder().decode(Analysis.self, from: data!)
            print(analysis)
        }
        dataTask?.resume()
        group.wait()
        
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
//{
//    "usage": {
//        "text_units": 1,
//        "text_characters": 69,
//        "features": 4
//    },
//    "semantic_roles": [
//    {
//    "subject": {
//    "text": "style of adidas sneakers"
//    },
//    "sentence": "Which style of adidas sneakers were made famous in the 80s by Run-DMC",
//    "object": {
//    "text": "famous"
//    },
//    "action": {
//    "verb": {
//    "text": "make",
//    "tense": "past"
//    },
//    "text": "were made",
//    "normalized": "be make"
//    }
//    }
//    ],
//    "language": "en",
//    "keywords": [
//    {
//    "text": "adidas sneakers",
//    "relevance": 0.997787
//    },
//    {
//    "text": "Run-DMC",
//    "relevance": 0.765757
//    },
//    {
//    "text": "80s",
//    "relevance": 0.633225
//    },
//    {
//    "text": "style",
//    "relevance": 0.441278
//    }
//    ],
//    "entities": [
//    {
//    "type": "Company",
//    "text": "adidas",
//    "relevance": 0.33,
//    "disambiguation": {
//    "subtype": [
//    "Brand"
//    ],
//    "name": "Adidas",
//    "dbpedia_resource": "http://dbpedia.org/resource/Adidas"
//    },
//    "count": 1
//    }
//    ],
//    "concepts": [
//    {
//    "text": "Adidas",
//    "relevance": 0.91136,
//    "dbpedia_resource": "http://dbpedia.org/resource/Adidas"
//    },
//    {
//    "text": "1980s",
//    "relevance": 0.886784,
//    "dbpedia_resource": "http://dbpedia.org/resource/1980s"
//    }
//    ]
//}


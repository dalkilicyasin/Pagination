//
//  DataSource.swift
//  CaseStudy
//
//  Created by Ovunc Dalkiran on 01.01.2021.

import Foundation

// Model class that represents a person with an `id` and a `fullName`
public class Person {
    let id: Int
    let fullName: String
    
    init(id: Int, fullName: String) {
        self.id = id
        self.fullName = fullName
    }
}


public class FetchResponse {
    let people: [Person]
    let next: String?
    
    init(people: [Person], next: String?) {
        self.people = people
        self.next = next
    }
}


public class FetchError {
    let errorDescription: String
    
    init(description: String) {
        self.errorDescription = description
    }
}

public typealias FetchCompletionHandler = (FetchResponse?, FetchError?) -> ()


public class DataSource {

    private struct Constants {
        static let peopleCountRange: ClosedRange<Int> = 100...200 // lower bound must be > 0
        static let fetchCountRange: ClosedRange<Int> = 5...20 // lower bound must be > 0
        static let lowWaitTimeRange: ClosedRange<Double> = 0.0...0.3 // lower bound must be >= 0.0
        static let highWaitTimeRange: ClosedRange<Double> = 1.0...2.0 // lower bound must be >= 0.0
        static let errorProbability = 0.1 // must be > 0.0
        static let backendBugTriggerProbability = 0.05 // must be > 0.0
        static let emptyFirstResultsProbability = 0.1 // must be > 0.0
    }

    private static var people: [Person] = []
    private static let operationsQueue = DispatchQueue.init(
        label: "data_source_operations_queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .inherit,
        target: nil
    )
    
    public class func fetch(next: String?, _ completionHandler: @escaping FetchCompletionHandler) {
        DispatchQueue.global().async {
            operationsQueue.sync {
                initializeDataIfNecessary()
                let (response, error, waitTime) = processRequest(next)
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    completionHandler(response, error)
                }
            }
        }
    }
    
    private class func initializeDataIfNecessary() {
        guard people.isEmpty else { return }
        
        var newPeople: [Person] = []
        let peopleCount: Int = RandomUtils.generateRandomInt(inClosedRange: Constants.peopleCountRange)
        for index in 0..<peopleCount {
            let person = Person(id: index + 1, fullName: PeopleGen.generateRandomFullName())
            newPeople.append(person)
        }

        people = newPeople.shuffled()
    }
    
    private class func processRequest(_ next: String?) -> (FetchResponse?, FetchError?, Double) {
        var error: FetchError? = nil
        var response: FetchResponse? = nil
        let isError = RandomUtils.roll(forProbabilityGTZero: Constants.errorProbability)
        var waitTime: Double!
        
        if isError {
            waitTime = RandomUtils.generateRandomDouble(inClosedRange: Constants.lowWaitTimeRange)
            error = FetchError(description: "Please do not refresh rapidly. Wait until listed")
        }
        else {
            waitTime = RandomUtils.generateRandomDouble(inClosedRange: Constants.highWaitTimeRange)
            let fetchCount = RandomUtils.generateRandomInt(inClosedRange: Constants.fetchCountRange)
            let peopleCount = people.count
            
            if let next = next, (Int(next) == nil || Int(next)! < 0) {
                error = FetchError(description: "There is no Peope List to show! Please try again.")
            }
            else {
                let endIndex: Int = min(peopleCount, fetchCount + (next == nil ? 0 : (Int(next!) ?? 0)))
                let beginIndex: Int = next == nil ? 0 : min(Int(next!)!, endIndex)
                var responseNext: String? = endIndex >= peopleCount ? nil : String(endIndex)
                
                var fetchedPeople: [Person] = Array(people[beginIndex..<endIndex])
                if beginIndex > 0 && RandomUtils.roll(forProbabilityGTZero: Constants.backendBugTriggerProbability) {
                    fetchedPeople.insert(people[beginIndex - 1], at: 0)
                }
                else if beginIndex == 0 && RandomUtils.roll(forProbabilityGTZero: Constants.emptyFirstResultsProbability) {
                    fetchedPeople = []
                    responseNext = nil
                }
                response = FetchResponse(people: fetchedPeople,
                                           next: responseNext)
            }
        }

        return (response, error, waitTime)
    }
    
}

// Utils

fileprivate class RandomUtils {
    

    class func generateRandomInt(inClosedRange range: ClosedRange<Int>) -> Int {
        return Int.random(in: range)
    }

    class func generateRandomInt(inRange range: Range<Int>) -> Int {
        return Int.random(in: range)
    }

    
    class func generateRandomDouble(inClosedRange range: ClosedRange<Double>) -> Double {
        return Double.random(in: range)
    }
    
    class func roll(forProbabilityGTZero probability: Double) -> Bool {
        let random = Double.random(in: 0.0...1.0)
        return random <= probability
    }
}


fileprivate class PeopleGen {
    
    private static let firstNames = [
        "Fatma",
        "Mehmet",
        "Ayşe",
        "Mustafa",
        "Emine",
        "Ahmet",
        "Hatice",
        "Ali",
        "Zeynep",
        "Hüseyin",
        "Elif",
        "Hasan",
        "İbrahim",
        "Can",
        "Murat",
        "Özlem"
    ]
    
    private static let lastNames = [
        "Yılmaz",
        "Şahin",
        "Demir",
        "Çelik",
        "Şahin",
        "Öztürk",
        "Kılıç",
        "Arslan",
        "Taş",
        "Aksoy",
        "Barış",
        "Dalkıran"
    ]
    
    class func generateRandomFullName() -> String {
        let firstNamesCount = firstNames.count
        let lastNamesCount = lastNames.count

        let firstName = firstNames[RandomUtils.generateRandomInt(inRange: 0..<firstNamesCount)]
        let lastName = lastNames[RandomUtils.generateRandomInt(inRange: 0..<lastNamesCount)]

        return "\(firstName) \(lastName)"
    }
}

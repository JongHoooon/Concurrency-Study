import UIKit

enum NetworkError: Error {
    case badUrl
    case decodingError
    case invalidID
}

struct CreditScore: Decodable {
    let score: Int
}

struct Constants {
    struct Urls {
        static func equifax(userId: Int) -> URL? {
            return URL(string: "https://ember-sparkly-rule.glitch.me/equifax/credit-score/\(userId)")
        }
        
        static func experian(userId: Int) -> URL? {
            return URL(string: "https://ember-sparkly-rule.glitch.me/experian/credit-score/\(userId)")
        }
        
    }
}

func calculateAPR(creditScores: [CreditScore]) -> Double {
    
    let sum = creditScores.reduce(0) { next, credit in
        return next + credit.score
    }
    
    return Double(sum/creditScores.count/100)
}

func getAPR(userId: Int) async throws -> Double {
    
//    if userId % 2 == 0 {
//        throw NetworkError.invalidID
//    }
    
    guard let equifaxUrl = Constants.Urls.equifax(userId: userId),
          let experianUrl = Constants.Urls.experian(userId: userId) else {
              throw NetworkError.badUrl
          }
    
    /*
     
    // 첫 번째 줄이 실행되고 종료된 이후에 두 번째 줄이 순차적으로 실행
    let (equifaxData, _) = try await URLSession.shared.data(from: equifaxUrl)
    let (experianData, _) = try await URLSession.shared.data(from: experianUrl)
     */
    
    // concurrent하게 실행
    async let (equifaxData, _) = URLSession.shared.data(from: equifaxUrl)
    async let (experianData, _) = try await URLSession.shared.data(from: experianUrl)
    
    
    let equifaxCreditScore = try? JSONDecoder().decode(CreditScore.self, from: try await equifaxData)
    let experianCrediScore = try? JSONDecoder().decode(CreditScore.self, from: try await experianData)
    
    guard let equifaxCreditScore = equifaxCreditScore,
          let experianCrediScore = experianCrediScore else {
        throw NetworkError.decodingError
    }
    
    return calculateAPR(creditScores: [equifaxCreditScore, experianCrediScore])
}

/*
Task {
    let apr = try await getAPR(userId: 1)
    print(apr)
}
*/

let ids = [1, 2, 3, 4, 5]
var invalidIds: [Int] = []

/*
Task {
    for id in ids {
        do {
            try Task.checkCancellation()
            let apr = try await getAPR(userId: id)
            print(apr)
        } catch {
            print(error)
            invalidIds.append(id)
        }
    }
    
    print(invalidIds)
} */

func getAPRForAllUsers(ids: [Int]) async throws -> [Int: Double] {
    
    var userAPR: [Int: Double] = [:]
        
        try await withThrowingTaskGroup(of: (Int, Double).self, body: { group in
            for id in ids {
                group.addTask {
                    return (id, try await getAPR(userId: id))
                }
            }
            
            // group을 하나씩 기다린다.
            for try await (id, apr) in group {
                userAPR[id] = apr
            }
        })
    return userAPR
}

Task {
    let userAPRs = try await getAPRForAllUsers(ids: ids)
    print(userAPRs)
}

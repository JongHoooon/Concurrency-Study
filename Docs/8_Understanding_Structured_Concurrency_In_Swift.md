# Section 8

## Async-let Tasks

```swift
// 첫 번째 줄이 실행되고 종료된 이후에 두 번째 줄이 순차적으로 실행
let (equifaxData, _) = try await URLSession.shared.data(from: equifaxUrl)
let (experianData, _) = try await URLSession.shared.data(from: experianUrl)
```

```swift
// concurrent하게 실행
async let (equifaxData, _) = URLSession.shared.data(from: equifaxUrl)
async let (experianData, _) = try await URLSession.shared.data(from: experianUrl)

// 사용하는 데에서는 await 사용해서 기다린다.
let equifaxCreditScore = try? JSONDecoder().decode(CreditScore.self, from: try await equifaxData)
let experianCrediScore = try? JSONDecoder().decode(CreditScore.self, from: try await experianData)
```

<br>

## Async-let in a Loop 

equifax, experian은 concurrent하게 실행되고 id에 대한 작업은 순차적으로 진행된다.

```swift
let ids = [1, 2, 3, 4, 5]
var invalidIds: [Int] = []

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
} 
```
<img src= "/Docs/images/1.png" width = "50%">

<br>

## Group Tasks

```swift
let ids = [1, 2, 3, 4, 5]

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
```

<img scr = "/Docs/images/2.png" >
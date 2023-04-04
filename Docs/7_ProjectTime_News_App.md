# Section 7

## 1. Converting FetchSources to Async and Await

<br>

### Completion Handler
```swift
func fetchSources(url: URL?, completion: @escaping (Result<[NewsSource], NetworkError>) -> Void) {
    guard let url = url else {
        completion(.failure(.badUrl))
        return
    }
    
    URLSession.shared.dataTask(with: url) { data, _, error in
        
        guard let data = data, error == nil else {
            completion(.failure(.invalidData))
            return
        }
        
        let newsSourceResponse = try? JSONDecoder().decode(NewsSourceResponse.self, from: data)
        completion(.success(newsSourceResponse?.sources ?? []))
        
    }.resume()
}
```
```swift
func getSources() {    
    Webservice().fetchSources(url: Constants.Urls.sources) { result in
        switch result {
            case .success(let newsSources):
                DispatchQueue.main.async {
                    self.newsSources = newsSources.map(NewsSourceViewModel.init)
                }
            case .failure(let error):
                print(error)
        }
    }
}
```

<br>

### Async/Await
```swift
func fetchSourcesAsync(url: URL?) async throws -> [NewsSource] {
    guard let url = url else {
        return []
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    let newsSourceResponse = try?
    JSONDecoder().decode(NewsSourceResponse.self, from: data)
    
    return newsSourceResponse?.sources ?? []
}
```
```swift
func getSources() async {
    do {
        let newsSources = try await Webservice().fetchSourcesAsync(url: Constants.Urls.sources)
        DispatchQueue.main.async {
            self.newsSources = newsSources.map(NewsSourceViewModel.init)
        }
    } catch {
        print(error)
    }    
}
```

<br>

### Rx

```swift
func fetchSourcesRx(url: URL?) -> Single<[NewsSource]> {
    return Observable.just(url)
        .map { URLRequest(url: $0!) }
        .flatMap { URLSession.shared.rx.data(request: $0) }
        .map({ data in
            do {
                let newsSourceResponse = try JSONDecoder().decode(NewsSourceResponse.self, from: data)
                return newsSourceResponse.sources
            } catch {
                throw APIError.decodingError
            }
        })
        .asSingle()
}
```
```swift
func getSoucesRx() async {
    do {
        let newsSources = try await Webservice().fetchSourcesRx(url: Constants.Urls.sources).value
        DispatchQueue.main.async {
            self.newsSources = newsSources.map(NewsSourceViewModel.init)
        }
    } catch {
        print(error)
    }
}
```

<br>
<br>

## 2. Using Continuation to Create Custom Async/Await Methods


### Completion Handler 사용
```swift
private func fetchNews(by sourceId: String, url: URL?, completion: @escaping (Result<[NewsArticle], NetworkError>) -> Void) {    
    guard let url = url else {
        completion(.failure(.badUrl))
        return
    }
        
    URLSession.shared.dataTask(with: url) { data, _, error in
        
        guard let data = data, error == nil else {
            completion(.failure(.invalidData))
            return
        }
        
        let newsArticleResponse = try? JSONDecoder().decode(NewsArticleResponse.self, from: data)
        completion(.success(newsArticleResponse?.articles ?? []))
        
    }.resume()
    
}
```
```swift
func getNewsBy(sourceId: String) async {
    Webservice().fetchNews(by: sourceId, url: Constants.Urls.topHeadlines(by: sourceId)) { result in
        switch result {
            case .success(let newsArticles):
                DispatchQueue.main.async {
                    self.newsArticles = newsArticles.map(NewsArticleViewModel.init)
                }
            case .failure(let error):
                print(error)
        }
    } 
}
```

<br>

### Continuation 사용해 변형
```swift
func fetchNewsAsync(sourceId: String, url: URL?) async throws -> [NewsArticle] {   
    try await withCheckedThrowingContinuation({ continuation in
        fetchNews(by: sourceId, url: url) { result in
            switch result {
            case .success(let newsArticles):
                continuation.resume(returning: newsArticles)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    })
}
```
```swift
func getNewsBy(sourceId: String) async {   
    do {
        let newsArticles = try await Webservice().fetchNewsAsync(sourceId: sourceId, url: Constants.Urls.topHeadlines(by: sourceId))
        DispatchQueue.main.async {
            self.newsArticles = newsArticles.map(NewsArticleViewModel.init)
        }
    } catch {
        print(error)
    }
}
```

<br>

### Rx 사용해 변형
```swift
func fetchNewsAsyncRx(sourceId: String, url: URL?) -> Single<[NewsArticle]> {
    return Single<[NewsArticle]>.create { single in
            self.fetchNews(by: sourceId, url: url, completion: { result in
                switch result {
                case .success(let newsArticles):
                    single(.success(newsArticles))
                case .failure(let error):
                    single(.failure(error))
                }
            })
        return Disposables.create {}
    }
}
```
```swift
func getSoucesRx() async {
    do {
        let newsSources = try await Webservice().fetchSourcesRx(url: Constants.Urls.sources).value
        DispatchQueue.main.async {
            self.newsSources = newsSources.map(NewsSourceViewModel.init)
        }
    } catch {
        print("error: \(error)")
    }
}
```

<br>
<br>

## 참고 

- [Mohammad Azam - Concurrency in Swift](https://www.udemy.com/course/asyncawait-and-actors-concurrency-in-swift/)
- [RxSwift Documentation](https://github.com/ReactiveX/RxSwift/blob/main/Documentation/SwiftConcurrency.md)
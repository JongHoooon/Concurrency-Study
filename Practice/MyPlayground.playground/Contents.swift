import UIKit

func fetchThumbnails() async -> [UIImage] {
    return [UIImage()]
}

func updateUI() async {
    
    // get thumbnails
    let thumbnails = await fetchThumbnails()
    
    Task.detached(priority: .background) {
        writeToCache(images: thumbnails)
    }
//    Task.detached(operation: <#T##() -> Success#>)
}

private func writeToCache(images: [UIImage]) {
    // write to cache
}


Task {
    await updateUI()
}




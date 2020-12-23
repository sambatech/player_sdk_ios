import Foundation

typealias HttpCompletionHandlerType = ((_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void)

class HttpClient {

    func post(urlString: String, json: String, completionHandler: HttpCompletionHandlerType?) {
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("http://\(Util.mainBundleIdentifier())", forHTTPHeaderField: "Origin")
        request.httpMethod = "POST"
        let postString = json
        request.httpBody = postString.data(using: .utf8)
//        print("Post String: \(postString)")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else { // check for fundamental networking error
                return
            }
//            if let httpResponse = response as? HTTPURLResponse {
//                print("Status Code \(httpResponse.statusCode)")
//            }

            completionHandler?(data, response, error)
        }
        task.resume()
    }
}

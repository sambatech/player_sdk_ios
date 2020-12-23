import Foundation

typealias LicenseCallCompletionHandler = ((_ success: Bool) -> Void)

func DPrint(_ string: String) {
    #if DEBUG
    print(string)
    #endif
}

class LicenseCall {
    var config: BitmovinAnalyticsConfig
    var httpClient: HttpClient
    var analyticsLicenseUrl: String

    init(config: BitmovinAnalyticsConfig) {
        self.config = config
        httpClient = HttpClient()
        self.analyticsLicenseUrl = BitmovinAnalyticsConfig.analyticsLicenseUrl
    }

    public func authenticate(_ completionHandler: @escaping LicenseCallCompletionHandler) {
        let licenseCallData = LicenseCallData()
        licenseCallData.key = config.key
        licenseCallData.domain = Util.mainBundleIdentifier()
        licenseCallData.analyticsVersion = Util.version()
        httpClient.post(urlString: self.analyticsLicenseUrl, json: Util.toJson(object: licenseCallData)) { data, response, error in
            guard error == nil else { // check for fundamental networking error
                completionHandler(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completionHandler(false)
                return
            }

            guard let data = data else {
                completionHandler(false)
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
                    DPrint("Licensing failed. Could not decode JSON response: \(data)")
                    completionHandler(false)
                    return
                }

                guard httpResponse.statusCode < 400 else {
                    let message = json["message"] as? String
                    DPrint("Licensing failed. Reason: \(message ?? "Unknown error")")
                    completionHandler(false)
                    return
                }

                guard let status = json["status"] as? String else {
                    DPrint("Licensing failed. Reason: status not set")
                    completionHandler(false)
                    return
                }

                guard status == "granted" else {
                    DPrint("Licensing failed. Reason given by server: \(status)")
                    completionHandler(false)
                    return
                }

                completionHandler(true)

            } catch {
                completionHandler(false)
            }
        }
    }
}

extension Notification.Name {
    static let licenseFailed = Notification.Name("licenseFailed")
}

import Foundation

public class AdModuleInformation {
    var name: String
    var version: String?
    
    init(name: String, version: String?) {
        self.name = name
        self.version = version
    }
}

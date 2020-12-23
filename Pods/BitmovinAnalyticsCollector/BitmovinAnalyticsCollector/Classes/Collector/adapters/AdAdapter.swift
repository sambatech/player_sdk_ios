import Foundation

protocol AdAdapter {
    func releaseAdapter()
    func getModuleInformation() -> AdModuleInformation
    func isAutoPlayEnabled() -> Bool
}

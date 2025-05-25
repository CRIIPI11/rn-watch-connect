import Combine
import ExpoModulesCore
import WatchConnectivity

public class RnWatchConnectModule: Module {

    private let manager = RnWatchConnectManager.shared

    public func definition() -> ModuleDefinition {
        Name("RnWatchConnect")

        // Properties
        Property("isWatchSupported") {
            self.manager.isSupported
        }

        Property("isWatchPaired") {
            self.manager.isPaired
        }

        Property("isWatchAppInstalled") {
            self.manager.isAppInstalled
        }

        Property("isWatchReachable") {
            self.manager.isReachable
        }

        Property("watchActivationState") {
            self.manager.activationState
        }

        // Events
        Events(
            "onWatchPairedChanged",
            "onWatchAppInstallChanged",
            "onReachabilityChanged"
        )

        OnStartObserving {

            manager.$isPaired
                .sink { self.sendEvent("onWatchPairedChanged", ["isPaired": $0]) }
                .store(in: &cancellables)

            manager.$isAppInstalled
                .sink { self.sendEvent("onWatchAppInstallChanged", ["isAppInstalled": $0]) }
                .store(in: &cancellables)

            manager.$isReachable
                .sink { self.sendEvent("onReachabilityChanged", ["isReachable": $0]) }
                .store(in: &cancellables)
        }

        OnStopObserving {
            cancellables.removeAll()
        }
    }

    private var cancellables: Set<AnyCancellable> = []
}

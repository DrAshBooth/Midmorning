import SwiftUI
import Record
import AppLock

/// Safe mode under the app lock (mm-t42.21). Data-and-privacy spec, "Launch
/// safety", lists what safe mode skips: "the Erasure read, the import, the
/// Reconciler and the scheduler". The app lock is not in that list, and
/// app-lock spec, "When the app asks", states: "With the app lock on, the
/// app MUST make the system authentication request at every launch." So
/// safe mode builds its controller from the same `Local.store` values as
/// the running app, and shows the same cover window over Export and Get
/// support.
struct SafeModeRootView: View {
    let store: RecordStore
    let onEverythingDeleted: () -> Void
    let onDeleteFromThisDevice: () -> Void

    @StateObject private var controller: AppLockController

    init(store: RecordStore, onEverythingDeleted: @escaping () -> Void, onDeleteFromThisDevice: @escaping () -> Void) {
        self.store = store
        self.onEverythingDeleted = onEverythingDeleted
        self.onDeleteFromThisDevice = onDeleteFromThisDevice
        _controller = StateObject(wrappedValue: AppLockControllerFactory.make(store: store))
    }

    var body: some View {
        SafeModeView(store: store)
            .appLockLifecycle(controller: controller, store: store)
            .appLockCover(
                controller: controller,
                store: store,
                onEverythingDeleted: onEverythingDeleted,
                onDeleteFromThisDevice: onDeleteFromThisDevice
            )
    }
}

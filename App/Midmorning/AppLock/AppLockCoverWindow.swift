import SwiftUI
import UIKit
import Combine
import Record
import AppLock

/// App-lock spec, "The cover": "While the app is locked, the app MUST show
/// the cover over every screen, Get support included." UIKit shows each
/// sheet and full-screen cover above the view that presents it, so an
/// overlay on Today cannot cover them (mm-t15.15). The cover therefore
/// lives in its own `UIWindow`, at a level above every presentation of the
/// app's own window. The sheets under it stay presented, so unsaved text
/// in them stays in memory (requirement "Unsaved text survives the lock").
///
/// `AppLockController.state` drives the window through
/// `AppLifecycleState.coverWindowMode`: it shows while `coverMode` is not
/// `.none`, or while a route is pending. The subscription changes the
/// window at once, in the same turn of the run loop as the state change,
/// so the cover is on screen before the system takes the App Switcher
/// snapshot.
@MainActor
final class AppLockCoverWindow: ObservableObject {
    private var window: UIWindow?
    private weak var hostWindow: UIWindow?
    private var subscription: AnyCancellable?
    private var mode: CoverWindowMode = .hidden

    func install<Root: View>(over hostWindow: UIWindow, controller: AppLockController, rootView: Root) {
        guard window == nil, let scene = hostWindow.windowScene else { return }
        self.hostWindow = hostWindow
        let hosting = UIHostingController(rootView: rootView)
        // Opaque from the first frame, before SwiftUI draws the cover.
        hosting.view.backgroundColor = .systemBackground
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.rootViewController = hosting
        window.accessibilityViewIsModal = true
        window.isHidden = true
        self.window = window
        // `@Published` sends the new value before it stores it, so this
        // reads the value it receives, never `controller.state`.
        subscription = controller.$state.sink { [weak self] state in
            self?.update(for: state)
        }
    }

    func remove() {
        subscription = nil
        guard let window else { return }
        let wasKey = window.isKeyWindow
        window.isHidden = true
        window.rootViewController = nil
        self.window = nil
        hostWindow?.accessibilityElementsHidden = false
        if wasKey { hostWindow?.makeKey() }
    }

    private func update(for state: AppLifecycleState) {
        guard let window else { return }
        // `AppLifecycleState.coverWindowMode` (`AppLock`, tested) decides.
        let mode = state.coverWindowMode
        self.mode = mode
        hostWindow?.accessibilityElementsHidden = mode != .hidden
        guard mode != .hidden else {
            guard !window.isHidden else { return }
            let wasKey = window.isKeyWindow
            window.isHidden = true
            if wasKey { hostWindow?.makeKey() }
            return
        }
        window.isHidden = false
        guard mode == .shownWithFocus, !window.isKeyWindow else { return }
        // After this update ends: the keyboard of a sheet under the cover
        // closes, and the cover's own controls get the focus. The text in
        // the sheet stays as typed.
        Task { @MainActor [weak self, weak window] in
            guard let self, let window, self.window === window, self.mode == .shownWithFocus else { return }
            self.hostWindow?.endEditing(true)
            window.makeKey()
        }
    }
}

/// What the cover window shows: the cover itself, and the empty new-entry
/// screen an entry point opens (requirement "A new entry before
/// authentication"). The new-entry screen presents from this window's
/// root, which never has another presentation, so it opens even when a
/// sheet is up in the app's own window. Before, a sheet on Today stopped
/// it, and the pending route stayed set and turned the cover off for the
/// rest of the session (mm-t15.18).
private struct AppLockCoverWindowRoot: View {
    @ObservedObject var controller: AppLockController
    let store: RecordStore
    let onEverythingDeleted: () -> Void
    let onDeleteFromThisDevice: () -> Void

    var body: some View {
        CoverView(controller: controller, onEverythingDeleted: onEverythingDeleted, onDeleteFromThisDevice: onDeleteFromThisDevice)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .fullScreenCover(isPresented: Binding(
                get: { controller.state.pendingRoute == .newEntry },
                set: { isPresented in if !isPresented { controller.handle(.pendingRouteResolved) } }
            )) {
                NewEntryView(store: store, day: RecordDay.interval(containing: Date(), calendar: .current), initialTime: nil) { _ in
                    controller.handle(.pendingRouteResolved)
                }
            }
            // A hosting controller in a window of its own does not follow
            // the scene's phase, and the new-entry screen hides its text
            // with it while the app is inactive. The controller holds the
            // same phase that the app's own window sends it.
            .environment(\.scenePhase, Self.scenePhase(controller.state.scenePhase))
            .tint(Color.accentColor)
    }

    private static func scenePhase(_ phase: LifecycleScenePhase) -> ScenePhase {
        switch phase {
        case .active: return .active
        case .inactive: return .inactive
        case .background: return .background
        }
    }
}

/// Finds the window that holds the view, so the cover window can join the
/// same scene.
private struct HostWindowReader: UIViewRepresentable {
    let onWindow: @MainActor (UIWindow) -> Void

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.isUserInteractionEnabled = false
        view.onWindow = onWindow
        return view
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        uiView.onWindow = onWindow
    }

    final class ProbeView: UIView {
        var onWindow: (@MainActor (UIWindow) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window { onWindow?(window) }
        }
    }
}

/// Puts the cover window over the view's own window.
private struct AppLockCoverModifier: ViewModifier {
    @ObservedObject var controller: AppLockController
    let store: RecordStore
    let onEverythingDeleted: () -> Void
    let onDeleteFromThisDevice: () -> Void

    @StateObject private var coverWindow = AppLockCoverWindow()

    func body(content: Content) -> some View {
        content
            .background(HostWindowReader { window in
                // A full-screen presentation takes this view out of its
                // window and puts it back, so this can run more than once;
                // `install` makes one window only. The window stays for as
                // long as this phase: `onDisappear` also runs under a
                // full-screen presentation, so it cannot remove the cover.
                let coverWindow = coverWindow
                coverWindow.install(over: window, controller: controller, rootView: AppLockCoverWindowRoot(
                    controller: controller,
                    store: store,
                    onEverythingDeleted: {
                        coverWindow.remove()
                        onEverythingDeleted()
                    },
                    onDeleteFromThisDevice: {
                        coverWindow.remove()
                        onDeleteFromThisDevice()
                    }
                ))
            })
    }
}

extension View {
    /// The app-lock cover for a phase of `AppLockRootView` that shows the
    /// record.
    func appLockCover(
        controller: AppLockController,
        store: RecordStore,
        onEverythingDeleted: @escaping () -> Void,
        onDeleteFromThisDevice: @escaping () -> Void
    ) -> some View {
        modifier(AppLockCoverModifier(
            controller: controller,
            store: store,
            onEverythingDeleted: onEverythingDeleted,
            onDeleteFromThisDevice: onDeleteFromThisDevice
        ))
    }
}

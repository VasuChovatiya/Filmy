import SwiftUI

/// Poster-to-detail zoom transition. iOS 18+ zooms the tapped poster into the detail screen and
/// back again on pop (including the interactive swipe back); iOS 17 keeps the standard push.
extension View {
    /// Marks the view the detail screen zooms out of. Use the movie id as `id`.
    @ViewBuilder
    func heroSource(id: Int, in namespace: Namespace.ID?, cornerRadius: CGFloat = Radius.m) -> some View {
        if #available(iOS 18.0, *), let namespace {
            matchedTransitionSource(id: id, in: namespace) { source in
                source.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        } else {
            self
        }
    }

    /// Applied to the pushed screen, with the same `id` and namespace as its `heroSource`.
    @ViewBuilder
    func heroDestination(id: Int, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18.0, *), let namespace {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}

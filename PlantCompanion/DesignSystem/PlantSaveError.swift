import SwiftUI

private struct PlantSaveError: ViewModifier {
    @Environment(PlantStore.self) private var store

    func body(content: Content) -> some View {
        content.alert("Could not save", isPresented: Binding(
            get: { store.lastError != nil },
            set: { if !$0 { store.lastError = nil } }
        )) {
            Button("OK") { store.lastError = nil }
        } message: {
            Text(store.lastError ?? "Please try again.")
        }
    }
}

extension View {
    func plantSaveError() -> some View { modifier(PlantSaveError()) }
}

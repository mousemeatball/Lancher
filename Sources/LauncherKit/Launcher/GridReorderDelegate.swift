#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

/// Reorders root-grid entries live as the user drags one tile over another.
struct GridReorderDelegate: DropDelegate {
    let targetID: String
    @Binding var draggingID: String?
    let onMove: (_ id: String, _ beforeTargetID: String) -> Void

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingID, dragging != targetID else { return }
        onMove(dragging, targetID)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        return true
    }
}
#endif

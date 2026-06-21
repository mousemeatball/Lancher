#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

/// Handles dragging within the root grid:
/// - Dragging an **app onto a folder** drops it *into* the folder (Launchpad-style), highlighting
///   the folder while hovered rather than reordering.
/// - Any other combination reorders entries live as you drag.
struct GridReorderDelegate: DropDelegate {
    let targetEntry: LauncherGridEntry
    @Binding var draggingID: String?
    @Binding var dropTargetFolderID: Folder.ID?
    let onReorder: (_ id: String, _ beforeTargetID: String) -> Void
    let onDropIntoFolder: (_ appEntryID: String, _ folderID: Folder.ID) -> Void

    private var draggingIsApp: Bool { draggingID?.hasPrefix("app:") ?? false }

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingID, dragging != targetEntry.id else { return }
        if case .folder(let folder) = targetEntry, draggingIsApp {
            dropTargetFolderID = folder.id          // highlight; defer the add to the drop
        } else {
            dropTargetFolderID = nil
            onReorder(dragging, targetEntry.id)
        }
    }

    func dropExited(info: DropInfo) {
        if case .folder(let folder) = targetEntry, dropTargetFolderID == folder.id {
            dropTargetFolderID = nil
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        defer { draggingID = nil; dropTargetFolderID = nil }
        guard let dragging = draggingID else { return false }
        if case .folder(let folder) = targetEntry, draggingIsApp {
            onDropIntoFolder(dragging, folder.id)
        }
        return true
    }
}
#endif

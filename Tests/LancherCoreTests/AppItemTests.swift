import Testing
import Foundation
@testable import LancherCore

@Suite struct AppItemTests {
    @Test func identityUsesProvidedID() {
        let item = AppItem(
            id: "com.test.app",
            name: "Test",
            bundleID: "com.test.app",
            url: URL(filePath: "/Applications/Test.app"),
            category: nil
        )
        #expect(item.id == "com.test.app")
    }

    @Test func equatableComparesAllFields() {
        let url = URL(filePath: "/Applications/Test.app")
        let a = AppItem(id: "x", name: "Test", bundleID: "x", url: url, category: nil)
        let b = AppItem(id: "x", name: "Test", bundleID: "x", url: url, category: nil)
        let c = AppItem(id: "x", name: "Different", bundleID: "x", url: url, category: nil)
        #expect(a == b)
        #expect(a != c)
    }
}

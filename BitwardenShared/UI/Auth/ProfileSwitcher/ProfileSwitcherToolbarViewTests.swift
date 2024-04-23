import BitwardenSdk
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

final class ProfileSwitcherToolbarViewTests: BitwardenTestCase {
    var processor: MockProcessor<ProfileSwitcherState, ProfileSwitcherAction, ProfileSwitcherEffect>!
    var subject: ProfileSwitcherToolbarView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let account = ProfileSwitcherItem.anneAccount
        let state = ProfileSwitcherState(
            accounts: [account],
            activeAccountId: account.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        processor = MockProcessor(state: state)
        subject = ProfileSwitcherToolbarView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    @ViewBuilder
    func snapshotSubject(title: String) -> some View {
        NavigationView {
            Spacer()
                .navigationBarTitle(title, displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        subject
                    }
                }
        }
    }

    /// Tapping the view dispatches the `.requestedProfileSwitcher` effect.
    func test_tap_currentAccount() async throws {
        let view = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.account)
        try await view.tap()

        XCTAssertEqual(
            processor.effects.last,
            .requestedProfileSwitcher(visible: !subject.store.state.isVisible)
        )
    }

    // MARK: Snapshots

    func test_snapshot_empty() {
        processor.state = .empty()
        assertSnapshot(
            matching: snapshotSubject(
                title: "Empty State"
            ),
            as: .portrait(heightMultiple: 0.1)
        )
    }

    func test_snapshot_noActive() {
        processor.state = .init(
            accounts: [ProfileSwitcherItem.anneAccount],
            activeAccountId: nil,
            allowLockAndLogout: true,
            isVisible: true
        )
        assertSnapshot(
            matching: snapshotSubject(
                title: "No Active Account"
            ),
            as: .portrait(heightMultiple: 0.1)
        )
    }

    func test_snapshot_singleAccount() {
        assertSnapshot(
            matching: snapshotSubject(
                title: "Single Account"
            ),
            as: .portrait(heightMultiple: 0.1)
        )
    }

    func test_snapshot_multi() {
        processor.state = .init(
            accounts: [
                ProfileSwitcherItem.anneAccount,
                ProfileSwitcherItem(
                    color: .blue,
                    email: "",
                    isUnlocked: true,
                    userId: "123",
                    userInitials: "OW",
                    webVault: ""
                ),
            ],
            activeAccountId: "123",
            allowLockAndLogout: true,
            isVisible: true
        )
        assertSnapshot(
            matching: snapshotSubject(
                title: "Multi Account"
            ),
            as: .portrait(heightMultiple: 0.1)
        )
    }

    func test_snapshot_profileIconColor_black() {
        processor.state = .init(
            accounts: [
                ProfileSwitcherItem.anneAccount,
                ProfileSwitcherItem(
                    color: Color(hex: "000000"),
                    email: "",
                    isUnlocked: true,
                    userId: "123",
                    userInitials: "OW",
                    webVault: ""
                ),
            ],
            activeAccountId: "123",
            allowLockAndLogout: true,
            isVisible: true
        )
        assertSnapshot(
            matching: snapshotSubject(
                title: "Black Icon Color"
            ),
            as: .portrait(heightMultiple: 0.1)
        )
    }

    func test_snapshot_profileIconColor_blue() {
        processor.state = .init(
            accounts: [
                ProfileSwitcherItem.anneAccount,
                ProfileSwitcherItem(
                    color: Color(hex: "16cbfc"),
                    email: "",
                    isUnlocked: true,
                    userId: "123",
                    userInitials: "OW",
                    webVault: ""
                ),
            ],
            activeAccountId: "123",
            allowLockAndLogout: true,
            isVisible: true
        )
        assertSnapshot(
            matching: snapshotSubject(
                title: "Blue Icon Color"
            ),
            as: .portrait(heightMultiple: 0.1)
        )
    }

    func test_snapshot_profileIconColor_white() {
        processor.state = .init(
            accounts: [
                ProfileSwitcherItem.anneAccount,
                ProfileSwitcherItem(
                    color: Color(hex: "ffffff"),
                    email: "",
                    isUnlocked: true,
                    userId: "123",
                    userInitials: "OW",
                    webVault: ""
                ),
            ],
            activeAccountId: "123",
            allowLockAndLogout: true,
            isVisible: true
        )
        assertSnapshot(
            matching: snapshotSubject(
                title: "White Icon Color"
            ),
            as: .portrait(heightMultiple: 0.1)
        )
    }

    func test_snapshot_profileIconColor_yellow() {
        processor.state = .init(
            accounts: [
                ProfileSwitcherItem.anneAccount,
                ProfileSwitcherItem(
                    color: Color(hex: "fcff41"),
                    email: "",
                    isUnlocked: true,
                    userId: "123",
                    userInitials: "OW",
                    webVault: ""
                ),
            ],
            activeAccountId: "123",
            allowLockAndLogout: true,
            isVisible: true
        )
        assertSnapshot(
            matching: snapshotSubject(
                title: "Yellow Icon Color"
            ),
            as: .portrait(heightMultiple: 0.1)
        )
    }
}

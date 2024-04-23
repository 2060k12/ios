import SwiftUI

#if DEBUG
extension ProfileSwitcherItem {
    static let anneAccount = ProfileSwitcherItem.fixture(
        color: .purple,
        email: "anne.account@bitwarden.com",
        userInitials: "AA"
    )

    static let beeAccount = ProfileSwitcherItem.fixture(
        color: .yellow,
        email: "bee.account@bitwarden.com",
        userInitials: "BA"
    )
}

extension ProfileSwitcherItem {
    static func fixture(
        color: Color = .purple,
        email: String = "",
        isUnlocked: Bool = false,
        userId: String = UUID().uuidString,
        userInitials: String? = nil,
        webVault: String = "vault.bitwarden.com"
    ) -> ProfileSwitcherItem {
        ProfileSwitcherItem(
            color: color,
            email: email,
            isUnlocked: isUnlocked,
            userId: userId,
            userInitials: userInitials,
            webVault: webVault
        )
    }
}

extension ProfileSwitcherState {
    static let dualAccounts = ProfileSwitcherState(
        accounts: [
            .anneAccount,
            .fixture(
                color: .yellow,
                email: "bonus.bridge@bitwarden.com",
                isUnlocked: true,
                userInitials: "BB"
            ),
        ],
        activeAccountId: ProfileSwitcherItem.anneAccount.userId,
        allowLockAndLogout: true,
        isVisible: true
    )

    static let singleAccount = ProfileSwitcherState(
        accounts: [.anneAccount],
        activeAccountId: ProfileSwitcherItem.anneAccount.userId,
        allowLockAndLogout: true,
        isVisible: true
    )

    static let singleAccountHidden = ProfileSwitcherState(
        accounts: [.anneAccount],
        activeAccountId: ProfileSwitcherItem.anneAccount.userId,
        allowLockAndLogout: true,
        isVisible: false
    )

    static let subMaximumAccounts = ProfileSwitcherState(
        accounts: [
            .anneAccount,
            .fixture(
                color: .yellow,
                email: "bonus.bridge@bitwarden.com",
                isUnlocked: true,
                userInitials: "BB"
            ),
            .fixture(
                color: .teal,
                email: "concurrent.claim@bitarden.com",
                isUnlocked: true,
                userInitials: "CC"
            ),
            .fixture(
                color: .indigo,
                email: "double.dip@bitwarde.com",
                isUnlocked: true,
                userInitials: "DD"
            ),
        ],
        activeAccountId: ProfileSwitcherItem.anneAccount.userId,
        allowLockAndLogout: true,
        isVisible: true
    )

    static let maximumAccounts = ProfileSwitcherState(
        accounts: [
            .anneAccount,
            .fixture(
                color: .yellow,
                email: "bonus.bridge@bitwarden.com",
                isUnlocked: true,
                userInitials: "BB"
            ),
            .fixture(
                color: .teal,
                email: "concurrent.claim@bitarden.com",
                isUnlocked: true,
                userInitials: "CC"
            ),
            .fixture(
                color: .indigo,
                email: "double.dip@bitwarde.com",
                isUnlocked: true,
                userInitials: "DD"
            ),
            .fixture(
                color: .green,
                email: "extra.edition@bitwarden.com",
                isUnlocked: true,
                userInitials: "EE"
            ),
        ],
        activeAccountId: ProfileSwitcherItem.anneAccount.userId,
        allowLockAndLogout: true,
        isVisible: true
    )
}
#endif

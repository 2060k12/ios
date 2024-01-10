import BitwardenSdk

// MARK: - VaultAutofillListAction

/// Actions that can be processed by a `VaultAutofillListProcessor`.
///
enum VaultAutofillListAction: Equatable {
    /// The cancel button was tapped.
    case cancelTapped

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
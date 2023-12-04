// swiftlint:disable file_length

import BitwardenSdk
import SwiftUI

// MARK: - VaultMainView

/// The main view of the vault.
private struct VaultMainView: View {
    // MARK: Properties

    /// A flag indicating if the search bar is focused.
    @Environment(\.isSearching) private var isSearching

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultListState, VaultListAction, VaultListEffect>

    var body: some View {
        // A ZStack with hidden children is used here so that opening and closing the
        // search interface does not reset the scroll position for the main vault
        // view, as would happen if we used an `if else` block here.
        //
        // Additionally, we cannot use an `.overlay()` on the main vault view to contain
        // the search interface since VoiceOver still reads the elements below the overlay,
        // which is not ideal.

        ZStack {
            let isSearching = isSearching
                || !store.state.searchText.isEmpty
                || !store.state.searchResults.isEmpty

            vault
                .hidden(isSearching)

            search
                .hidden(!isSearching)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .onChange(of: isSearching) { newValue in
            store.send(.searchStateChanged(isSearching: newValue))
        }
        .animation(.default, value: isSearching)
    }

    // MARK: Private Properties

    /// A view that displays the empty vault interface.
    @ViewBuilder private var emptyVault: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()

                    Text(Localizations.noItems)
                        .multilineTextAlignment(.center)
                        .font(.styleGuide(.callout))
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                    Button(Localizations.addAnItem) {
                        store.send(.addItemPressed)
                    }
                    .buttonStyle(.tertiary())

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(minHeight: reader.size.height)
            }
        }
    }

    /// A view that displays the search interface, including search results, an empty search
    /// interface, and a message indicating that no results were found.
    @ViewBuilder private var search: some View {
        if store.state.searchText.isEmpty || !store.state.searchResults.isEmpty {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.state.searchResults) { item in
                        Button {
                            store.send(.itemPressed(item: item))
                        } label: {
                            vaultItemRow(
                                for: item,
                                isLastInSection: store.state.searchResults.last == item
                            )
                            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
                        }
                    }
                }
            }
        } else {
            GeometryReader { reader in
                ScrollView {
                    VStack(spacing: 35) {
                        Image(decorative: Asset.Images.magnifyingGlass)
                            .resizable()
                            .frame(width: 74, height: 74)
                            .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

                        Text(Localizations.thereAreNoItemsThatMatchTheSearch)
                            .multilineTextAlignment(.center)
                            .font(.styleGuide(.callout))
                            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    }
                    .frame(maxWidth: .infinity, minHeight: reader.size.height, maxHeight: .infinity)
                }
            }
        }
    }

    /// A view that displays either the my vault or empty vault interface.
    @ViewBuilder private var vault: some View {
        LoadingView(state: store.state.loadingState) { sections in
            if sections.isEmpty {
                emptyVault
            } else {
                vaultContents(with: sections)
            }
        }
    }

    // MARK: Private Methods

    /// A view that displays the main vault interface, including sections for groups and
    /// vault items.
    ///
    /// - Parameter sections: The sections of the vault list to display.
    ///
    @ViewBuilder
    private func vaultContents(with sections: [VaultListSection]) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(sections) { section in
                    vaultSection(title: section.name, items: section.items)
                }
            }
            .padding(16)
        }
    }

    /// Creates a row in the list for the provided item.
    ///
    /// - Parameters:
    ///   - item: The `VaultListItem` to use when creating the view.
    ///   - isLastInSection: A flag indicating if this item is the last one in the section.
    ///
    @ViewBuilder
    private func vaultItemRow(for item: VaultListItem, isLastInSection: Bool = false) -> some View {
        VaultListItemRowView(store: store.child(
            state: { _ in
                VaultListItemRowState(
                    item: item,
                    hasDivider: !isLastInSection
                )
            },
            mapAction: { action in
                switch action {
                case .morePressed:
                    return .morePressed(item: item)
                }
            },
            mapEffect: nil
        ))
    }

    /// Creates a section that appears in the vault.
    ///
    /// - Parameters:
    ///   - title: The title of the section.
    ///   - items: The `VaultListItem`s in this section.
    ///
    @ViewBuilder
    private func vaultSection(title: String, items: [VaultListItem]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(title.uppercased())
                Spacer()
                Text("\(items.count)")
            }
            .font(.footnote)
            .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(items) { item in
                    Button {
                        store.send(.itemPressed(item: item))
                    } label: {
                        vaultItemRow(for: item, isLastInSection: items.last == item)
                    }
                }
            }
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - VaultListView

/// A view that allows the user to view a list of the items in their vault.
///
struct VaultListView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultListState, VaultListAction, VaultListEffect>

    var body: some View {
        ZStack {
            VaultMainView(store: store)
                .searchable(
                    text: store.binding(
                        get: \.searchText,
                        send: VaultListAction.searchTextChanged
                    ),
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Localizations.search
                )
                .refreshable {
                    await store.perform(.refreshVault)
                }
            profileSwitcher
        }
        .navigationTitle(Localizations.myVault)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    store.send(.requestedProfileSwitcher(visible: !store.state.profileSwitcherState.isVisible))
                } label: {
                    HStack {
                        Text(store.state.userInitials)
                            .font(.styleGuide(.caption2Monospaced))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.purple)
                            .clipShape(Circle())
                        Spacer()
                    }
                    .frame(minWidth: 50)
                    .fixedSize()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                AddItemButton {
                    store.send(.addItemPressed)
                }
            }
        }
        .task {
            await store.perform(.refreshAccountProfiles)
        }
        .task {
            await store.perform(.appeared)
        }
    }

    // MARK: Private properties

    /// A view that displays the ability to add or switch between account profiles
    @ViewBuilder private var profileSwitcher: some View {
        ProfileSwitcherView(
            store: store.child(
                state: { vaultListState in
                    vaultListState.profileSwitcherState
                },
                mapAction: { action in
                    .profileSwitcherAction(action)
                },
                mapEffect: nil
            )
        )
    }
}

// MARK: Previews

#if DEBUG
// swiftlint:disable:next type_body_length
struct VaultListView_Previews: PreviewProvider {
    static let account1 = ProfileSwitcherItem(
        color: .purple,
        email: "Anne.Account@bitwarden.com",
        userInitials: "AA"
    )

    static let account2 = ProfileSwitcherItem(
        color: .green,
        email: "bonus.bridge@bitwarden.com",
        isUnlocked: true,
        userInitials: "BB"
    )

    static let singleAccountState = ProfileSwitcherState(
        accounts: [account1],
        activeAccountId: account1.userId,
        isVisible: false
    )

    static let dualAccountState = ProfileSwitcherState(
        accounts: [account1, account2],
        activeAccountId: account1.userId,
        isVisible: false
    )

    static var previews: some View {
        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState()
                    )
                )
            )
        }
        .previewDisplayName("Loading")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            loadingState: .data([])
                        )
                    )
                )
            )
        }
        .previewDisplayName("Empty")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            loadingState: .data([
                                VaultListSection(
                                    id: "1",
                                    items: [
                                        .init(cipherListView: .init(
                                            id: UUID().uuidString,
                                            organizationId: nil,
                                            folderId: nil,
                                            collectionIds: [],
                                            name: "Example",
                                            subTitle: "email@example.com",
                                            type: .login,
                                            favorite: true,
                                            reprompt: .none,
                                            edit: false,
                                            viewPassword: true,
                                            attachments: 0,
                                            creationDate: Date(),
                                            deletedDate: nil,
                                            revisionDate: Date()
                                        ))!,
                                        .init(cipherListView: .init(
                                            id: UUID().uuidString,
                                            organizationId: nil,
                                            folderId: nil,
                                            collectionIds: [],
                                            name: "Example 2",
                                            subTitle: "",
                                            type: .secureNote,
                                            favorite: true,
                                            reprompt: .none,
                                            edit: false,
                                            viewPassword: true,
                                            attachments: 0,
                                            creationDate: Date(),
                                            deletedDate: nil,
                                            revisionDate: Date()
                                        ))!,
                                    ],
                                    name: "Favorites"
                                ),
                                VaultListSection(
                                    id: "2",
                                    items: [
                                        VaultListItem(
                                            id: "21",
                                            itemType: .group(.login, 123)
                                        ),
                                        VaultListItem(
                                            id: "22",
                                            itemType: .group(.card, 25)
                                        ),
                                        VaultListItem(
                                            id: "23",
                                            itemType: .group(.identity, 1)
                                        ),
                                        VaultListItem(
                                            id: "24",
                                            itemType: .group(.secureNote, 0)
                                        ),
                                    ],
                                    name: "Types"
                                ),
                            ])
                        )
                    )
                )
            )
        }
        .previewDisplayName("My Vault")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            profileSwitcherState: ProfileSwitcherState(
                                accounts: [],
                                activeAccountId: nil,
                                isVisible: false
                            ),
                            searchResults: [
                                .init(cipherListView: .init(
                                    id: UUID().uuidString,
                                    organizationId: nil,
                                    folderId: nil,
                                    collectionIds: [],
                                    name: "Example",
                                    subTitle: "email@example.com",
                                    type: .login,
                                    favorite: true,
                                    reprompt: .none,
                                    edit: false,
                                    viewPassword: true,
                                    attachments: 0,
                                    creationDate: Date(),
                                    deletedDate: nil,
                                    revisionDate: Date()
                                ))!,
                            ],
                            searchText: "Exam"
                        )
                    )
                )
            )
        }
        .previewDisplayName("1 Search Result")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            searchResults: [
                                .init(cipherListView: .init(
                                    id: UUID().uuidString,
                                    organizationId: nil,
                                    folderId: nil,
                                    collectionIds: [],
                                    name: "Example",
                                    subTitle: "email@example.com",
                                    type: .login,
                                    favorite: true,
                                    reprompt: .none,
                                    edit: false,
                                    viewPassword: true,
                                    attachments: 0,
                                    creationDate: Date(),
                                    deletedDate: nil,
                                    revisionDate: Date()
                                ))!,
                                .init(cipherListView: .init(
                                    id: UUID().uuidString,
                                    organizationId: nil,
                                    folderId: nil,
                                    collectionIds: [],
                                    name: "Example 2",
                                    subTitle: "email2@example.com",
                                    type: .login,
                                    favorite: true,
                                    reprompt: .none,
                                    edit: false,
                                    viewPassword: true,
                                    attachments: 0,
                                    creationDate: Date(),
                                    deletedDate: nil,
                                    revisionDate: Date()
                                ))!,
                                .init(cipherListView: .init(
                                    id: UUID().uuidString,
                                    organizationId: nil,
                                    folderId: nil,
                                    collectionIds: [],
                                    name: "Example 3",
                                    subTitle: "email3@example.com",
                                    type: .login,
                                    favorite: true,
                                    reprompt: .none,
                                    edit: false,
                                    viewPassword: true,
                                    attachments: 0,
                                    creationDate: Date(),
                                    deletedDate: nil,
                                    revisionDate: Date()
                                ))!,
                            ],
                            searchText: "Exam"
                        )
                    )
                )
            )
        }
        .previewDisplayName("3 Search Results")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            searchResults: [],
                            searchText: "Exam"
                        )
                    )
                )
            )
        }
        .previewDisplayName("No Search Results")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            profileSwitcherState: singleAccountState
                        )
                    )
                )
            )
        }
        .previewDisplayName("Profile Switcher Visible: Single Account")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            profileSwitcherState: dualAccountState
                        )
                    )
                )
            )
        }
        .previewDisplayName("Profile Switcher Visible: Multi Account")
    }
}
#endif
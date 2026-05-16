import SwiftUI

struct BulletinFormView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: BulletinFormViewModel
    @State private var hasExpiry: Bool

    let onSaved: (UUID) -> Void

    init(mode: BulletinFormViewModel.Mode, service: BulletinsService, prefill: BulletinDetails? = nil, onSaved: @escaping (UUID) -> Void) {
        let vm = BulletinFormViewModel(mode: mode, service: service, prefill: prefill)
        _viewModel = State(initialValue: vm)
        _hasExpiry = State(initialValue: prefill?.expiresAt != nil)
        self.onSaved = onSaved
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Bulletin title", text: $vm.title)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Detail") {
                    TextEditor(text: $vm.detail)
                        .frame(minHeight: 140)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Category") {
                    categoryPicker
                }

                Section("Audience") {
                    audiencePicker
                }

                Section("Options") {
                    Toggle("Requires acknowledgement", isOn: $vm.requiresAcknowledgement)
                    if BulletinAccessPolicy.canPin(me: session.me) {
                        Toggle("Pinned", isOn: $vm.isPinned)
                    }
                    Toggle("Set expiry", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker(
                            "Expires",
                            selection: Binding(
                                get: { vm.expiresAt ?? Date().addingTimeInterval(60 * 60 * 24 * 7) },
                                set: { vm.expiresAt = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                .onChange(of: hasExpiry) { _, isOn in
                    if !isOn { vm.expiresAt = nil }
                }

                if let saveError = vm.saveError {
                    Section {
                        Label(saveError, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            // Use LocalizedStringKey explicitly so ternaries don't collapse to
            // runtime Strings (which would skip the catalog lookup).
            .navigationTitle(Text(vm.mode.isEdit ? LocalizedStringKey("Edit bulletin") : LocalizedStringKey("New bulletin")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(vm.saveInFlight)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: submit) {
                        if vm.mode.isEdit {
                            Text("Save")
                        } else {
                            Text("Post")
                        }
                    }
                    .disabled(!vm.canSubmit)
                }
            }
            .overlay {
                if vm.saveInFlight {
                    ProgressView()
                        .controlSize(.large)
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .task { await vm.loadCategoriesIfNeeded() }
        }
        .interactiveDismissDisabled(vm.saveInFlight)
    }

    // MARK: - Pickers

    @ViewBuilder
    private var categoryPicker: some View {
        @Bindable var vm = viewModel

        switch vm.categoryState {
        case .idle, .loading:
            HStack { ProgressView(); Text("Loading…").foregroundStyle(.secondary) }
        case .error(let message):
            VStack(alignment: .leading, spacing: 6) {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                Button("Try again") {
                    Task { await vm.loadCategoriesIfNeeded() }
                }
            }
        case .loaded:
            if vm.categories.isEmpty {
                Text("No categories available")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Category", selection: $vm.selectedCategoryId) {
                    Text("Choose a category").tag(UUID?.none)
                    ForEach(vm.categories) { cat in
                        HStack {
                            Image(systemName: FontAwesomeMapping.sfSymbol(for: cat.icon))
                                .foregroundStyle(Color(hex: cat.colourCode))
                            Text(cat.name)
                        }
                        .tag(UUID?.some(cat.id))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var audiencePicker: some View {
        @Bindable var vm = viewModel

        let kinds: [BulletinAudienceKind] = [.allStaff, .allPupils, .allParents]
        ForEach(kinds, id: \.self) { kind in
            Toggle(kind.displayName, isOn: Binding(
                get: { vm.selectedAudiences.contains(kind) },
                set: { isOn in
                    if isOn { vm.selectedAudiences.insert(kind) }
                    else    { vm.selectedAudiences.remove(kind) }
                }
            ))
        }
        if vm.selectedAudiences.isEmpty {
            Text("Pick at least one audience.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Submit

    private func submit() {
        Task {
            if let id = await viewModel.submit() {
                onSaved(id)
                dismiss()
            }
        }
    }
}

#if DEBUG
#Preview("Create") {
    let categories = [
        BulletinCategory(id: UUID(uuidString: "AAAAAAAA-1111-1111-1111-111111111111")!,
                         name: "General", icon: "fa-solid fa-bullhorn", colourCode: "#0EA5E9",
                         displayOrder: 1, active: true, isSystem: true, version: 1),
        BulletinCategory(id: UUID(uuidString: "BBBBBBBB-2222-2222-2222-222222222222")!,
                         name: "Safeguarding", icon: "fa-solid fa-triangle-exclamation", colourCode: "#DC2626",
                         displayOrder: 2, active: true, isSystem: true, version: 1)
    ]
    let service = MockBulletinsService().withCategories(categories)

    return BulletinFormView(mode: .create, service: service) { _ in }
        .environment(AppSession.preview(phase: .authenticated(.previewStaff), bulletinsService: service))
}

#Preview("Edit") {
    let categories = [
        BulletinCategory(id: BulletinSummary.previewUrgent.categoryId,
                         name: BulletinSummary.previewUrgent.categoryName,
                         icon: BulletinSummary.previewUrgent.categoryIcon,
                         colourCode: BulletinSummary.previewUrgent.categoryColourCode,
                         displayOrder: 1, active: true, isSystem: true, version: 1)
    ]
    let service = MockBulletinsService().withCategories(categories)

    return BulletinFormView(
        mode: .edit(id: BulletinDetails.previewUrgent.id, version: BulletinDetails.previewUrgent.version),
        service: service,
        prefill: BulletinDetails.previewUrgent
    ) { _ in }
    .environment(AppSession.preview(phase: .authenticated(.previewStaff), bulletinsService: service))
}
#endif

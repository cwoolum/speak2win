import SwiftUI

enum AddMode: String, CaseIterable {
    case newWord = "Add as new word"
    case aliasToExisting = "Add as alias to existing word"
}

struct AddToDictionarySheet: View {
    let selectedText: String
    @EnvironmentObject var dictionaryState: DictionaryState
    @Environment(\.dismiss) private var dismiss

    @State private var addMode: AddMode = .newWord
    @State private var selectedExistingEntry: DictionaryEntry? = nil
    @State private var category: EntryCategory = .custom
    @State private var searchQuery: String = ""

    private var filteredEntries: [DictionaryEntry] {
        if searchQuery.isEmpty {
            return dictionaryState.entries
        }
        return dictionaryState.entries.filter {
            $0.word.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add to Dictionary")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                // Selected text display
                HStack {
                    Text("Selected text:")
                        .foregroundColor(.secondary)
                    Text(selectedText)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }

                // Mode picker
                Picker("Mode", selection: $addMode) {
                    ForEach(AddMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)

                if addMode == .newWord {
                    // Category for new word
                    Picker("Category", selection: $category) {
                        ForEach(EntryCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                } else {
                    // Search and select existing word
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Search existing words...", text: $searchQuery)
                            .textFieldStyle(.roundedBorder)

                        if filteredEntries.isEmpty {
                            Text("No existing words found")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ScrollView {
                                VStack(spacing: 4) {
                                    ForEach(filteredEntries) { entry in
                                        HStack {
                                            Image(systemName: entry.category.icon)
                                                .foregroundColor(.secondary)
                                            Text(entry.word)
                                            Spacer()
                                            if selectedExistingEntry?.id == entry.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedExistingEntry?.id == entry.id
                                            ? Color.accentColor.opacity(0.1)
                                            : Color.clear
                                        )
                                        .cornerRadius(4)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedExistingEntry = entry
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 150)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .padding()

            Divider()

            // Footer
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("Add") {
                    addToDictionary()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
                .disabled(addMode == .aliasToExisting && selectedExistingEntry == nil)
            }
            .padding()
        }
        .frame(width: 400, height: addMode == .newWord ? 280 : 420)
    }

    private func addToDictionary() {
        let trimmedText = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)

        if addMode == .newWord {
            // Create new dictionary entry with the selected text as the word
            let newEntry = DictionaryEntry(
                word: trimmedText,
                language: dictionaryState.selectedLanguage,
                category: category
            )
            dictionaryState.add(newEntry)
        } else if let existingEntry = selectedExistingEntry {
            // Add as alias to existing entry
            var updatedEntry = existingEntry
            if !updatedEntry.aliases.contains(where: { $0.lowercased() == trimmedText.lowercased() }) {
                updatedEntry.aliases.append(trimmedText)
                dictionaryState.update(updatedEntry)
            }
        }

        dismiss()
    }
}

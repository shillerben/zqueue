//
//  QueueView.swift
//  ZQueue
//
//  Created by Ben Shiller on 3/7/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct QueueView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AudioItem.order) private var items: [AudioItem]
    @State private var showingFilePicker = false
    @State private var showingPlayback = false
    @State private var selectedItems: Set<PersistentIdentifier> = []
    @State private var isEditing = false
    @Bindable var playerManager: AudioPlayerManager

    var body: some View {
        NavigationStack {
            List(selection: isEditing ? $selectedItems : nil) {
                ForEach(items) { item in
                    Button {
                        playerManager.loadQueue(items)
                        if let index = items.firstIndex(where: { $0.id == item.id }) {
                            playerManager.playItem(at: index)
                        }
                        showingPlayback = true
                    } label: {
                        QueueRowView(item: item, isCurrentItem: item.id == playerManager.currentItem?.id)
                    }
                    .tint(.primary)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
                .deleteDisabled(isEditing)
            }
            .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("No Audio Files", systemImage: "music.note.list")
                    } description: {
                        Text("Tap + to add audio files to your queue.")
                    }
                }
            }
            .navigationTitle("ZQueue")
            .toolbar {
                if !items.isEmpty && isEditing {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if selectedItems.count == items.count {
                                selectedItems.removeAll()
                            } else {
                                selectedItems = Set(items.map(\.persistentModelID))
                            }
                        } label: {
                            Text(selectedItems.count == items.count ? "Deselect All" : "Select All")
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive) {
                            deleteSelectedItems()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(selectedItems.isEmpty)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Done") {
                            isEditing = false
                            selectedItems.removeAll()
                        }
                    } else {
                        Button {
                            showingFilePicker = true
                        } label: {
                            Label("Add Audio", systemImage: "plus")
                        }
                    }
                }
                if !items.isEmpty && !isEditing {
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            playerManager.loadQueue(items)
                            showingPlayback = true
                        } label: {
                            Label("Play", systemImage: "play.fill")
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .navigationDestination(isPresented: $showingPlayback) {
                PlaybackView(playerManager: playerManager, items: items)
            }
            .onAppear {
                playerManager.sendWatchQueueState(items: items)
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            let startOrder = (items.map(\.order).max() ?? -1) + 1
            for (index, url) in urls.enumerated() {
                let accessing = url.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                do {
                    let bookmarkData = try url.bookmarkData(
                        options: [],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    let title = url.deletingPathExtension().lastPathComponent
                    let item = AudioItem(
                        title: title,
                        fileName: url.lastPathComponent,
                        bookmarkData: bookmarkData,
                        order: startOrder + index
                    )
                    modelContext.insert(item)
                } catch {
                    print("Failed to create bookmark for \(url): \(error)")
                }
            }
            playerManager.sendWatchQueueState(items: items)
        case .failure(let error):
            print("File import failed: \(error.localizedDescription)")
        }
    }

    private func deleteSelectedItems() {
        withAnimation {
            for item in items where selectedItems.contains(item.persistentModelID) {
                modelContext.delete(item)
            }
            selectedItems.removeAll()
            isEditing = false
            reorderItems()
        }
        playerManager.sendWatchQueueState(items: items)
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
            reorderItems()
        }
        playerManager.sendWatchQueueState(items: items)
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var mutableItems = items
        mutableItems.move(fromOffsets: source, toOffset: destination)
        for (index, item) in mutableItems.enumerated() {
            item.order = index
        }
        playerManager.sendWatchQueueState(items: items)
    }

    private func reorderItems() {
        for (index, item) in items.enumerated() {
            item.order = index
        }
    }
}

// MARK: - Queue Row View

struct QueueRowView: View {
    let item: AudioItem
    let isCurrentItem: Bool

    var body: some View {
        HStack {
            Image(systemName: isCurrentItem ? "speaker.wave.2.fill" : "music.note")
                .foregroundColor(isCurrentItem ? .accentColor : .secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                    .fontWeight(isCurrentItem ? .semibold : .regular)
                Text(item.fileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

import SwiftUI

struct TagManagerView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        store.selectedTag = nil
                        dismiss()
                    } label: {
                        HStack {
                            Text("全部名片")
                            Spacer()
                            Text("\(store.cards.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("标签") {
                    if store.tags.isEmpty {
                        Text("还没有标签，编辑名片时可以添加")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.tags, id: \.self) { tag in
                            Button {
                                store.selectedTag = tag
                                dismiss()
                            } label: {
                                HStack {
                                    Text(tag)
                                    Spacer()
                                    Text("\(count(for: tag))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteTags)
                    }
                }
            }
            .navigationTitle("标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func count(for tag: String) -> Int {
        store.cards.filter { $0.tags.contains(tag) }.count
    }

    private func deleteTags(at offsets: IndexSet) {
        let tags = store.tags
        for index in offsets where tags.indices.contains(index) {
            store.deleteTag(tags[index])
        }
    }
}

import SwiftUI
import CardCore

struct CardListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showScanner = false
    @State private var showTagManager = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if store.cards.isEmpty {
                    emptyState
                } else {
                    cardList
                }
            }
            if let tag = store.selectedTag {
                tagBar(tag)
            }
        }
        .navigationTitle("名片夹")
        .searchable(text: $store.searchText, prompt: "搜索姓名 / 公司 / 电话 / 邮箱")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showTagManager = true
                } label: {
                    Image(systemName: "tag")
                }
                .disabled(store.tags.isEmpty)
                .accessibilityLabel("标签")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showScanner = true
                } label: {
                    Image(systemName: "camera.viewfinder")
                }
                .accessibilityLabel("扫描名片")
            }
        }
        .navigationDestination(for: BusinessCard.self) { card in
            CardDetailView(cardID: card.id)
        }
        .sheet(isPresented: $showTagManager) {
            TagManagerView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showScanner) {
            ScanFlowView()
                .environmentObject(store)
        }
        .alert("出错了", isPresented: errorBinding) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(store.lastErrorMessage ?? "")
        }
    }

    private var cardList: some View {
        List {
            if store.filteredCards.isEmpty {
                ContentUnavailableView(
                    "没有匹配的名片",
                    systemImage: "magnifyingglass",
                    description: Text("换个关键词或标签试试")
                )
            } else {
                ForEach(store.filteredCards) { card in
                    NavigationLink(value: card) {
                        CardRow(card: card)
                    }
                }
                .onDelete(perform: deleteCards)
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("还没有名片")
                .font(.title3.bold())
            Text("拍摄或导入一张名片，开始建立你的名片夹")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showScanner = true
            } label: {
                Label("扫描第一张名片", systemImage: "camera.viewfinder")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tagBar(_ tag: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "tag.fill")
            Text(tag)
            Spacer()
            Button {
                store.selectedTag = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
        }
        .font(.footnote)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
        .padding(.bottom, 12)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { store.lastErrorMessage != nil },
            set: { newValue in
                if !newValue { store.clearError() }
            }
        )
    }

    private func deleteCards(at offsets: IndexSet) {
        let cards = store.filteredCards
        for index in offsets where cards.indices.contains(index) {
            store.delete(cards[index])
        }
    }
}

struct CardRow: View {
    @EnvironmentObject private var store: AppStore
    let card: BusinessCard

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                Text(card.displayName)
                    .font(.headline)
                if !card.subtitle.isEmpty {
                    Text(card.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let phone = card.primaryPhone {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = store.image(for: card, processed: true) ?? store.image(for: card, processed: false) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 64, height: 40)
                .overlay(Image(systemName: "person.crop.rectangle").foregroundStyle(.secondary))
        }
    }
}

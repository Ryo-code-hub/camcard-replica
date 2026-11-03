import SwiftUI
import UIKit
import CardCore

struct CardDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let cardID: UUID

    @State private var showEditor = false
    @State private var showDeleteConfirm = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false

    private var card: BusinessCard? {
        store.cards.first { $0.id == cardID }
    }

    var body: some View {
        Group {
            if let card {
                content(for: card)
            } else {
                ContentUnavailableView("名片已删除", systemImage: "trash")
            }
        }
        .navigationTitle("名片详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditor = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    Button {
                        exportVCF()
                    } label: {
                        Label("导出 VCF", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let card {
                NavigationStack {
                    CardFormView(mode: .edit, initialDraft: CardDraft(card: card)) { draft in
                        store.update(draft.apply(to: card))
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(items: shareItems)
        }
        .confirmationDialog("确定删除这张名片吗？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                if let card {
                    store.delete(card)
                }
                dismiss()
            }
            Button("取消", role: .cancel) {}
        }
    }

    private func content(for card: BusinessCard) -> some View {
        Form {
            Section {
                if let image = store.image(for: card, processed: true) ?? store.image(for: card, processed: false) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Section("基本信息") {
                DetailRow(title: "姓名", value: card.name)
                DetailRow(title: "公司", value: card.company)
                DetailRow(title: "职位", value: card.jobTitle)
            }

            if !card.mobiles.isEmpty || !card.phones.isEmpty || !card.faxes.isEmpty {
                Section("电话") {
                    ForEach(card.mobiles, id: \.self) { number in
                        Button {
                            open("tel://\(dialable(number))")
                        } label: {
                            Label(number, systemImage: "phone.fill")
                        }
                    }
                    ForEach(card.phones, id: \.self) { number in
                        Button {
                            open("tel://\(dialable(number))")
                        } label: {
                            Label(number, systemImage: "phone")
                        }
                    }
                    ForEach(card.faxes, id: \.self) { number in
                        Label(number, systemImage: "printer")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("联系方式") {
                ForEach(card.emails, id: \.self) { email in
                    Button {
                        open("mailto:\(email)")
                    } label: {
                        Label(email, systemImage: "envelope")
                    }
                }
                if !card.website.isEmpty {
                    Button {
                        open(websiteURL(card.website))
                    } label: {
                        Label(card.website, systemImage: "globe")
                    }
                }
                DetailRow(title: "地址", value: card.address)
            }

            if !card.tags.isEmpty {
                Section("标签") {
                    WrappingTags(tags: card.tags)
                }
            }

            Section("备注") {
                if card.notes.isEmpty {
                    Text("暂无备注").foregroundStyle(.secondary)
                } else {
                    Text(card.notes)
                }
            }

            Section {
                Button {
                    exportVCF()
                } label: {
                    Label("导出为 VCF 名片", systemImage: "square.and.arrow.up")
                }
                Button {
                    showEditor = true
                } label: {
                    Label("编辑名片", systemImage: "pencil")
                }
            }

            Section("识别证据") {
                DisclosureGroup("OCR 原始文本") {
                    Text(card.rawOCRText.isEmpty ? "无" : card.rawOCRText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DetailRow(title: "创建时间", value: Self.dateFormatter.string(from: card.createdAt))
            }
        }
    }

    private func exportVCF() {
        guard let card else { return }
        do {
            let url = try VCFService.temporaryFileURL(for: [card])
            shareItems = [url]
            showShareSheet = true
        } catch {
            store.lastErrorMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        openURL(url)
    }

    private func dialable(_ number: String) -> String {
        number.filter { $0.isNumber || $0 == "+" }
    }

    private func websiteURL(_ website: String) -> String {
        if website.hasPrefix("http://") || website.hasPrefix("https://") {
            return website
        }
        return "https://\(website)"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        if !value.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
            }
        }
    }
}

struct WrappingTags: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                }
            }
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

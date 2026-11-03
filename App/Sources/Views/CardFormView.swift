import SwiftUI
import CardCore

struct CardFormView: View {
    enum Mode {
        case create
        case edit

        var title: String {
            switch self {
            case .create: return "确认名片信息"
            case .edit: return "编辑名片"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var draft: CardDraft

    private let mode: Mode
    private let onSave: (CardDraft) -> Void

    init(mode: Mode, initialDraft: CardDraft, onSave: @escaping (CardDraft) -> Void) {
        self.mode = mode
        self.onSave = onSave
        _draft = State(initialValue: initialDraft)
    }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("姓名", text: $draft.name)
                TextField("公司", text: $draft.company)
                TextField("职位", text: $draft.jobTitle)
            }
            Section("电话（每行一个）") {
                TextField("手机", text: $draft.mobiles, axis: .vertical)
                TextField("办公电话", text: $draft.phones, axis: .vertical)
                TextField("传真", text: $draft.faxes, axis: .vertical)
            }
            Section("联系方式") {
                TextField("邮箱（每行一个）", text: $draft.emails, axis: .vertical)
                TextField("网站", text: $draft.website)
                TextField("地址", text: $draft.address, axis: .vertical)
            }
            Section("标签与备注") {
                TextField("标签（逗号分隔）", text: $draft.tags)
                TextField("备注", text: $draft.notes, axis: .vertical)
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    onSave(draft)
                    dismiss()
                }
            }
        }
    }
}

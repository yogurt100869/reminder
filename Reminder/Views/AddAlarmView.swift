import SwiftData
import SwiftUI

struct AddAlarmView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var fireDate = Calendar.current.date(
        byAdding: .hour,
        value: 1,
        to: .now
    ) ?? .now.addingTimeInterval(3_600)
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("闹钟") {
                    TextField("标签（例如：开会）", text: $title)
                    DatePicker(
                        "时间",
                        selection: $fireDate,
                        in: Date().addingTimeInterval(1)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                }

                Section {
                    Label(
                        "闹钟通过 iOS 通知播放提示音，请确保系统通知和声音已开启。",
                        systemImage: "speaker.wave.2"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("新建闹钟")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(isSaving || !AlarmDateValidator.isValid(fireDate))
                }
            }
            .interactiveDismissDisabled(isSaving)
            .alert(
                "无法创建闹钟",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    @MainActor
    private func save() async {
        guard AlarmDateValidator.isValid(fireDate) else {
            errorMessage = AlarmSchedulingError.dateIsNotInFuture.localizedDescription
            return
        }

        isSaving = true
        let alarm = Alarm(
            title: normalizedTitle,
            fireDate: fireDate
        )

        do {
            try await AlarmScheduler.shared.ensureAuthorization()
            try await AlarmScheduler.shared.schedule(alarm)
            modelContext.insert(alarm)
            do {
                try modelContext.save()
            } catch {
                AlarmScheduler.shared.cancel(alarm)
                modelContext.delete(alarm)
                throw error
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }

    private var normalizedTitle: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? "提醒" : trimmedTitle
    }
}

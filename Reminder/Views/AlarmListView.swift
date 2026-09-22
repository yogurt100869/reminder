import SwiftData
import SwiftUI
import UserNotifications

struct AlarmListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Alarm.fireDate) private var alarms: [Alarm]

    @State private var isPresentingAddAlarm = false
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if alarms.isEmpty {
                    ContentUnavailableView(
                        "还没有闹钟",
                        systemImage: "alarm",
                        description: Text("点击右上角的加号，设置任意未来日期和时间。")
                    )
                } else {
                    List {
                        permissionSection

                        ForEach(alarms) { alarm in
                            AlarmRow(alarm: alarm)
                        }
                        .onDelete(perform: deleteAlarms)
                    }
                }
            }
            .navigationTitle("闹钟")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddAlarm = true
                    } label: {
                        Label("新建闹钟", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddAlarm, onDismiss: refreshAuthorizationStatus) {
                AddAlarmView()
            }
            .task {
                await refreshAuthorizationStatus()
            }
            .alert(
                "操作失败",
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
        .tint(.orange)
    }

    @ViewBuilder
    private var permissionSection: some View {
        if authorizationStatus == .denied {
            Section {
                Label("通知权限已关闭，新闹钟无法发出提醒。请在系统设置中开启通知。", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    private func deleteAlarms(at offsets: IndexSet) {
        let alarmsToDelete = offsets.map { alarms[$0] }

        do {
            for alarm in alarmsToDelete {
                modelContext.delete(alarm)
            }
            try modelContext.save()
            for alarm in alarmsToDelete {
                AlarmScheduler.shared.cancel(alarm)
            }
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func refreshAuthorizationStatus() {
        Task {
            authorizationStatus = await AlarmScheduler.shared.authorizationStatus()
        }
    }
}

private struct AlarmRow: View {
    let alarm: Alarm

    private var isElapsed: Bool {
        alarm.fireDate <= .now
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isElapsed ? "alarm.waves.left.and.right.fill" : "alarm.fill")
                .font(.title2)
                .foregroundStyle(isElapsed ? .secondary : .orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.fireDate, format: .dateTime.month().day().weekday(.abbreviated))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(alarm.fireDate, format: .dateTime.hour().minute())
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                Text(alarm.title)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            Spacer()

            if isElapsed {
                Text("已结束")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var statusManager: StatusManager

    private static let timeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Claude Status")
                    .font(.headline)
                Spacer()
                if statusManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                }
                Button {
                    Task { await statusManager.fetch() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if let error = statusManager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            Divider()

            if statusManager.items.isEmpty && !statusManager.isLoading {
                Text("No status updates available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(12)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(statusManager.items.prefix(10)) { item in
                            statusRow(item)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 400)
            }

            Divider()

            // Footer
            HStack {
                if let lastUpdated = statusManager.lastUpdated {
                    Text("Updated \(Self.timeFormatter.localizedString(for: lastUpdated, relativeTo: Date()))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Open Status Page") {
                    if let url = URL(string: "https://status.claude.com") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 380)
    }

    private func statusRow(_ item: StatusItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: item.status.icon)
                    .foregroundColor(item.status.color)
                    .font(.body)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(item.status.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(item.status.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(item.status.color.opacity(0.15))
                            .cornerRadius(4)

                        Text(Self.dateFormatter.string(from: item.pubDate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if let link = item.link {
                NSWorkspace.shared.open(link)
            }
        }
    }
}

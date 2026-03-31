import Foundation
import SwiftUI

struct StatusItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let pubDate: Date
    let link: URL?
    let status: IncidentStatus
}

enum IncidentStatus: String {
    case resolved = "Resolved"
    case monitoring = "Monitoring"
    case identified = "Identified"
    case investigating = "Investigating"
    case update = "Update"
    case unknown = "Unknown"

    var color: Color {
        switch self {
        case .resolved: return .green
        case .monitoring: return .blue
        case .identified: return .orange
        case .investigating: return .red
        case .update: return .yellow
        case .unknown: return .gray
        }
    }

    var icon: String {
        switch self {
        case .resolved: return "checkmark.circle.fill"
        case .monitoring: return "eye.circle.fill"
        case .identified: return "exclamationmark.triangle.fill"
        case .investigating: return "magnifyingglass.circle.fill"
        case .update: return "info.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

@MainActor
class StatusManager: ObservableObject {
    @Published var items: [StatusItem] = []
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var timer: Timer?
    private static let refreshInterval: TimeInterval = 180 // 3 minutes

    var hasOngoingIncident: Bool {
        items.contains { $0.status != .resolved }
    }

    var menuBarTitle: String {
        return "Claude Status"
    }

    var statusNSColor: NSColor {
        if items.isEmpty { return .gray }
        return hasOngoingIncident ? .orange : .systemGreen
    }

    init() {
        Task {
            await fetch()
        }
        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetch()
            }
        }
    }

    func fetch() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let url = URL(string: "https://status.claude.com/history.rss") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let parser = RSSParser(data: data)
            items = parser.parse()
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - RSS Parser

class RSSParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var items: [StatusItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentLink = ""
    private var currentGuid = ""
    private var isInsideItem = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f
    }()

    init(data: Data) {
        self.data = data
    }

    func parse() -> [StatusItem] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            isInsideItem = true
            currentTitle = ""
            currentDescription = ""
            currentPubDate = ""
            currentLink = ""
            currentGuid = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInsideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "description": currentDescription += string
        case "pubDate": currentPubDate += string
        case "link": currentLink += string
        case "guid": currentGuid += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {
        guard elementName == "item" else { return }
        isInsideItem = false

        let status = Self.extractStatus(from: currentDescription)
        let date = Self.dateFormatter.date(from: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Date()

        let item = StatusItem(
            id: currentGuid.trimmingCharacters(in: .whitespacesAndNewlines),
            title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: Self.cleanHTML(currentDescription),
            pubDate: date,
            link: URL(string: currentLink.trimmingCharacters(in: .whitespacesAndNewlines)),
            status: status
        )
        items.append(item)
    }

    private static func extractStatus(from html: String) -> IncidentStatus {
        let lowered = html.lowercased()
        if lowered.contains("<strong>resolved</strong>") { return .resolved }
        if lowered.contains("<strong>monitoring</strong>") { return .monitoring }
        if lowered.contains("<strong>identified</strong>") { return .identified }
        if lowered.contains("<strong>investigating</strong>") { return .investigating }
        if lowered.contains("<strong>update</strong>") { return .update }
        return .unknown
    }

    private static func cleanHTML(_ html: String) -> String {
        // Decode HTML entities first
        guard let data = html.data(using: .utf8),
              let decoded = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
              ) else {
            // Fallback: strip tags with regex
            return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                       .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return decoded.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

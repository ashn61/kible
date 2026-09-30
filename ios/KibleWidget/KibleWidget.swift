import SwiftUI
import WidgetKit

// MARK: - Veri (Flutter tarafı: lib/services/widget_service.dart)

private let appGroupId = "group.com.kible.kible"

struct KibleDay: Decodable {
    let d: String       // yyyy-MM-dd
    let h: String       // hicri tarih
    let t: [Double]     // epoch ms × 6
    let l: [String]     // "04:45" × 6
}

struct KiblePayload: Decodable {
    let location: String
    let names: [String]
    let days: [KibleDay]

    static func load() -> KiblePayload? {
        guard let raw = UserDefaults(suiteName: appGroupId)?.string(forKey: "kible_data"),
              let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(KiblePayload.self, from: data)
    }

    /// Tüm vakitler (tarih sırasıyla).
    var moments: [(name: String, label: String, date: Date)] {
        days.flatMap { day in
            day.t.indices.map { i in
                (names[safe: i] ?? "", day.l[safe: i] ?? "", Date(timeIntervalSince1970: day.t[i] / 1000))
            }
        }
    }

    func today(at date: Date) -> KibleDay? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        let key = f.string(from: date)
        return days.first { $0.d == key }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}

// MARK: - Timeline

struct KibleEntry: TimelineEntry {
    let date: Date
    let location: String
    let hijri: String
    let nextName: String?
    let nextLabel: String?
    let nextDate: Date?
    let names: [String]
    let labels: [String]
    let currentIndex: Int

    static let placeholder = KibleEntry(
        date: .now, location: "Trabzon", hijri: "19 Rebiülahir 1448",
        nextName: "İkindi", nextLabel: "15:35", nextDate: .now.addingTimeInterval(5400),
        names: ["İmsak", "Güneş", "Öğle", "İkindi", "Akşam", "Yatsı"],
        labels: ["04:45", "06:09", "12:16", "15:35", "18:13", "19:32"], currentIndex: 2
    )

    static func make(at date: Date, payload: KiblePayload?) -> KibleEntry {
        guard let payload else {
            return KibleEntry(date: date, location: "Kıble", hijri: "", nextName: nil, nextLabel: nil,
                              nextDate: nil, names: [], labels: [], currentIndex: -1)
        }
        let next = payload.moments.first { $0.date > date }
        let today = payload.today(at: date)
        let current = today?.t.lastIndex { Date(timeIntervalSince1970: $0 / 1000) <= date } ?? -1
        return KibleEntry(
            date: date, location: payload.location, hijri: today?.h ?? "",
            nextName: next?.name, nextLabel: next?.label, nextDate: next?.date,
            names: payload.names, labels: today?.l ?? [], currentIndex: current
        )
    }
}

struct KibleProvider: TimelineProvider {
    func placeholder(in context: Context) -> KibleEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (KibleEntry) -> Void) {
        completion(context.isPreview ? .placeholder : KibleEntry.make(at: .now, payload: KiblePayload.load()))
    }

    /// Şimdi + önümüzdeki her vakit girişi için bir kayıt; geri sayım
    /// `Text(date, style: .timer)` ile sistem tarafından canlı güncellenir.
    func getTimeline(in context: Context, completion: @escaping (Timeline<KibleEntry>) -> Void) {
        let payload = KiblePayload.load()
        let now = Date.now
        var dates = [now]
        if let payload {
            dates += payload.moments.map(\.date).filter { $0 > now }.prefix(24)
            // Gece yarısı: bugünün listesi değişsin.
            if let midnight = Calendar.current.nextDate(after: now, matching: DateComponents(hour: 0),
                                                        matchingPolicy: .nextTime) {
                dates.append(midnight)
            }
        }
        let entries = dates.sorted().map { KibleEntry.make(at: $0, payload: payload) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Görünümler

private let navy = Color(red: 11 / 255, green: 45 / 255, blue: 59 / 255)
private let teal = Color(red: 14 / 255, green: 90 / 255, blue: 95 / 255)
private let gold = Color(red: 212 / 255, green: 175 / 255, blue: 55 / 255)
private let beige = Color(red: 247 / 255, green: 245 / 255, blue: 239 / 255)

struct KibleWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: KibleEntry

    var body: some View {
        switch family {
        case .accessoryInline: inline
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .systemSmall: small
        default: medium
        }
    }

    // Kilit ekranı
    @ViewBuilder
    private var inline: some View {
        if let name = entry.nextName, let date = entry.nextDate {
            Text("\(name) \(date, style: .timer)")
        } else {
            Text("Kıble")
        }
    }

    private var circular: some View {
        VStack(spacing: 0) {
            Image(systemName: "moon.stars.fill").font(.caption2)
            Text(entry.nextLabel ?? "--:--").font(.system(.caption, design: .rounded)).bold()
        }
        .containerBackground(for: .widget) { AccessoryWidgetBackground() }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.nextName.map { "\($0) · \(entry.nextLabel ?? "")" } ?? "Kıble").font(.headline)
            if let date = entry.nextDate {
                Text(date, style: .timer).font(.system(.title3, design: .rounded)).monospacedDigit()
            }
            Text(entry.location).font(.caption2).opacity(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }

    // Ana ekran / Bugün görünümü
    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(entry.location, systemImage: "location.fill")
                .font(.caption).foregroundStyle(beige).labelStyle(PinLabelStyle())
            Spacer(minLength: 0)
            Text(entry.nextName.map { "\($0) · \(entry.nextLabel ?? "")" } ?? "Uygulamayı açın")
                .font(.subheadline).foregroundStyle(beige.opacity(0.85))
            if let date = entry.nextDate {
                Text(date, style: .timer)
                    .font(.system(size: 30, weight: .light, design: .rounded))
                    .monospacedDigit().foregroundStyle(gold).minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { background }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(entry.location, systemImage: "location.fill")
                    .font(.subheadline.bold()).foregroundStyle(beige).labelStyle(PinLabelStyle())
                Spacer()
                Text(entry.hijri).font(.caption2).foregroundStyle(beige.opacity(0.65))
            }
            HStack(alignment: .firstTextBaseline) {
                Text(entry.nextName.map { "\($0) · \(entry.nextLabel ?? "")" } ?? "Uygulamayı açın")
                    .font(.subheadline).foregroundStyle(beige.opacity(0.85))
                Spacer()
                if let date = entry.nextDate {
                    Text(date, style: .timer)
                        .font(.system(size: 28, weight: .light, design: .rounded))
                        .monospacedDigit().foregroundStyle(gold).multilineTextAlignment(.trailing)
                }
            }
            HStack(spacing: 4) {
                ForEach(entry.names.indices, id: \.self) { i in
                    let active = i == entry.currentIndex
                    VStack(spacing: 2) {
                        Text(entry.names[i]).font(.system(size: 10))
                            .foregroundStyle(active ? navy : beige.opacity(0.65))
                        Text(entry.labels[safe: i] ?? "--:--").font(.system(size: 13, weight: .bold))
                            .foregroundStyle(active ? navy : beige)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(active ? gold : .clear, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .containerBackground(for: .widget) { background }
    }

    private var background: some View {
        LinearGradient(colors: [teal, navy], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct PinLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.foregroundStyle(gold).font(.caption2)
            configuration.title.lineLimit(1)
        }
    }
}

// MARK: - Widget

struct KibleWidget: Widget {
    let kind = "KibleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KibleProvider()) { entry in
            KibleWidgetView(entry: entry)
        }
        .configurationDisplayName("Kıble")
        .description("Sıradaki namaz vakti ve geri sayım.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryInline, .accessoryCircular, .accessoryRectangular,
        ])
    }
}

@main
struct KibleWidgetBundle: WidgetBundle {
    var body: some Widget { KibleWidget() }
}

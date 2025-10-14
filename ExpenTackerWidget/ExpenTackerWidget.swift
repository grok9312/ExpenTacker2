//
//  ExpenTackerWidget.swift
//  ExpenTackerWidget
//
//  Created by 張郁眉 on 2025/10/13.
//

import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let totalExpense: Double
}

struct ExpenseRecordWidget: Codable {
    let amount: Double
    let date: Date
    let type: String // "expense" or "income"
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), totalExpense: 0)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let total = Self.fetchTodayExpenseTotal()
        return SimpleEntry(date: Date(), configuration: configuration, totalExpense: total)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let total = Self.fetchTodayExpenseTotal()
            let entry = SimpleEntry(date: entryDate, configuration: configuration, totalExpense: total)
            entries.append(entry)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
    
    static func fetchTodayExpenseTotal() -> Double {
        let groupID = "group.com.YuMei.expentacker2" // unified App Group ID
        let userDefaults = UserDefaults(suiteName: groupID)
        guard let data = userDefaults?.data(forKey: "expenses") else { return 0 }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let records = try? decoder.decode([ExpenseRecordWidget].self, from: data) else { return 0 }
        // Compare with current date to avoid timezone pitfalls
        let now = Date()
        return records.filter { $0.type == "expense" && Calendar.current.isDate($0.date, inSameDayAs: now) }
            .reduce(0) { $0 + $1.amount }
    }
}

struct ExpenTackerWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("今日支出")
                .font(.headline)
            Text("$\(Int(entry.totalExpense))")
                .font(.largeTitle)
                .foregroundColor(.red)
        }
        .padding()
    }
}

struct ExpenTackerWidget: Widget {
    let kind: String = "ExpenTackerWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            ExpenTackerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    ExpenTackerWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley, totalExpense: 0)
    SimpleEntry(date: .now, configuration: .starEyes, totalExpense: 0)
}

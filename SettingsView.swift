import SwiftUI

// Define your sort options as an iterable enum
enum SortPreference: String, CaseIterable, Identifiable {
    case alphabeticalAZ = "Alphabetical (A-Z)"
    case alphabeticalZA = "Alphabetical (Z-A)"
    case alphabeticalNumbersBack = "Alphabetical (Numbers in Back)"
    case groupByContention = "Group by Contention"
    var id: Self { self }
}

struct DeScriptSettingsView: View {
    // Utilize AppStorage to automatically persist the setting natively
    @AppStorage("ledgerSortPreference") private var sortPreference: SortPreference = .alphabeticalNumbersBack
    
    var body: some View {
        Form {
            Picker("Sort Ledger By:", selection: $sortPreference) {
                ForEach(SortPreference.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
           .pickerStyle(.radioGroup)
            
            // Native alignment for descriptive footnote text
            Text("Grouping by contention pushes unassigned\nbinaries to the bottom.")
               .font(.system(size: 11, weight:.regular))
               .foregroundStyle(.secondary)
                // Align the text with the radio buttons, bypassing the picker label
               .alignmentGuide(.leading) { dimensions in
                    dimensions[.leading]
                }
               .padding(.top, 4)
        }
       .padding(20)
       .frame(width: 380)
        // Ensure the background remains an opaque standard material for readability
       .background(Color(NSColor.windowBackgroundColor))
    }
}

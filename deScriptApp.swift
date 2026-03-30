import SwiftUI

enum SortOption: String, CaseIterable, Identifiable {
    case aToZ = "Alphabetical (A-Z)"
    case zToA = "Alphabetical (Z-A)"
    case numbersLast = "Alphabetical (Numbers in Back)"
    case contention = "Group by Contention"
    
    var id: String { self.rawValue }
}

struct SettingsView: View {
    @AppStorage("ledgerSortOption") private var sortOption: SortOption = .aToZ
    
    var body: some View {
        Form {
            Picker("Sort Ledger By:", selection: $sortOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.radioGroup)
            .padding(.bottom, 10)
            
            Text("Grouping by contention pushes unassigned binaries to the bottom.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(width: 400, height: 200)
        .navigationTitle("deScript Settings")
    }
}

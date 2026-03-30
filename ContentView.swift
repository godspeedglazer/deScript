import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var ledger = LedgerManager()
    @State private var searchText = ""
    @State private var selectedAppID: String?
    
    // Reads your chosen setting from the native macOS preferences
    @AppStorage("ledgerSortOption") private var sortOption: SortOption = .aToZ
    
    // The upgraded dynamic sorting and filtering engine
    var filteredApps: [AppEntry] {
        var result = ledger.apps
        
        // 1. Apply Search Filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.contention.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleID.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 2. Apply the chosen Sort Option
        result.sort { a, b in
            switch sortOption {
            case .aToZ:
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                
            case .zToA:
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedDescending
                
            case .numbersLast:
                let aIsDigit = a.name.first?.isNumber ?? false
                let bIsDigit = b.name.first?.isNumber ?? false
                if aIsDigit && !bIsDigit { return false }
                if !aIsDigit && bIsDigit { return true }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                
            case .contention:
                if a.contention == b.contention {
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                }
                if a.contention.isEmpty { return false }
                if b.contention.isEmpty { return true }
                return a.contention.localizedCaseInsensitiveCompare(b.contention) == .orderedAscending
            }
        }
        
        return result
    }
    
    var selectedAppBinding: Binding<AppEntry>? {
        guard let id = selectedAppID, let index = ledger.apps.firstIndex(where: { $0.id == id }) else { return nil }
        return $ledger.apps[index]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // LEFT COLUMN: Sidebar
            VStack(spacing: 0) {
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search Ledger", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .regular))
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
                .padding(16)
                
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredApps) { app in
                            HStack(spacing: 12) {
                                if let icon = ledger.cachedIcons[app.bundleID] {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name)
                                        .font(.system(size: 13, weight: selectedAppID == app.id ? .semibold : .regular))
                                        .foregroundStyle(selectedAppID == app.id ? .white : .primary)
                                    
                                    if !app.contention.isEmpty {
                                        Text(app.contention)
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(selectedAppID == app.id ? .white : .blue)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(selectedAppID == app.id ? Color.accentColor : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedAppID = app.id
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                }
            }
            .frame(width: 260)
            .background(.regularMaterial)
            
            Divider()
            
            // RIGHT COLUMN: Detail Pane
            ZStack {
                Color(NSColor.windowBackgroundColor)
                
                if let binding = selectedAppBinding {
                    DetailHIGView(app: binding, icon: ledger.cachedIcons[binding.wrappedValue.bundleID], onSave: {
                        ledger.saveLedger()
                    })
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text("No Binary Selected")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(WindowChromeAssassination())
        .ignoresSafeArea()
    }
}

// MARK: - Subviews & Modifiers

struct DetailHIGView: View {
    @Binding var app: AppEntry
    var icon: NSImage?
    var onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // HEADER
            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    if let icon = icon {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.quaternary)
                            .frame(width: 64, height: 64)
                    }
                }
                .frame(width: 64, height: 64)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text(app.bundleID)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    TextField("Assign Contention", text: $app.contention)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, 2)
                        .onChange(of: app.contention) { onSave() }
                }
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 24)
            
            Divider().padding(.horizontal, 32)
            
            // BODY
            TextEditor(text: $app.notes)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.primary)
                .lineSpacing(6)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 32)
                .onChange(of: app.notes) { onSave() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

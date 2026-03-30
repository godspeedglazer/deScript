import SwiftUI
import AppKit
import Foundation
import Combine

struct AppEntry: Identifiable, Codable, Hashable {
    var id: String { bundleID }
    let name: String
    let bundleID: String
    let path: String
    var contention: String
    var notes: String
}

class LedgerManager: ObservableObject {
    @Published var apps: [AppEntry] = []
    @Published var cachedIcons: [String: NSImage] = [:]
    
    private let fm = FileManager.default
    private let ledgerURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("DeScriptLedger.json")
    
    init() {
        loadLedger()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.scanApplications()
        }
    }
    
    func scanApplications() {
        let searchPaths = ["/Applications", "/System/Applications", NSHomeDirectory() + "/Applications"]
        var discoveredApps: [AppEntry] = []
        var newIcons: [String: NSImage] = [:]
        
        let currentIDs = Set(self.apps.map { $0.bundleID })
        
        for path in searchPaths {
            guard let contents = try? fm.contentsOfDirectory(atPath: path) else { continue }
            
            for item in contents where item.hasSuffix(".app") {
                let fullPath = path + "/" + item
                let bundle = Bundle(path: fullPath)
                let name = item.replacingOccurrences(of: ".app", with: "")
                let bundleID = bundle?.bundleIdentifier ?? name
                
                let icon = NSWorkspace.shared.icon(forFile: fullPath)
                newIcons[bundleID] = icon
                
                if !currentIDs.contains(bundleID) {
                    // New defaults applied here
                    discoveredApps.append(AppEntry(name: name, bundleID: bundleID, path: fullPath, contention: "", notes: "deScript(ion)..."))
                }
            }
        }
        
        DispatchQueue.main.async {
            self.cachedIcons.merge(newIcons) { (current, _) in current }
            if !discoveredApps.isEmpty {
                self.apps.append(contentsOf: discoveredApps)
            }
            
            // THE FIX: Force a strict, case-insensitive master sort on the entire ledger
            self.apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            self.saveLedger()
        }
    }
    
    func saveLedger() {
        if let data = try? JSONEncoder().encode(apps) {
            try? data.write(to: ledgerURL)
        }
    }
    
    func loadLedger() {
        if let data = try? Data(contentsOf: ledgerURL),
           let saved = try? JSONDecoder().decode([AppEntry].self, from: data) {
            
            // Migration: Automatically cleans up the old "UNASSIGNED" string from your JSON
            self.apps = saved.map { entry in
                var updated = entry
                if updated.contention == "UNASSIGNED" { updated.contention = "" }
                if updated.notes == "Awaiting logical justification..." { updated.notes = "deScript(ion)..." }
                return updated
            }
            // Master sort on load as well
            self.apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
    
    func updateEntry(_ entry: AppEntry) {
        if let idx = apps.firstIndex(where: { $0.bundleID == entry.bundleID }) {
            apps[idx] = entry
            self.apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } // Keep sorted on edit
            saveLedger()
        }
    }
}

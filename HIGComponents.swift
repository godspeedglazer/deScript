import SwiftUI
import AppKit

// MARK: - AppKit Hook to Nuke Window Chrome
struct WindowChromeAssassination: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                
                // Kill the traffic lights
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
                
                // Allow the user to drag the window from anywhere on the background
                window.isMovableByWindowBackground = true
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Native HIG Material Modifier
struct HIGPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            // Uses Apple's native visual effect view for accurate desktop refraction
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}

extension View {
    func nativeHIGPanel() -> some View {
        self.modifier(HIGPanel())
    }
}

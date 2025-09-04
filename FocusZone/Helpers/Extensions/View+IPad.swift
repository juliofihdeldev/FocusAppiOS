import SwiftUI

// MARK: - iPad Layout Extensions
extension View {
    /// Applies iPad-specific layout modifications
    func iPadLayout() -> some View {
        self
            .modifier(IPadLayoutModifier())
    }
    
    /// Applies responsive padding based on device type
    func responsivePadding(_ edges: Edge.Set = .all, _ length: CGFloat = 16) -> some View {
        self
            .padding(edges, isIPad ? length * 1.5 : length)
    }
    
    /// Applies responsive font size
    func responsiveFont(_ style: Font.TextStyle) -> some View {
        self
            .font(.system(style))
    }
    
    /// Applies responsive spacing
    func responsiveSpacing(_ spacing: CGFloat) -> some View {
        self
            .padding(.vertical, isIPad ? spacing * 1.2 : spacing)
    }
}

// MARK: - Device Detection
private var isIPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}

// MARK: - iPad Layout Modifier
struct IPadLayoutModifier: ViewModifier {
    func body(content: Content) -> some View {
        if isIPad {
            content
                .frame(maxWidth: 1200) // Limit max width on very large screens
                .padding(.horizontal, 40) // More generous padding on iPad
        } else {
            content
        }
    }
}

// MARK: - Font Extensions for iPad
extension Font.TextStyle {
    var larger: Font {
        switch self {
        case .largeTitle:
            return .largeTitle
        case .title:
            return .title
        case .title2:
            return .title
        case .title3:
            return .title2
        case .headline:
            return .title3
        case .body:
            return .headline
        case .callout:
            return .body
        case .subheadline:
            return .callout
        case .footnote:
            return .subheadline
        case .caption:
            return .footnote
        case .caption2:
            return .caption
        @unknown default:
            return .body
        }
    }
}

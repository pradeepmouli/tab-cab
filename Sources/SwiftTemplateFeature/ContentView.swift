import SwiftUI

public struct ContentView: View {
    public var body: some View {
        VStack(spacing: 20) {
            Text("SwiftTemplate")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("A modern Swift template")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    public init() {}
}

#Preview {
    ContentView()
}

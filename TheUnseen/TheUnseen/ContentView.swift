import SwiftUI

struct ContentView: View {
    @State private var showTestMenu = false
    
    var body: some View {
        NavigationView {
            ChatView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        #if DEBUG
                        Button(action: {
                            showTestMenu = true
                        }) {
                            Image(systemName: "hammer.circle")
                                .foregroundColor(.blue)
                        }
                        #endif
                    }
                }
                .sheet(isPresented: $showTestMenu) {
                    TestMenuView()
                }
        }
    }
}

#Preview {
    ContentView()
}

import SwiftUI

struct TestMenuView: View {
    @State private var showP2PTests = false
    @State private var showFirebaseTests = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Development Test Suite")
                    .font(.largeTitle)
                    .padding()
                
                Text("Run tests to verify system components")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Divider()
                
                // P2P Tests
                Button(action: {
                    showP2PTests = true
                }) {
                    HStack {
                        Image(systemName: "network")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("P2P Connectivity Tests")
                                .font(.headline)
                            Text("Test connection, handshake, and messaging")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .sheet(isPresented: $showP2PTests) {
                    P2PTestView()
                }
                
                // Firebase Tests
                Button(action: {
                    showFirebaseTests = true
                }) {
                    HStack {
                        Image(systemName: "flame")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Firebase Tests")
                                .font(.headline)
                            Text("Test auth, Firestore, and ANIMA")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }
                .sheet(isPresented: $showFirebaseTests) {
                    FirebaseTestView()
                }
                
                Divider()
                
                // Test Status Summary
                VStack(alignment: .leading, spacing: 10) {
                    Text("Test Coverage")
                        .font(.headline)
                    
                    TestStatusRow(component: "P2P Discovery", status: .implemented)
                    TestStatusRow(component: "Encryption", status: .implemented)
                    TestStatusRow(component: "Firebase Auth", status: .implemented)
                    TestStatusRow(component: "Biometric Auth", status: .implemented)
                    TestStatusRow(component: "ANIMA System", status: .implemented)
                    TestStatusRow(component: "Cloud Functions", status: .notImplemented)
                    TestStatusRow(component: "Block/Report", status: .notImplemented)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct TestStatusRow: View {
    let component: String
    let status: TestStatus
    
    enum TestStatus {
        case implemented
        case partial
        case notImplemented
        
        var color: Color {
            switch self {
            case .implemented: return .green
            case .partial: return .orange
            case .notImplemented: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .implemented: return "checkmark.circle.fill"
            case .partial: return "exclamationmark.circle.fill"
            case .notImplemented: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
            Text(component)
                .font(.caption)
            Spacer()
        }
    }
}

#Preview {
    TestMenuView()
}
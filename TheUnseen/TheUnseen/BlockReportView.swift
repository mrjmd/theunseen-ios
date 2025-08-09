import SwiftUI

struct BlockReportView: View {
    @Environment(\.dismiss) var dismiss
    let partnerName: String?
    let partnerUID: String
    let sessionId: String?
    let onBlock: (Bool) -> Void // Callback with whether report was included
    
    @State private var selectedReason: ReportReason?
    @State private var additionalContext = ""
    @State private var showingConfirmation = false
    @State private var isBlocking = false
    
    enum ReportReason: String, CaseIterable {
        case harassment = "Harassment or bullying"
        case hateSpeed = "Hate speech or discrimination"
        case inappropriate = "Inappropriate or sexual content"
        case spam = "Spam or commercial activity"
        case impersonation = "Impersonation or false identity"
        case violence = "Threats or violence"
        case other = "Other concerning behavior"
        
        var icon: String {
            switch self {
            case .harassment: return "exclamationmark.bubble"
            case .hateSpeed: return "exclamationmark.triangle"
            case .inappropriate: return "eye.slash"
            case .spam: return "envelope.badge.shield.half.filled"
            case .impersonation: return "person.crop.circle.badge.xmark"
            case .violence: return "hand.raised"
            case .other: return "flag"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                            .symbolEffect(.pulse)
                        
                        Text("Safety Options")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Your safety is our priority")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Quick Block Option
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Block This Initiate", systemImage: "hand.raised.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("You will never be matched with this person again.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            blockUser(withReport: false)
                        }) {
                            Text("Block Only")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(12)
                        }
                        .disabled(isBlocking)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // Report Option
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Block and Report", systemImage: "flag.fill")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text("Block this person and submit a report for Shadow Council review.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        // Reason Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select a reason:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(ReportReason.allCases, id: \.self) { reason in
                                Button(action: {
                                    selectedReason = reason
                                }) {
                                    HStack {
                                        Image(systemName: reason.icon)
                                            .frame(width: 24)
                                        Text(reason.rawValue)
                                            .font(.caption)
                                        Spacer()
                                        if selectedReason == reason {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .foregroundColor(selectedReason == reason ? .red : .primary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedReason == reason ? 
                                                  Color.red.opacity(0.1) : 
                                                  Color(UIColor.tertiarySystemBackground))
                                    )
                                }
                            }
                        }
                        
                        // Additional Context
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional context (optional):")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextEditor(text: $additionalContext)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            blockUser(withReport: true)
                        }) {
                            Text("Block and Report")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedReason != nil ? Color.red : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(selectedReason == nil || isBlocking)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // Info text
                    Text("All reports are reviewed by the Shadow Council to maintain a safe community. False reports may result in account restrictions.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("User Blocked", isPresented: $showingConfirmation) {
                Button("Return to Path") {
                    dismiss()
                    onBlock(selectedReason != nil)
                }
            } message: {
                if selectedReason != nil {
                    Text("This person has been blocked and your report has been submitted for review. You will never be matched with them again.")
                } else {
                    Text("This person has been blocked. You will never be matched with them again.")
                }
            }
        }
    }
    
    private func blockUser(withReport: Bool) {
        isBlocking = true
        
        let firestoreService = FirestoreService()
        
        if withReport, let reason = selectedReason {
            firestoreService.blockUser(
                partnerUID,
                reason: reason.rawValue,
                context: additionalContext.isEmpty ? nil : additionalContext,
                sessionId: sessionId
            )
        } else {
            firestoreService.blockUser(partnerUID)
        }
        
        // Show confirmation after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingConfirmation = true
        }
    }
}

#Preview {
    BlockReportView(
        partnerName: "Anonymous",
        partnerUID: "test-uid",
        sessionId: "test-session",
        onBlock: { _ in }
    )
}
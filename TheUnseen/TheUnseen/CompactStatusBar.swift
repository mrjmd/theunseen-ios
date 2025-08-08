import SwiftUI

struct CompactStatusBar: View {
    let currentAct: Int
    let isMeaningful: Bool
    
    private let acts = [
        (1, "Opening"),
        (2, "Turn"), 
        (3, "Deepening")
    ]
    
    var body: some View {
        HStack(spacing: 16) {
            // Act progression dots
            ForEach(acts, id: \.0) { act, name in
                VStack(spacing: 3) {
                    Circle()
                        .fill(currentAct >= act ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                    
                    Text(name)
                        .font(.system(size: 9))
                        .foregroundColor(currentAct == act ? .purple : .gray)
                }
            }
            
            Spacer()
            
            // Field status - minimal text
            if isMeaningful {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                    Text("Field Stabilized")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                }
            } else {
                Text("Field Strengthening...")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(UIColor.secondarySystemBackground).opacity(0.6))
        .cornerRadius(8)
    }
}

#Preview {
    VStack {
        CompactStatusBar(currentAct: 1, isMeaningful: false)
        CompactStatusBar(currentAct: 2, isMeaningful: false)
        CompactStatusBar(currentAct: 3, isMeaningful: true)
    }
    .padding()
}
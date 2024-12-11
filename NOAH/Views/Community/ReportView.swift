import SwiftUI

struct ReportView: View {
    let contentId: String
    let contentType: String
    @StateObject private var viewModel = CommunityViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var reason = ""
    @State private var description = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let reportReasons = [
        "Harassment or Bullying",
        "Hate Speech",
        "Inappropriate Content",
        "Spam",
        "Misinformation",
        "Personal Information",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reason for Report")) {
                    Picker("Reason", selection: $reason) {
                        ForEach(reportReasons, id: \.self) { reason in
                            Text(reason).tag(reason)
                        }
                    }
                }
                
                Section(header: Text("Additional Information")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section(footer: Text("Your report will be reviewed by moderators")) {
                    Button(action: submitReport) {
                        Text("Submit Report")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(isValid ? Color.red : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Report Submitted", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isValid: Bool {
        !reason.isEmpty && !description.isEmpty
    }
    
    private func submitReport() {
        Task {
            await viewModel.reportContent(
                targetId: contentId,
                targetType: contentType,
                reason: reason,
                description: description
            )
            alertMessage = "Thank you for helping keep our community safe. A moderator will review your report."
            showingAlert = true
        }
    }
}

#Preview {
    ReportView(contentId: "test-post", contentType: "post")
}

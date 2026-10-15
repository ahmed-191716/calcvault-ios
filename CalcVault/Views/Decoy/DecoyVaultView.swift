import SwiftUI

/// الواجهة التمويهية (Decoy Vault): تفتح فقط عند إدخال رمز الإكراه/الطوارئ
/// تظهر كأنها تطبيق ملاحظات وتسوق عادي جداً وبدائي، لتبديد أي شكوك لمن يفتش الهاتف بالقوة
public struct DecoyVaultView: View {
    @ObservedObject private var store = LocalVaultStore.shared
    @ObservedObject private var auth = AuthManager.shared
    
    @State private var showAdd = false
    @State private var title = ""
    @State private var content = ""
    @State private var selectedDecoy: SecretNote?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            List {
                Section(header: Text("ملاحظاتي اليومية")) {
                    ForEach(store.decoyNotes) { note in
                        Button(action: {
                            selectedDecoy = note
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(note.content)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete { indexSet in
                        store.deleteDecoyNote(at: indexSet)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("الملاحظات")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("خروج") {
                        auth.lock()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                NavigationView {
                    Form {
                        TextField("العنوان", text: $title)
                        TextEditor(text: $content)
                            .frame(minHeight: 140)
                    }
                    .navigationTitle("ملاحظة جديدة")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("إلغاء") { showAdd = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("إضافة") {
                                if !title.isEmpty {
                                    store.addDecoyNote(title: title, content: content)
                                    title = ""
                                    content = ""
                                    showAdd = false
                                }
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedDecoy) { note in
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(note.title)
                                .font(.title)
                                .bold()
                            Divider()
                            Text(note.content)
                                .font(.body)
                            Spacer()
                        }
                        .padding()
                    }
                    .navigationTitle("تفاصيل")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("تم") { selectedDecoy = nil }
                        }
                    }
                }
            }
        }
    }
}

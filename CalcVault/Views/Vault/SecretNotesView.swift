import SwiftUI
import CryptoKit

/// واجهة الملاحظات المشفرة محلياً بتشفير عسكري AES-256-GCM
public struct SecretNotesView: View {
    @ObservedObject private var store = LocalVaultStore.shared
    @ObservedObject private var auth = AuthManager.shared
    
    @State private var showAddSheet = false
    @State private var newTitle = ""
    @State private var newContent = ""
    @State private var selectedNote: SecretNote?
    
    public init() {}
    
    public var body: some View {
        Group {
            if store.notes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "lock.doc.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue.opacity(0.8))
                    
                    Text("لا توجد ملاحظات سرية")
                        .font(.headline)
                    
                    Text("جميع الملاحظات هنا تُحفظ محلياً على جهازك ويتم تشفيرها بواسطة مفتاح مشتق من رمز دخولك السري، ولا يمكن قراءتها خارج هذا التطبيق.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button(action: { showAddSheet = true }) {
                        Label("إضافة أول ملاحظة", systemImage: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 8)
                }
                .padding()
            } else {
                List {
                    ForEach(store.notes) { note in
                        Button(action: {
                            selectedNote = note
                        }) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(note.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "lock.shield.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                
                                Text(note.content)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
                                Text(note.updatedAt, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteNotes)
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("الملاحظات المشفرة")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            addNoteSheet
        }
        .sheet(item: $selectedNote) { note in
            viewNoteSheet(note)
        }
        .onAppear {
            if let key = auth.activeSymmetricKey {
                store.loadSecretNotes(with: key)
            }
        }
    }
    
    private func deleteNotes(at offsets: IndexSet) {
        guard let key = auth.activeSymmetricKey else { return }
        store.deleteNote(at: offsets, key: key)
    }
    
    // MARK: - نافذة إضافة ملاحظة جديدة
    private var addNoteSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("عنوان الملاحظة")) {
                    TextField("مثال: كلمات مرور، حسابات بنكية...", text: $newTitle)
                }
                
                Section(header: Text("المحتوى السري")) {
                    TextEditor(text: $newContent)
                        .frame(minHeight: 180)
                }
            }
            .navigationTitle("ملاحظة جديدة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        showAddSheet = false
                        newTitle = ""
                        newContent = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ مشفر") {
                        guard let key = auth.activeSymmetricKey, !newTitle.isEmpty else { return }
                        store.addNote(title: newTitle, content: newContent, key: key)
                        showAddSheet = false
                        newTitle = ""
                        newContent = ""
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    // MARK: - عرض الملاحظة
    private func viewNoteSheet(_ note: SecretNote) -> some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("تشفير محلي AES-256", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Spacer()
                        Text(note.updatedAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 6)
                    
                    Text(note.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Divider()
                    
                    Text(note.content)
                        .font(.body)
                        .lineSpacing(6)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("إغلاق") {
                        selectedNote = nil
                    }
                }
            }
        }
    }
}

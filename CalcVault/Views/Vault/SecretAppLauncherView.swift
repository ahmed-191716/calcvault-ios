import SwiftUI
import SafariServices

/// واجهة قاذف التطبيقات السري داخل الآلة الحاسبة (بدون الحاجة لبصمة أو قيود خارجية)
public struct SecretAppLauncherView: View {
    @State private var apps: [SecretAppItem] = []
    @State private var showAddSheet = false
    @State private var activeWebURL: URL? = nil
    @State private var appLaunchErrorMessage: String? = nil
    @State private var showLaunchError = false
    
    // متغيرات إضافة تطبيق مخصص
    @State private var customName = ""
    @State private var customURL = ""
    @State private var isWebLink = false
    
    private let storageKey = "calcvault.secret.apps.list"
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // بطاقة الشرح والتوجيه
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock.square.stack.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text("كيف تخفي التطبيق وتفتحه من هنا؟")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        stepRow(num: "1", text: "اذهب لأي تطبيق في شاشتك (مثلاً واتساب) واضغط عليه ضغطة مطولة.")
                        stepRow(num: "2", text: "اختر 'إزالة التطبيق' ثم 'إزالة من الشاشة الرئيسية' (Remove from Home Screen).")
                        stepRow(num: "3", text: "سيختفي التطبيق تماماً من شاشة هاتفك، ويمكنك فتحه مباشرة من الأزرار بالأسفل برمزك السري وبدون أي بصمة!")
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(14)
                .padding(.horizontal)
                
                // شبكة التطبيقات السرية
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("التطبيقات والروابط المجهزة")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: { showAddSheet = true }) {
                            Label("إضافة تطبيق", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 16) {
                        ForEach(apps) { item in
                            Button(action: {
                                launchApp(item)
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(LinearGradient(
                                                gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.orange]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 64, height: 64)
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        
                                        Image(systemName: item.iconSymbol)
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(item.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteApp(item)
                                } label: {
                                    Label("حذف من القائمة", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("تطبيقاتي السرية")
        .sheet(isPresented: $showAddSheet) {
            addAppSheet
        }
        .sheet(item: $activeWebURL) { url in
            SafariWebView(url: url)
        }
        .alert(isPresented: $showLaunchError) {
            Alert(
                title: Text("تعذر فتح التطبيق"),
                message: Text(appLaunchErrorMessage ?? "تأكد من أن التطبيق مثبت على هاتفك."),
                dismissButton: .default(Text("حسناً"))
            )
        }
        .onAppear {
            loadApps()
        }
    }
    
    private func stepRow(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Color.orange)
                .clipShape(Circle())
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - تشغيل التطبيق أو الرابط
    private func launchApp(_ item: SecretAppItem) {
        if item.isWebLink, let url = URL(string: item.urlString) {
            activeWebURL = url
            return
        }
        
        if let url = URL(string: item.urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                appLaunchErrorMessage = "يبدو أن تطبيق (\(item.name)) غير مثبت على هذا الهاتف، أو أن الرابط غير مدعوم."
                showLaunchError = true
            }
        }
    }
    
    // MARK: - حفظ واسترجاع التطبيقات
    private func loadApps() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SecretAppItem].self, from: data) {
            self.apps = decoded
        } else {
            // القائمة الافتراضية الجاهزة
            self.apps = [
                SecretAppItem(name: "واتساب", urlString: "whatsapp://", iconSymbol: "message.fill"),
                SecretAppItem(name: "تلغرام", urlString: "tg://", iconSymbol: "paperplane.fill"),
                SecretAppItem(name: "سناب شات", urlString: "snapchat://", iconSymbol: "camera.fill"),
                SecretAppItem(name: "إنستغرام", urlString: "instagram://", iconSymbol: "photo.on.rectangle.angled"),
                SecretAppItem(name: "منصة إكس", urlString: "twitter://", iconSymbol: "bubble.left.and.bubble.right.fill"),
                SecretAppItem(name: "يوتيوب", urlString: "youtube://", iconSymbol: "play.rectangle.fill"),
                SecretAppItem(name: "متصفح خاص", urlString: "https://www.google.com", iconSymbol: "globe", isWebLink: true)
            ]
            saveApps()
        }
    }
    
    private func saveApps() {
        if let encoded = try? JSONEncoder().encode(apps) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func deleteApp(_ item: SecretAppItem) {
        apps.removeAll { $0.id == item.id }
        saveApps()
    }
    
    // MARK: - نافذة إضافة تطبيق مخصص
    private var addAppSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("معلومات التطبيق أو الرابط")) {
                    TextField("اسم التطبيق (مثال: بنك الراجحي، فيسبوك)", text: $customName)
                    TextField("الرابط أو الرابط الداخلي (مثال: https://...)", text: $customURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    
                    Toggle("رابط موقع إنترنت (يفتح بمتصفح سري داخلي)", isOn: $isWebLink)
                }
            }
            .navigationTitle("إضافة اختصار سري")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { showAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        if !customName.isEmpty && !customURL.isEmpty {
                            let newItem = SecretAppItem(
                                name: customName,
                                urlString: customURL,
                                iconSymbol: isWebLink ? "safari.fill" : "app.fill",
                                isWebLink: isWebLink
                            )
                            apps.append(newItem)
                            saveApps()
                            customName = ""
                            customURL = ""
                            isWebLink = false
                            showAddSheet = false
                        }
                    }
                    .disabled(customName.isEmpty || customURL.isEmpty)
                }
            }
        }
    }
}

// دمج متصفح Safari السري
struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.dismissButtonStyle = .close
        return vc
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

extension URL: Identifiable {
    public var id: String { self.absoluteString }
}

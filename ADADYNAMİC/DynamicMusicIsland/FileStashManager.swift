

import Foundation
import AppKit
import Combine
import UniformTypeIdentifiers

class FileStashManager: ObservableObject {
    @Published var stashedFiles: [URL] = []
    let maxFileCount = 5
    
    // Dosyayı hafızaya al
    func addFile(provider: NSItemProvider) {
        // Zaten 5 dosya varsa yenisini ekleme
        guard stashedFiles.count < maxFileCount else {
            print("⚠️ Maximum file count reached (\(stashedFiles.count)/\(maxFileCount))")
            return
        }
        
        print("📥 Attempting to load file from provider")
        print("   - Can load NSURL: \(provider.canLoadObject(ofClass: NSURL.self))")
        print("   - Can load NSImage: \(provider.canLoadObject(ofClass: NSImage.self))")
        print("   - Registered type identifiers: \(provider.registeredTypeIdentifiers)")
        
        // Get the first registered type
        guard let firstType = provider.registeredTypeIdentifiers.first else {
            print("❌ No registered type identifiers")
            return
        }
        
        print("   ✓ Attempting to load with type: \(firstType)")
        
        // Load the item with its first available type
        provider.loadItem(forTypeIdentifier: firstType, options: nil) { [weak self] (item, error) in
            if let error = error {
                print("❌ Error loading item: \(error.localizedDescription)")
                return
            }
            
            guard let self = self else { return }
            
            var fileURL: URL?
            
            // Try different conversion methods
            if let url = item as? URL {
                print("   ✓ Item is already a URL")
                fileURL = url
            } else if let data = item as? Data {
                print("   ✓ Item is Data, attempting to convert to URL")
                fileURL = URL(dataRepresentation: data, relativeTo: nil)
            } else if let string = item as? String {
                print("   ✓ Item is String: \(string)")
                // Check if it's a file path
                if string.hasPrefix("/") || string.hasPrefix("file://") {
                    fileURL = URL(fileURLWithPath: string.replacingOccurrences(of: "file://", with: ""))
                } else {
                    fileURL = URL(string: string)
                }
            } else if let nsurl = item as? NSURL {
                print("   ✓ Item is NSURL")
                fileURL = nsurl as URL
            } else {
                print("❌ Unknown item type: \(type(of: item))")
                print("   Item description: \(String(describing: item))")
            }
            
            guard let url = fileURL else {
                print("❌ Failed to convert to URL from: \(String(describing: item))")
                return
            }
            
            // Ensure it's a file URL
            let finalURL = url.isFileURL ? url : URL(fileURLWithPath: url.path)
            
            print("✅ Successfully loaded file: \(finalURL.lastPathComponent)")
            print("   Full path: \(finalURL.path)")
            print("   Is file URL: \(finalURL.isFileURL)")
            
            DispatchQueue.main.async {
                // Aynı dosya zaten varsa ekleme
                if !self.stashedFiles.contains(finalURL) {
                    self.stashedFiles.append(finalURL)
                    print("📦 Added to stash. Total files: \(self.stashedFiles.count)")
                    print("   Current stash: \(self.stashedFiles.map { $0.lastPathComponent })")
                } else {
                    print("⚠️ File already in stash: \(finalURL.lastPathComponent)")
                }
            }
        }
    }
    
    // Dosyayı listeden çıkar
    func removeFile(_ url: URL) {
        stashedFiles.removeAll { $0 == url }
    }
    
    // AirDrop menüsünü tetikle
    func shareViaAirDrop(providers: [NSItemProvider]) {
        print("🎯 AirDrop function called with \(providers.count) providers")
        var urlsToShare: [URL] = []
        let group = DispatchGroup()
        
        for (index, provider) in providers.enumerated() {
            print("   Processing provider #\(index + 1) for AirDrop")
            print("   Types: \(provider.registeredTypeIdentifiers)")
            group.enter()
            
            // Get the first registered type
            guard let firstType = provider.registeredTypeIdentifiers.first else {
                print("   ❌ No type identifiers")
                group.leave()
                continue
            }
            
            provider.loadItem(forTypeIdentifier: firstType, options: nil) { item, error in
                if let error = error {
                    print("   ❌ Error loading: \(error.localizedDescription)")
                    group.leave()
                    return
                }
                
                var fileURL: URL?
                
                if let url = item as? URL {
                    fileURL = url
                } else if let data = item as? Data {
                    fileURL = URL(dataRepresentation: data, relativeTo: nil)
                } else if let string = item as? String {
                    if string.hasPrefix("/") || string.hasPrefix("file://") {
                        fileURL = URL(fileURLWithPath: string.replacingOccurrences(of: "file://", with: ""))
                    } else {
                        fileURL = URL(string: string)
                    }
                } else if let nsurl = item as? NSURL {
                    fileURL = nsurl as URL
                }
                
                if let url = fileURL {
                    let finalURL = url.isFileURL ? url : URL(fileURLWithPath: url.path)
                    print("   ✅ Got URL for AirDrop: \(finalURL.lastPathComponent)")
                    urlsToShare.append(finalURL)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print("📤 Attempting AirDrop with \(urlsToShare.count) files")
            guard !urlsToShare.isEmpty else {
                print("❌ No files to share")
                return
            }
            
            guard let service = NSSharingService(named: .sendViaAirDrop) else {
                print("❌ AirDrop service unavailable")
                return
            }
            
            if service.canPerform(withItems: urlsToShare) {
                print("✅ Opening AirDrop picker...")
                service.perform(withItems: urlsToShare)
            } else {
                print("❌ AirDrop cannot perform with these items")
            }
        }
    }
}

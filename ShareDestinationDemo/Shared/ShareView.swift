//
//  ShareView.swift
//  ShareDestinationDemo
//
//  Created by Itsuki on 2024/11/17.
//


import SwiftUI
import UniformTypeIdentifiers

enum ViewMode {
    case view
    case edit
}

struct ShareView: View {
    private static let groupId = "group.itsuki.enjoy.ShareDestinationDemo"
    @AppStorage("text", store: UserDefaults(suiteName: Self.groupId)) private var savedText: String = ""
    @AppStorage("url", store: UserDefaults(suiteName: Self.groupId)) private var savedUrl: String = ""
    @AppStorage("extraNote", store: UserDefaults(suiteName: Self.groupId)) private var savedNote: String = ""

    private let itemProviders: [NSItemProvider]
    private let completeRequest: (() ->Void)?
    private let cancelRequest: ((ShareError) -> Void)?
    
    private let textType = UTType.text.identifier
    private let urlType = UTType.url.identifier
    
    @State private var url: URL?
    @State private var text: String?
    @State private var entry: String = ""
    @State private var viewMode: ViewMode
    
    var body: some View {
        VStack(spacing: 24) {
            if viewMode == .view && savedUrl.isEmpty && savedText.isEmpty && savedNote.isEmpty {
                VStack(spacing: 16) {
                    Text("No Previous Saved Info Available!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text("Head to Safari and try to share a URL or some text!")
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity, alignment: .center)

                
            } else {
                if viewMode == .view {
                    Text("Previous Saved Info")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                if let url {
                    VStack(spacing: 16) {
                        Text("URL")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(LocalizedStringKey(url.absoluteString))
                            .multilineTextAlignment(.leading)
                    }
                }
                
                if let text = text, !text.isEmpty {
                    VStack(spacing: 16) {
                        Text("Text")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(text)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                if text != nil || url != nil {
                    Divider()
                        .background(.black)
                }
                
                VStack(spacing: 16) {
                    Text("Some Extra Notes")
                    TextField("", text: $entry, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(5, reservesSpace: true)
                        .shadow(radius: 1)
                        .lineSpacing(4)
                        .disabled(viewMode == .view)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .topTrailing, content: {
            if let completeRequest {
                Button(action: {
                    savedUrl = url?.absoluteString ?? ""
                    savedText = text ?? ""
                    savedNote = entry
                    completeRequest()
                }, label: {
                    Text("Save")
                })
            }
        })
        .overlay(alignment: .topLeading, content: {
            if let completeRequest {
                Button(action: {
                    completeRequest()
                }, label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                })
            }
        })
        .padding()
        .onAppear {
            if viewMode == .view {
                self.text = savedText
                self.url = URL(string: savedUrl)
                self.entry = savedNote
                return
            }
            do {
                try processItems(itemProviders)
            } catch (let error) {
                print(error)
                if error is ShareError {
                    cancelRequest?(error as! ShareError)
                } else {
                    cancelRequest?(.unknown)
                }
            }
        }
        .onChange(of: [savedUrl, savedNote, savedText], {
            self.text = savedText
            self.url = URL(string: savedUrl)
            self.entry = savedNote

        })
    }
    
    nonisolated private func processItems(_ itemProviders: [NSItemProvider]) throws {
        var text: String?
        var url: URL?
        Task {
            for itemProvider in itemProviders {
                if itemProvider.hasItemConformingToTypeIdentifier(urlType) {
                    let data = try await itemProvider.loadItem(forTypeIdentifier: urlType)
                    print("url", data)
                    
                    guard let urlData = data as? NSURL as? URL
                    else {
                        print("error getting url data")
                        throw ShareError.loadItemError
                    }
                    url = urlData

                    continue
                }
                if itemProvider.hasItemConformingToTypeIdentifier(textType) {
                    let data = try await itemProvider.loadItem(forTypeIdentifier: textType)
                    print("text", data)
                    
                    guard let textData = data as? String
                    else {
                        print("error getting text data")
                        throw ShareError.loadItemError
                    }
                    
                    text = textData
                    
                    continue
                }
            }
            
            if text == nil && url == nil {
                print("ShareError.itemNotFound")
                throw ShareError.itemNotFound
            }
            
            DispatchQueue.main.async { [text, url] in
                self.text = text
                self.url = url
            }
        }
    }
}

extension ShareView {
    init(itemProviders: [NSItemProvider], completeRequest: @escaping () -> Void, cancelRequest: @escaping (ShareError) -> Void) {
        self.itemProviders = itemProviders
        self.completeRequest = completeRequest
        self.cancelRequest = cancelRequest
        self.viewMode = .edit
    }
    
    init() {
        self.itemProviders = []
        self.completeRequest = nil
        self.cancelRequest = nil
        self.viewMode = .view
    }
}



#Preview {
    ShareView()
    
//    ShareView(itemProviders: [
//        .init(item: "Hello" as NSSecureCoding, typeIdentifier: UTType.text.identifier),
//        .init(item: "https://bulbapedia.bulbagarden.net/wiki/Pikachu_(Pok%C3%A9mon)" as NSSecureCoding, typeIdentifier: UTType.url.identifier)
//    ], completeRequest: {}, cancelRequest: {_ in })
}

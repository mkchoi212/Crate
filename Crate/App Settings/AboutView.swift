//
//  AboutView.swift
//  untitled
//
//  Created by Mike Choi on 11/11/22.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }
}

extension String: Identifiable {
    public var id: String {
        self
    }
}

struct AboutView: View {
    @State var launchURL: String?
    
    var body: some View {
        List {
            Section {
                mural
            } header: { }
            
            myTwitter
            
            licneses
            
            rate
        }
        .listStyle(.insetGrouped)
        .sheet(item: $launchURL) { url in
            SafariView(url: URL(string: url)!)
        }
    }
    
    var licneses: some View {
        NavigationLink {
            LicensesView()
        } label: {
            HStack {
                Image(systemName: "scroll.fill")
                Text("Licenses")
                    .modifier(BodyTextModifier())
                
                Spacer()
            }
        }
    }
    
    var rate: some View {
        Button {
            launchURL = "https://twitter.com/guard_if"
        } label: {
            HStack {
                Image(systemName: "heart.fill")
                Text("Rate untitled.")
                    .modifier(BodyTextModifier())
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    var myTwitter: some View {
        Button {
            launchURL = "https://twitter.com/guard_if"
        } label: {
            HStack {
                Image(systemName: "bird.fill")
                Text("Made by @guard_if")
                    .modifier(BodyTextModifier())
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    var mural: some View {
        VStack(alignment: .center, spacing: 30) {
            ZStack {
                ForEach(-2...2, id: \.self) { i in
                    Text("untitled.")
                        .font(.system(size: 40, weight: .bold, design: .default))
                        .offset(x: CGFloat(i) * 24, y: CGFloat(i) * 24)
                }
            }
            .padding()
            .padding(.vertical, 20)
            
            let versionNum = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            Text("version \(versionNum ?? "0.0")")
                .font(.system(size: 14, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color.clear)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct AboutView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AboutView()
        }
    }
}

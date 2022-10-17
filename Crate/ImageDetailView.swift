//
//  ImageDetailView.swift
//  Crate
//
//  Created by Mike Choi on 10/13/22.
//

import SwiftUI
import Foundation
import UIKit

final class ImageDetailViewModel: ObservableObject {
    @Published var entry: Entry = .init(id: UUID(), name: "", date: Date(), original: UIImage(systemName: "circle")!, modified: nil, colors: [])
    
    var palette: [UIColor] {
        entry.colors.compactMap { $0.makeUIColor() }
    }
    
    var image: UIImage {
        entry.modified ?? entry.original
    }
}

struct ImageDetailView: View {
    let proxy: FloatingPanelProxy
    @Binding var folderName: String
    @Binding var entry: Entry?
    
    @State var backgroundColor: Color? = .black
    @EnvironmentObject var viewModel: ImageDetailViewModel
    
    var body: some View {
        GeometryReader { reader in
            VStack(alignment: .center, spacing: 12) {
                ZStack(alignment: .top) {
                    HStack {
                        Button {
                            proxy.move(to: .hidden, animated: true)
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    
                    Text("⭐ Favorites")
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .semibold, design: .default))
                }
                
                Image(uiImage: viewModel.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: reader.size.height * 0.6, alignment: .center)
                
                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.entry.name)
                            .font(.system(size: 24, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                        
                        Text("2 weeks ago")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.white)
                            .font(.system(size: 28, weight: .semibold, design: .default))
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("PALETTE")
                        .foregroundColor(.gray)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    
                    HStack {
                        ForEach(viewModel.palette) { color in
                            RoundedRectangle(cornerRadius: 6)
                                .foregroundColor(Color(uiColor: color))
                                .frame(width: 40, height: 40)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.vertical)
                
                Spacer()
            }
        }
        .padding(.top, 18)
        .padding(.horizontal, 20)
        .background(.black)
        .onChange(of: entry) { entry in
            proxy.fpc?.isRemovalInteractionEnabled = true
            
            if let entry = entry {
                viewModel.entry = entry
                proxy.move(to: .full, animated: true)
            } else {
                proxy.move(to: .hidden, animated: true)
            }
        }
    }
}

struct ImageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(FolderStorage.shared)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
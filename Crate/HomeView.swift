//
//  ContentView.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import SwiftUI
import FloatingPanel

struct HomeSettingsView: View {
    let proxy: FloatingPanelProxy
    @Binding var showSettings: Bool
    @Binding var zoomFactor: Double
    
    var body: some View {
        VStack(spacing: 24) {
            Text("choose your perspective")
            
            HStack(spacing: 12) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 20, weight: .light, design: .default))
                
                Slider(value: $zoomFactor, in: 1...15, step: 1)
                
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 20, weight: .light, design: .default))
            }
        }
        .padding()
        .onChange(of: showSettings) { _ in
            proxy.move(to: .full, animated: true)
        }
    }
}

struct HomeView: View {
    @Binding var detailPayload: DetailPayload?
    @Binding var zoomFactor: Double
    @Binding var showSettings: Bool
    
    @State var imagesPayload: ImagesPayload?
    @State var showingImagePicker = false
    @State var showImageReviewModal = false
    
    // MARK: - Core Data
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \PictureFolder.name, ascending: true)], animation: .default)
    var folders: FetchedResults<PictureFolder>
    
    // MARK: -
    
    @StateObject var viewModel = PictureEntryViewModel()
    @StateObject var panelDelegate = SettingsPanelDelegate()
    @StateObject var detailViewModel = ImageDetailViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(folders) { folder in
                        section(Folder(coreDataObject: folder))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                
                Button {
                    showingImagePicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .semibold, design: .default))
                        .foregroundColor(Color.white)
                        .padding()
                        .background(Circle().foregroundColor(.blue))
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Crate")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(imagesPayload: $imagesPayload)
        }
        .fullScreenCover(item: $imagesPayload) { payload in
            ImageReview(images: payload.images)
        }
    }
    
    @ViewBuilder
    func section(_ folder: Folder) -> some View {
        HStack(alignment: .center) {
            Text(folder.fullName)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .bold, design: .default))
            }
        }
        .padding(.vertical)
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.flexible())]) {
                ForEach(folder.entries) { entry in
                    Button {
                        detailPayload = DetailPayload(id: UUID(), folder: folder, detail: entry)
                    } label: {
                        VStack(alignment: .center, spacing: 6) {
                            Image(uiImage: viewModel.image(for: entry))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 50 * zoomFactor)
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text(viewModel.name(for: entry))
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundColor(.white)
                                
                                Text(viewModel.dateString(for: entry))
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
//        .background(Color.red)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(detailPayload: .constant(nil), zoomFactor: .constant(4), showSettings: .constant(false))
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
    }
}

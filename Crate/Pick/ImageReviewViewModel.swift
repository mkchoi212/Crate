//
//  ImageReviewViewModel.swift
//  untitled
//
//  Created by Mike Choi on 10/16/22.
//

import CoreData
import Combine
import SwiftUI
import Vision

struct SegmentedImage {
    let original: UIImage
    let active: UIImage
    let inactive: UIImage
}

final class ImageReviewManager: ObservableObject {
    var current: ImageReviewViewModel = .dummy
    @Published var viewModels: [ImageReviewViewModel] = []
    
    func save(viewContext: NSManagedObjectContext) async {
        await withTaskGroup(of: Bool.self) { taskGroup in
            for vm in viewModels {
                taskGroup.addTask {
                    let ok = await vm.save(viewContext: viewContext)
                    return ok
                }
            }
        }
    }
    
    func setupEditMode(entry: EntryEntity) {
        guard let viewModel = ImageReviewViewModel(entry: entry) else {
            return
        }
        
        viewModels = [viewModel]
        current = viewModel
    }
    
    func createViewModels(images: [UIImage]) {
        if !viewModels.isEmpty {
            return
        }
        
        viewModels = images.enumerated().map { ImageReviewViewModel(image: $0.element, pageNumber: $0.offset) }
        if let first = viewModels.first {
            current = first
        }
    }
    
    func selectViewModel(idx: Int) {
        if viewModels.count == idx + 1 {
            return
        }
        
        current = viewModels[idx]
    }
}

final class ImageReviewViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let originalImage: UIImage
    let pageNumber: Int
    var existingEntry: PictureEntry?
    
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var folder: Folder?
   
    @Published var allTextBoundingBoxes: [BoundingBox] = []
    @Published var textBoundingBoxes: [BoundingBox] = []
    @Published var titleBox: BoundingBox?
    
    @Published var includeSegmentedImage = false
    @Published var segmentedImage: SegmentedImage?
    @Published var imageSize: CGSize = .zero
    @Published var colors: [MMCQ.Color]?
    @Published var tappableBounds: CGRect?
    
    // MARK: -  processors
  
    let paletteQueue = DispatchQueue(label: "com.crate.color_palette", qos: .background)
    let textProcessor = TextProcessor()
    let personSegmenter = PersonSegmenter()
    var textRecognitionStream: AnyCancellable?
    var imageSegmentationStream: AnyCancellable?

    // MARK: -
    
    let encoder = JSONEncoder()
    
    static let dummy = ImageReviewViewModel(image: UIImage(), pageNumber: -1)
    
    init(image: UIImage, pageNumber: Int) {
        self.originalImage = image.fixOrientation()
        self.pageNumber = pageNumber
    }
    
    init?(entry: EntryEntity) {
        guard let entry = entry.entry, let folder = entry.folder else { return nil}
        self.pageNumber = 0
        self.folder = Folder(coreDataObject: folder)
        self.originalImage = ImageStorage.shared.loadImage(named: entry.original)?.fixOrientation() ?? UIImage()
        self.description = entry.detailText ?? ""
        self.name = entry.name ?? ""
        
        existingEntry = entry
    }
    
    var segmented: UIImage? {
        includeSegmentedImage ? segmentedImage?.active : segmentedImage?.inactive
    }
        
    func didTapFolder(_ folder: PictureFolder) async {
        self.folder = Folder(coreDataObject: folder)
    }
    
    @MainActor
    func preprocess() async {
        Task(priority: .userInitiated) {
            async let boxes = await textProcessor.performRecognition(image: originalImage)
            async let segmented = await personSegmenter.segment(image: originalImage)
        
            self.segmentedImage = await segmented
            self.allTextBoundingBoxes = await boxes
        }
    }
  
    @MainActor
    func requestForProcessing(imageSize: CGSize) {
        if self.imageSize != .zero {
            return
        }
        
        self.imageSize = imageSize
       
        textRecognitionStream?.cancel()
        textRecognitionStream = $allTextBoundingBoxes
            .receive(on: RunLoop.main)
            .map { (rects: [BoundingBox]) -> [BoundingBox] in
                rects.map { box in
                    let bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
                    let rect = box.box.applying(bottomToTopTransform)
                    return BoundingBox(id: UUID(), confidence: box.confidence, box: VNImageRectForNormalizedRect(rect, Int(imageSize.width), Int(imageSize.height)), string: box.string)
                }
            }
            .sink { [weak self] (boxes: [BoundingBox]) in
                guard let self = self else { return }
                
                self.allTextBoundingBoxes = boxes.filter { $0.semiConfident }
                let suggested = self.allTextBoundingBoxes.max(by: { lft, rht in
                    lft.area < rht.area
                })
                
                if self.existingEntry == nil, let suggested = suggested {
                    self.name = suggested.string
                    self.titleBox = suggested
                }
            }
      
        imageSegmentationStream?.cancel()
        imageSegmentationStream = $segmentedImage
            .compactMap { $0 }
            .first()
            .receive(on: RunLoop.main)
            .sink { [weak self] image in
                guard let self = self else { return }
                
                Task(priority: .background) {
                    self.tappableBounds = await image.original.imageResized(to: imageSize).cropRect()
                }
                
                self.colors = ColorThief.getPalette(from: image.original, colorCount: 5)
            }
    }
    
    func didTapBoundingBox(_ box: BoundingBox) {
        DispatchQueue.main.async {
            if box == self.titleBox {
                self.titleBox = nil
                self.name = ""
            } else {
                self.titleBox = box
                self.name = box.string
            }
        }
    }
    
    func save(viewContext: NSManagedObjectContext) async -> Bool {
        guard let folder = folder else {
            return false
        }
       
        let entry: PictureEntry
        
        if let existingEntry = existingEntry {
            entry = existingEntry
        } else {
            entry = PictureEntry(context: viewContext)
            let entryID = UUID()
            entry.id = entryID
        }
        
        entry.name = name
        entry.date = Date()
        entry.detailText = description
        
        entry.original = ImageStorage.shared.write(originalImage, entryID: entry.id!, isOriginal: true)
        entry.modified = await ImageStorage.shared.write(segmentedImage?.original.trimmingTransparentPixels(), entryID: entry.id!, isOriginal: false)
        entry.boxes = NSArray()
        entry.folder = folder.coreDataObject
        entry.colors = (colors ?? []).map { $0.id }

        do {
            try viewContext.save()
            return true
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

import SwiftUI
struct GalleryView: View {
    @State var images: [UIImage?]
  
    @State var isSelectedArray: [Bool] = []
    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 0), count: 10)
    @Binding var showGallery: Bool
    @State private var showDetail: Bool = false
    @State var currentIndex: Int = 0
    @State private var isSelectionMode: Bool = false
    @State private var selectedImages: [Int] = []
    @State private var showDeleteAlert: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 0) {
                            ForEach(images.indices, id: \.self) { index in
                                if let uiImage = images[index] {
                                    ZStack {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: UIScreen.main.bounds.width * 0.1, height: UIScreen.main.bounds.width * 0.1)
                                            .clipped()
                                            .overlay {
                                                if selectedImages.contains(index) {
                                                    Color.black.opacity(0.4)
                                                        .frame(width: UIScreen.main.bounds.width * 0.1, height: UIScreen.main.bounds.width * 0.1)
                                                        .overlay(
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .foregroundColor(.white)
                                                                .padding(5),
                                                            alignment: .topTrailing
                                                        )
                                                }
                                            }
                                            .onTapGesture {
                                                if isSelectionMode {
                                                    toggleSelection(index: index)
                                                } else {
                                                    currentIndex = index
                                                    showDetail = true
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
                
                if showDetail {
                    PhotoDetailView(
                        showDetail: $showDetail,
                        images: images.compactMap { $0 },
                        currentIndex: $currentIndex
                    )
                }
            }
            .onAppear {
                isSelectedArray = Array(repeating: false, count: images.count)
            }
            .navigationTitle(switchNavigationTitle())
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Do you really want to delete it?"),
                    message: Text("This operation cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) { deleteSelectedImages() },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !showDetail {
                        HStack(spacing: 0) {
                            if isSelectionMode {
                                Button {
                                    isSelectionMode = false
                                    selectedImages.removeAll()
                                } label: {
                                    Text("Cancel")
                                        .padding(.vertical, 7)
                                        .padding(.horizontal)
                                        .background {
                                            RoundedRectangle(cornerRadius: 30)
                                                .foregroundStyle(.gray.opacity(0.2))
                                        }
                                }
                                .padding(.horizontal)
                            } else {
                                Button {
                                    isSelectionMode = true
                                } label: {
                                    Text("Select")
                                    .foregroundStyle(.blue)
                                        .padding(.vertical, 7)
                                        .padding(.horizontal)
                                        .background {
                                            RoundedRectangle(cornerRadius: 30)
                                                .foregroundStyle(.gray.opacity(0.2))
                                        }
                                }
                                .padding(.horizontal)
                            }
                            Button {
                                showGallery = false
                            } label: {
                                Image(systemName: "xmark")
                                    .foregroundStyle(.blue)
                                    .font(.subheadline)
                                    .padding(7)
                                    .background {
                                        Circle().foregroundStyle(.gray.opacity(0.2))
                                    }
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    if isSelectionMode {
                        HStack {
                            Button {} label: {}
                            Spacer()
                            Button {
                                showDeleteAlert = true
                            } label: {
                                Label("削除", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                            .disabled(selectedImages.isEmpty)
                        }
                    }
                }
            }
        }
    }
    private func switchNavigationTitle() -> String {
        if isSelectionMode {
            return "Selecting　\(selectedImages.count)"
        } else if showDetail {
            return ""
        } else {
            return "Gallery"
        }
    }
    private func toggleSelection(index: Int) {
        if selectedImages.contains(index) {
            isSelectedArray[index] = false
            selectedImages.removeAll(where: { $0 == index })
        } else {
            isSelectedArray[index] = true
            selectedImages.append(index)
        }
    }
    private func deleteSelectedImages() {
        withAnimation {
            let sortedIndices = selectedImages.sorted(by: >)
            for index in sortedIndices {
                images.remove(at: index)
            }
            selectedImages.removeAll()
            isSelectedArray = Array(repeating: false, count: images.count)
            isSelectionMode = false
        }
    }
}

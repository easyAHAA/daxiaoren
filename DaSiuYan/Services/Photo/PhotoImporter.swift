// PhotoImporter.swift
// PhotosPicker（iOS 16+）+ UIImagePickerController（iOS 15 fallback）。

import SwiftUI
import PhotosUI

public struct PhotoPickerView: View {
    @Binding var selected: UIImage?

    public init(selected: Binding<UIImage?>) {
        self._selected = selected
    }

    public var body: some View {
        if #available(iOS 16.0, *) {
            ModernPhotoPicker(selected: $selected) { pickerLabel }
        } else {
            LegacyPickerTrigger(selected: $selected) { pickerLabel }
        }
    }

    private var pickerLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
            Text("从相册选择")
                .font(.system(size: 15, weight: .semibold))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Capsule().fill(.ultraThinMaterial))
    }
}

@available(iOS 16.0, *)
private struct ModernPhotoPicker<Label: View>: View {
    @Binding var selected: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    let label: () -> Label

    var body: some View {
        PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
            label()
        }
        .onChange(of: pickerItem) { newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { selected = image }
                }
                pickerItem = nil
            }
        }
    }
}

private struct LegacyPickerTrigger<Label: View>: View {
    @Binding var selected: UIImage?
    @State private var show = false
    let label: () -> Label

    var body: some View {
        Button { show = true } label: { label() }
            .sheet(isPresented: $show) {
                LegacyImagePicker(image: $selected, isPresented: $show)
            }
    }
}

private struct LegacyImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LegacyImagePicker
        init(_ parent: LegacyImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

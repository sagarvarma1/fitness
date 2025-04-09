import SwiftUI
import UIKit

// Helper struct for UIKit image picker integration 
// that can be used throughout the app
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Camera/Photo Library selection view
struct ImagePickerSelectionView: View {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    @Binding var sourceType: UIImagePickerController.SourceType?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                Text("Choose Photo Source")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Button(action: {
                    sourceType = .camera
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                        Text("Camera")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    sourceType = .photoLibrary
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: "photo.fill")
                            .foregroundColor(.white)
                        Text("Photo Library")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 40)
            .background(Color(UIColor.darkGray))
            .cornerRadius(15)
            .padding(.horizontal, 30)
        }
    }
}

// Enum to make sourceType Identifiable for the sheet
extension UIImagePickerController.SourceType: Identifiable {
    public var id: Int {
        switch self {
        case .camera: return 1
        case .photoLibrary: return 2
        case .savedPhotosAlbum: return 3
        @unknown default: return 0
        }
    }
}

// Picker view that implements the selected source type
struct CameraOrLibraryPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = sourceType
        
        // Show camera roll in camera interface
        if sourceType == .camera {
            picker.showsCameraControls = true
            picker.cameraDevice = .rear
            picker.cameraCaptureMode = .photo
            // This enables the camera roll strip at the bottom
            picker.mediaTypes = ["public.image"]
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraOrLibraryPicker
        
        init(_ parent: CameraOrLibraryPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Enhanced camera picker that attempts to match the native iOS camera experience
struct NativeCameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .camera
        
        // Configure camera settings
        picker.showsCameraControls = true
        picker.cameraDevice = .rear
        picker.cameraCaptureMode = .photo
        
        // Use native media types
        picker.mediaTypes = ["public.image"]
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: NativeCameraPicker
        
        init(_ parent: NativeCameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Camera view with camera roll button
struct CameraWithGalleryView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    @State private var showingCamera = true
    @State private var showingImagePicker = false
    
    var body: some View {
        ZStack {
            // Camera view
            if showingCamera {
                ZStack {
                    CameraPicker(selectedImage: $selectedImage, presentationMode: presentationMode)
                    
                    // Top right gallery button - smaller and native looking
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                showingCamera = false
                                showingImagePicker = true
                            }) {
                                Image(systemName: "photo")
                                    .font(.system(size: 18))
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 16)
                            .padding(.trailing, 16)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Photo library picker
            if showingImagePicker {
                PhotoLibraryPicker(selectedImage: $selectedImage, presentationMode: presentationMode)
                    .transition(.move(edge: .trailing))
            }
        }
    }
}

// Camera picker component
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var presentationMode: Binding<PresentationMode>
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .camera
        picker.showsCameraControls = true
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Photo library picker component
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var presentationMode: Binding<PresentationMode>
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoLibraryPicker
        
        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
} 
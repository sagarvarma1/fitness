import SwiftUI

struct WelcomeView: View {
    @State private var navigateToPhotoUpload = false
    @State private var buttonScale = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background instead of flat black
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App title/branding
                    Text("10-WEEK SHRED")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding(.bottom, -10)
                    
                    // Fitness icon
                    Image(systemName: "flame.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .padding(.bottom, 20)
                    
                    // Fixed text with proper grammar
                    Text("IF YOU DO EVERY WORKOUT IN THIS APP FOR THE NEXT TEN WEEKS, YOU WILL BE RIPPED")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    NavigationLink(destination: PhotoUploadView(), isActive: $navigateToPhotoUpload) {
                        EmptyView()
                    }
                    
                    Spacer()
                    
                    // Button with pulse animation
                    Button("LET'S GO!") {
                        self.navigateToPhotoUpload = true
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 30)
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .font(.title3.bold())
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.red.opacity(0.7), lineWidth: 3.5)
                            .shadow(color: .red, radius: 3)
                    )
                    .padding(.horizontal, 50)
                    .scaleEffect(buttonScale)
                    .shadow(color: .red.opacity(0.5), radius: 10)
                    .onAppear {
                        // Subtle breathing animation for the button
                        withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            buttonScale = 1.05
                        }
                    }
                    
                    // Motivational subtext
                    Text("Transform your body starting today")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

// Designed PhotoUploadView - replaces the previous placeholder
struct PhotoUploadView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var navigateToMainView = false
    
    var body: some View {
        ZStack {
            // Same gradient background as WelcomeView for consistency
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Navigation header with back and skip buttons
                HStack {
                    // Back button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Skip button
                    NavigationLink(destination: Text("Main View Placeholder").navigationBarHidden(true), isActive: $navigateToMainView) {
                        EmptyView()
                    }
                    
                    Button("SKIP") {
                        navigateToMainView = true
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                
                // Fire icon MOVED to top (after navigation)
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.top, -5)
                
                // Upload heading MOVED to top (after fire icon)
                Text("UPLOAD INITIAL PHOTO")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                // Photo upload box - INCREASED height
                Button(action: {
                    isImagePickerPresented = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 350) // Increased from 200 to 350
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.7), lineWidth: 2)
                            )
                        
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 350) // Increased from 200 to 350
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50)) // Slightly larger icon
                                    .foregroundColor(.white)
                                    .padding(.bottom, 15)
                                
                                Text("PRESS HERE TO UPLOAD")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(selectedImage: $selectedImage)
                }
                
                // Continue button - appears when photo is selected
                if selectedImage != nil {
                    Button("CONTINUE") {
                        // Here you would save the image to CloudKit
                        // For now, just navigate to next screen
                        navigateToMainView = true
                    }
                    .padding(.vertical, 15)
                    .padding(.horizontal, 30)
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .font(.headline)
                    .cornerRadius(15)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// Helper struct for UIKit image picker integration
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

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .preferredColorScheme(.dark)
    }
}
import SwiftUI
import UIKit

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

// Updated PhotoUploadView with CloudKit integration
struct PhotoUploadView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var navigateToMainView = false
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Create a CloudKit manager instance
    @StateObject private var cloudKitManager = CloudKitManager()
    
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
                    NavigationLink(destination: HomePage(), isActive: $navigateToMainView) {
                        EmptyView()
                    }
                    
                    Button("SKIP") {
                        // Mark as completed initialization before navigating
                        UserDefaults.standard.set(true, forKey: "hasCompletedInitialSetup")
                        navigateToMainView = true
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                
                // Fire icon at top
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.top, -5)
                
                // Upload heading
                Text("UPLOAD INITIAL PHOTO")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                // Photo upload box
                Button(action: {
                    isImagePickerPresented = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 350)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.7), lineWidth: 2)
                            )
                        
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 350)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .padding(.bottom, 15)
                                
                                Text("PRESS HERE TO UPLOAD")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Show loading overlay when saving
                        if isSaving {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                                .frame(height: 350)
                            
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.bottom, 20)
                                
                                Text("Saving photo...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .disabled(isSaving)
                .padding(.horizontal, 30)
                .sheet(isPresented: $isImagePickerPresented) {
                    CameraWithGalleryView(selectedImage: $selectedImage)
                }
                
                // Continue button - appears when photo is selected
                if selectedImage != nil {
                    Button(action: {
                        // Mark as completed initialization
                        UserDefaults.standard.set(true, forKey: "hasCompletedInitialSetup")
                        // Try to save to CloudKit but don't block on failure
                        savePhotoToCloudKit()
                    }) {
                        Text("CONTINUE")
                            .padding(.vertical, 15)
                            .padding(.horizontal, 30)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .font(.headline)
                            .cornerRadius(15)
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    // Add skip CloudKit option during development
                    #if DEBUG
                    Text("(CloudKit may not work in simulator)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                        
                    Button(action: {
                        // Mark as completed initialization
                        UserDefaults.standard.set(true, forKey: "hasCompletedInitialSetup")
                        // Skip CloudKit and go directly to main view
                        navigateToMainView = true
                    }) {
                        Text("Skip CloudKit")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                    }
                    #endif
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        // Show an alert if there's an error
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        // Subscribe to CloudKit loading status
        .onChange(of: cloudKitManager.isLoading) { isLoading in
            isSaving = isLoading
        }
        // Remove the problematic onChange for error
        // Add onAppear modifier to set up error handler
        .onAppear {
            loadInitialPhoto()
            
            // Set up error handler
            cloudKitManager.errorHandler = { error in
                self.alertMessage = error.localizedDescription
                self.showingAlert = true
            }
        }
    }
    
    // Function to save the selected photo to CloudKit
    private func savePhotoToCloudKit() {
        guard let image = selectedImage else { return }
        
        isSaving = true
        
        // Try to save to CloudKit, but always allow continuing
        cloudKitManager.savePhoto(image: image, isInitial: true) { result in
            DispatchQueue.main.async {
                isSaving = false
                
                switch result {
                case .success(_):
                    print("Successfully saved photo to CloudKit")
                    // Navigate to main screen on success
                    navigateToMainView = true
                    
                case .failure(let error):
                    // Show error alert but still allow continuing
                    alertMessage = "Failed to save photo to CloudKit. Continuing in local mode: \(error.localizedDescription)"
                    showingAlert = true
                    
                    // Allow continuing despite CloudKit failure
                    // Implement local storage here in a real app
                    
                    // For now, just navigate
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.navigateToMainView = true
                    }
                }
            }
        }
    }
    
    // Function to check for existing initial photo
    private func loadInitialPhoto() {
        cloudKitManager.fetchInitialPhoto { result in
            switch result {
            case .success(let image):
                if let image = image {
                    self.selectedImage = image
                    print("Successfully loaded initial photo")
                } else {
                    print("No initial photo found")
                }
            case .failure(let error):
                print("Error loading initial photo: \(error.localizedDescription)")
                // Don't show an alert for this error
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .preferredColorScheme(.dark)
    }
}
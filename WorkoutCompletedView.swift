import SwiftUI
import UIKit

struct WorkoutCompletedView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var navigateToMainView = false
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var nextDay = 1  // Default to day two (index 1)
    
    // Create a CloudKit manager instance
    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var viewModel = WorkoutViewModel()
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Fire logo
                Image(systemName: "flame.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.red)
                    .padding(.top, 40)
                
                // Congratulatory message
                Text("Congratulations!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("You've completed your workout!")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
                
                // Photo upload section
                VStack(spacing: 15) {
                    Text("Track your progress")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        isImagePickerPresented = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                                .frame(height: 250)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.7), lineWidth: 2)
                                )
                            
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                        .padding(.bottom, 15)
                                    
                                    Text("TAKE A PHOTO")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Show loading overlay when saving
                            if isSaving {
                                Color.black.opacity(0.6)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $isImagePickerPresented) {
                        CameraWithGalleryView(selectedImage: $selectedImage)
                    }
                }
                
                Spacer()
                
                // Add Later button
                Button("ADD LATER") {
                    // Navigate to main view without saving photo
                    // Ensure we're going to day two
                    UserDefaults.standard.set(nextDay, forKey: "currentDayIndex")
                    dismissAndReturnToHome()
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.clear)
                .foregroundColor(.white)
                .font(.headline)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 30)
                
                // Continue button
                Button("CONTINUE") {
                    if let image = selectedImage {
                        savePhotoToCloudKit()
                    } else {
                        // If no photo was taken, just navigate to main view
                        // Ensure we're going to day two
                        UserDefaults.standard.set(nextDay, forKey: "currentDayIndex")
                        dismissAndReturnToHome()
                    }
                }
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .font(.headline)
                .cornerRadius(15)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .padding()
        }
        .onAppear {
            // Get the current day and set the next day
            let currentDay = viewModel.currentDayIndex ?? 0
            nextDay = currentDay + 1
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: cloudKitManager.isLoading) { isLoading in
            isSaving = isLoading
        }
        .onAppear {
            // Set up error handler
            cloudKitManager.errorHandler = { error in
                self.alertMessage = error.localizedDescription
                self.showingAlert = true
            }
        }
    }
    
    // Function to dismiss this view and return to HomePage
    private func dismissAndReturnToHome() {
        print("Dismissing WorkoutCompletedView")
        
        // Direct notification approach - first refresh HomeView, then hide this view
        NotificationCenter.default.post(name: NSNotification.Name("RefreshHomeView"), object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: NSNotification.Name("HideWorkoutCompletedView"), object: nil)
        }
        
        // Add haptic feedback when dismissing
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // Function to save the selected photo to CloudKit
    private func savePhotoToCloudKit() {
        guard let image = selectedImage else { return }
        
        isSaving = true
        print("Saving photo to CloudKit, day: \(nextDay)")
        
        // Set next day in UserDefaults
        UserDefaults.standard.set(nextDay, forKey: "currentDayIndex")
        
        // Try to save to CloudKit, but always allow continuing
        cloudKitManager.savePhoto(image: image, isInitial: false, day: viewModel.currentDayIndex ?? 0) { result in
            DispatchQueue.main.async {
                self.isSaving = false
                
                switch result {
                case .success(_):
                    print("Successfully saved photo to CloudKit")
                    self.dismissAndReturnToHome()
                    
                case .failure(let error):
                    // Show error alert but still allow continuing
                    self.alertMessage = "Failed to save photo to CloudKit. Continuing: \(error.localizedDescription)"
                    self.showingAlert = true
                    
                    // Allow continuing despite CloudKit failure
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.dismissAndReturnToHome()
                    }
                }
            }
        }
    }
}

// Confetti view implementation
struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Create multiple confetti pieces
            ForEach(0..<200, id: \.self) { index in
                ConfettiPiece(index: index, animate: animate)
            }
        }
        .onAppear {
            // Trigger haptic feedback when confetti appears
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            
            // Start animation
            withAnimation(.easeOut(duration: 2)) {
                animate = true
            }
            
            // Play haptic feedback
            generator.notificationOccurred(.success)
            
            // Add a second haptic for more emphasis
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                impactGenerator.impactOccurred()
            }
        }
    }
}

struct ConfettiPiece: View {
    let index: Int
    let animate: Bool
    
    // Pre-calculate random values to avoid animation issues
    private let color: Color
    private let rotation: Double
    private let size: CGFloat
    private let xPosition: CGFloat
    private let yPosition: CGFloat
    private let opacity: Double
    private let delay: Double
    private let speed: Double
    
    init(index: Int, animate: Bool) {
        self.index = index
        self.animate = animate
        
        // Precalculate all random values
        let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
        self.color = colors.randomElement() ?? .red
        self.rotation = Double.random(in: 0...720)
        self.size = CGFloat.random(in: 5...12)
        self.xPosition = CGFloat.random(in: 0...UIScreen.main.bounds.width)
        self.yPosition = CGFloat.random(in: -50...UIScreen.main.bounds.height)
        self.opacity = Double.random(in: 0.3...1.0)
        self.delay = Double.random(in: 0...0.3)
        self.speed = Double.random(in: 0.5...1.5)
    }
    
    var body: some View {
        confettiShape
            .position(
                x: animate ? xPosition : UIScreen.main.bounds.width/2,
                y: animate ? yPosition : -50
            )
            .opacity(animate ? opacity : 1)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.7)
                    .speed(speed)
                    .delay(delay),
                value: animate
            )
    }
    
    @ViewBuilder
    var confettiShape: some View {
        if index % 3 == 0 {
            Rectangle()
                .fill(color)
                .frame(width: size, height: size * 1.5)
                .rotationEffect(Angle(degrees: animate ? rotation : 0))
        } else if index % 3 == 1 {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .rotationEffect(Angle(degrees: animate ? rotation : 0))
        } else {
            Triangle()
                .fill(color)
                .frame(width: size, height: size)
                .rotationEffect(Angle(degrees: animate ? rotation : 0))
        }
    }
}

// Triangle shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct WorkoutCompletedView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutCompletedView()
    }
} 
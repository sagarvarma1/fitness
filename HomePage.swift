import SwiftUI

struct HomePage: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @State private var navigateToWorkout = false
    @State private var showingError = false
    
    var body: some View {
        ZStack {
            // Same gradient background as WelcomeView for consistency
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Top logo only - removed navigation area with reset button
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                    .padding(.top, 10)
                
                if let week = viewModel.currentWeek, let day = viewModel.currentDay {
                    // Week Title
                    Text(week.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Day name
                    Text(day.name)
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.bottom, 5)
                    
                    // Using a custom fullScreenCover instead of NavigationLink
                    Button("GET STARTED") {
                        self.navigateToWorkout = true
                    }
                    .padding(.vertical, 15)
                    .padding(.horizontal, 30)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .font(.headline)
                    .cornerRadius(15)
                    .padding(.horizontal, 30)
                    .fullScreenCover(isPresented: $navigateToWorkout) {
                        // Custom workout view without navigation elements
                        WorkoutProgressView(viewModel: viewModel, isPresented: $navigateToWorkout)
                    }
                    
                    // Workout Details
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            // Focus description
                            Text("Focus: \(day.focus)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                            
                            // Workout description
                            Text(day.description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.bottom, 10)
                            
                            // Exercise list
                            Text("Today's Exercises:")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ForEach(day.exercises) { exercise in
                                HStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(exercise.title)
                                        .foregroundColor(.white.opacity(0.9))
                                        .font(.callout)
                                    
                                    Spacer()
                                }
                                .padding(.leading, 5)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                    }
                } else {
                    // Fallback if data can't be loaded
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                            .padding()
                        
                        Text("Could not load workout data")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button(action: {
                            viewModel.loadWorkoutData()
                        }) {
                            Text("Reload")
                                .padding(.vertical, 10)
                                .padding(.horizontal, 30)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                }
                
                Spacer()
            }
            .padding(.top, 5) // Reduced top padding to use more space
        }
        .onAppear {
            // Ensure we've completed initialization by setting the flag
            UserDefaults.standard.set(true, forKey: "hasCompletedInitialSetup")
            
            // Load workout data when view appears
            if viewModel.workoutProgram == nil {
                viewModel.loadWorkoutData()
            }
        }
    }
}

// Custom workout progress view without any navigation elements
struct WorkoutProgressView: View {
    var viewModel: WorkoutViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Black background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Header with workout info
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                    .padding(.top, 20)
                
                if let week = viewModel.currentWeek, let day = viewModel.currentDay {
                    Text(week.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(day.name)
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.bottom, 10)
                }
                
                Text("Workout In Progress")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                
                Spacer()
                
                // Complete button
                Button("COMPLETE WORKOUT") {
                    viewModel.advanceToNextDay()
                    isPresented = false
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .font(.headline)
                .cornerRadius(15)
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
} 
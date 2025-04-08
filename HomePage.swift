import SwiftUI

struct HomePage: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @State private var navigateToWorkout = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Same gradient background as WelcomeView for consistency
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Small fire logo at top
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                        .padding(.top, 30)
                    
                    if let week = viewModel.currentWeek, let day = viewModel.currentDay {
                        // Week Title
                        Text(week.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Day name
                        Text(day.name)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.bottom, 5)
                        
                        // Get Started Button
                        NavigationLink(destination: Text("Workout In Progress (Placeholder)").navigationBarHidden(true), isActive: $navigateToWorkout) {
                            EmptyView()
                        }
                        
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
                        
                        // Focus description
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Focus: \(day.focus)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                            
                            // Exercise list
                            Text("Today's Exercises:")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ForEach(viewModel.currentExerciseTitles, id: \.self) { title in
                                HStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(title)
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
                    } else {
                        // Fallback if data can't be loaded
                        Text("Could not load workout data")
                            .foregroundColor(.white)
                            .padding()
                        
                        Button("Reload") {
                            viewModel.loadWorkoutData()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 30)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                }
                .padding(.top, 10)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
} 
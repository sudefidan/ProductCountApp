// ContentView.swift

import SwiftUI
import UserNotifications
import Foundation

struct Machine: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let timeInSeconds: TimeInterval
    var productCount: Int
    var isRunning: Bool = false
    var startTime: Date?
    var endTime: Date?
}

struct ContentView: View {
    @Binding var selectedMachine: Machine?
    @Binding var totalProductCount: Int
    @Binding var machines: [Machine]
    @State private var showAlert = false
    
    var isMachineSelected: Bool {
        selectedMachine != nil
    }
    
    var isMachineRunning: Bool {
        selectedMachine?.isRunning == true
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Today's Product Count: \(totalProductCount)")
                    .font(.title)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(machines) { machine in
                            CardView(machine: machine, selectedMachine: $selectedMachine)
                                .onTapGesture {
                                    selectedMachine = machine
                                }
                        }
                    }
                    .padding()
                }
                
                Button(action: {
                    guard let selectedMachine = selectedMachine else { return }
                    // Exit  if the machine is already running
                    if selectedMachine.isRunning {
                        sendAlreadyRunningNotification(for: selectedMachine)
                        return
                    }
                    
                    // Select machine
                    self.selectedMachine = selectedMachine
                    
                    // Update machine
                    if let index = machines.firstIndex(where: { $0.id == selectedMachine.id }) {
                        var updatedMachines = machines
                        
                        // Update machine's running state
                        updatedMachines[index].isRunning = true
                        // Update machine start time
                        updatedMachines[index].startTime = Date()
                        // Update machine end time
                        let calendar = Calendar.current
                        var dateComponents = DateComponents()
                        dateComponents.second = Int(selectedMachine.timeInSeconds)
                        if let startTime = updatedMachines[index].startTime,
                           let finishingDate = calendar.date(byAdding: dateComponents, to: startTime) {
                            updatedMachines[index].endTime =  finishingDate
                        } else {
                            // Handle the case when time attributes are nil
                            print("Failed to calculate the finishing date")
                        }
                        machines = updatedMachines
                    }
                    
                    // Simulating the machine finish after its duration
                    DispatchQueue.main.asyncAfter(deadline: .now() + selectedMachine.timeInSeconds) {
                        // Increment product count for the selected machine
                        totalProductCount += 1
                        
                        // Send a notification indicating the machine has finished
                        sendFinishNotification(for: selectedMachine)
                        
                        // Update the machine's count
                        if let index = machines.firstIndex(where: { $0.id == selectedMachine.id }) {
                            var updatedMachines = machines
                            updatedMachines[index].productCount += 1
                            updatedMachines[index].isRunning = false // Update machine's running state
                            machines = updatedMachines
                        }
                    }
                    
                    // Show the alert
                    showAlert = true
                }) {
                    Text("Start Machine")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .disabled(!isMachineSelected || isMachineRunning)
                }
                .padding()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Machine Successfully Started!"), message: Text("The machine has been successfully started."), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func sendFinishNotification(for machine: Machine) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Machine \(machine.name) Finished"
        content.body = "The machine \(machine.name) has finished its task."
        content.sound = UNNotificationSound.default
        
        // Create a trigger for the notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create a request with a unique identifier for the notification
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // Add the notification request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendAlreadyRunningNotification(for machine: Machine) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Machine \(machine.name) Already Running"
        content.body = "The machine \(machine.name) is already running."
        content.sound = UNNotificationSound.default
        
        // Create a trigger for the notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create a request with a unique identifier for the notification
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // Add the notification request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }
}


class CardViewModel: ObservableObject {
    // Hold the curren time
    @Published var currentTime = Date()
    
    // Create object to update
    var timer: Timer?
    
    func startTimer() {
        // Update the current time every second
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }
    
    func stopTimer() {
        // Invalidate the timer
        timer?.invalidate()
        // Set timer back to nil
        timer = nil
    }
}

struct CardView: View {
    // Machine display
    let machine: Machine
    // Selected machine from parent view
    @Binding var selectedMachine: Machine?
    // Time countdown view
    @StateObject private var viewModel = CardViewModel()
    
    var body: some View {
        VStack {
            Text(machine.name)
                .font(.title)
                .foregroundColor(selectedMachine == machine ? .white : .black)
                .padding()
                .background(selectedMachine == machine ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(10)
            
            Text("Product: \(Int(machine.productCount))")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 4)
            
            if machine.isRunning, let endTime = machine.endTime {
                let timeLeft = max(0, endTime.timeIntervalSince(viewModel.currentTime)) // Ensure the countdown is never negative
                Text("Countdown: \(formatTime(timeLeft))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                    .onAppear {
                        viewModel.startTimer() // Start the timer
                    }
                    .onDisappear {
                        viewModel.stopTimer() // Stop the timer
                    }
            }
        }
        .onReceive(viewModel.$currentTime) { _ in
            // Update view when countdown changes
            self.viewModel.objectWillChange.send()
        }
        .onChange(of: machine.isRunning) { isRunning in
            if isRunning {
                viewModel.startTimer() // Start the timer when machine starts running
            } else {
                viewModel.stopTimer() // Stop the timer when machine finishes or is no longer selected
            }
        }
        .onChange(of: selectedMachine) { newSelectedMachine in
            if newSelectedMachine != machine {
                viewModel.stopTimer() // Stop the timer when machine is no longer selected
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        // Specify the units
        formatter.allowedUnits = [.hour, .minute, .second]
        // Shorten the displayed time
        formatter.unitsStyle = .abbreviated
        // Format the time
        return formatter.string(from: time) ?? ""
    }
}


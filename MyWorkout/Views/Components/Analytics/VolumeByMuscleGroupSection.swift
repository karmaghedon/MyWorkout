import SwiftUI

struct VolumeByMuscleGroupSection: View {
    let volumeByMuscleGroup: [(muscle: String, sets: Int)]

    var body: some View {
        Section {
            if volumeByMuscleGroup.isEmpty {
                Text("No volume data yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(volumeByMuscleGroup, id: \.muscle) { item in
                    HStack {
                        Text(item.muscle)
                        Spacer()
                        Text("\(item.sets) sets")
                            .bold()
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        } header: {
            Label("Volume by Muscle Group", systemImage: "chart.pie.fill")
        }
    }
}

#Preview {
    List {
        VolumeByMuscleGroupSection(volumeByMuscleGroup: [
            (muscle: "Chest", sets: 24),
            (muscle: "Back", sets: 20)
        ])
    }
}

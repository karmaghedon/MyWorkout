import SwiftUI

struct VolumeByMuscleGroupSection: View {
    let volumeByMuscleGroup: [MuscleGroupVolume]

    var body: some View {
        Section {
            if volumeByMuscleGroup.isEmpty {
                Text("No volume data yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(volumeByMuscleGroup) { item in
                    HStack {
                        Text(item.muscleGroup.displayName)

                        Spacer()

                        Text("\(item.setCount) sets")
                            .bold()
                    }
                    .accessibilityElement(
                        children: .combine
                    )
                }
            }
        } header: {
            Label(
                "Volume by Muscle Group",
                systemImage: "chart.pie.fill"
            )
        }
    }
}

#Preview {
    List {
        VolumeByMuscleGroupSection(
            volumeByMuscleGroup: [
                MuscleGroupVolume(
                    muscleGroup: .chest,
                    setCount: 24
                ),
                MuscleGroupVolume(
                    muscleGroup: .back,
                    setCount: 20
                )
            ]
        )
    }
}

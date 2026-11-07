//
//  ChallengesView.swift
//  Productive - Joinable Multi-Day Habit Challenges & Milestone Achievement Badges
//

import SwiftUI

public struct ChallengesView: View {
    @EnvironmentObject var habitStore: HabitStore
    
    private var joinedChallenges: [HabitChallenge] {
        habitStore.challenges.filter { $0.isJoined }
    }
    
    private var availableChallenges: [HabitChallenge] {
        habitStore.challenges.filter { !$0.isJoined }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // Active Challenges
                if !joinedChallenges.isEmpty {
                    Section(header: Text("Active Challenges")) {
                        ForEach(joinedChallenges) { challenge in
                            let doneDays = habitStore.challengeCompletedDays(challenge)
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(hex: challenge.colorHex))
                                            .frame(width: 42, height: 42)
                                        Image(systemName: challenge.icon)
                                            .foregroundStyle(.white)
                                            .font(.headline)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(challenge.title)
                                            .font(.system(.headline, design: .rounded).weight(.bold))
                                        Text("Day \(doneDays) of \(challenge.durationDays) completed")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("Leave", role: .destructive) {
                                        habitStore.leaveChallenge(id: challenge.id)
                                    }
                                    .font(.caption.weight(.semibold))
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                }
                                
                                ProgressView(value: Double(doneDays), total: Double(max(1, challenge.durationDays)))
                                    .tint(Color(hex: challenge.colorHex))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Discover & Join Challenges
                Section(
                    header: Text("Guided Multi-Day Programs"),
                    footer: Text("Joining a challenge automatically creates or links its daily habit on your Today timeline.")
                ) {
                    ForEach(availableChallenges) { challenge in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hex: challenge.colorHex))
                                    .frame(width: 42, height: 42)
                                Image(systemName: challenge.icon)
                                    .foregroundStyle(.white)
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(challenge.title)
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                Text(challenge.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                habitStore.joinChallenge(id: challenge.id)
                            } label: {
                                Text("Join \(challenge.durationDays)d")
                                    .font(.caption.weight(.bold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: challenge.colorHex))
                            .buttonBorderShape(.capsule)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 3)
                    }
                }
                
                // Unlockable Milestone Badges
                Section(header: Text("Milestone Badges")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(habitStore.achievementBadges) { badge in
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(badge.isUnlocked ? Color(hex: badge.colorHex) : Color.secondary.opacity(0.16))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: badge.icon)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(badge.isUnlocked ? .white : .secondary)
                                        .symbolEffect(.bounce, value: badge.isUnlocked)
                                }
                                
                                Text(badge.title)
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundStyle(badge.isUnlocked ? .primary : .secondary)
                                
                                Text(badge.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .opacity(badge.isUnlocked ? 1.0 : 0.65)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Challenges")
        }
    }
}

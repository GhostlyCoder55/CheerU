import SwiftUI
import UserNotifications

// MARK: - Rotation Lock
struct RotationLockModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }
    }
}

extension View {
    func lockRotation() -> some View {
        self.modifier(RotationLockModifier())
    }
}

// MARK: - Mood Data Model
struct MoodEntry: Codable, Identifiable {
    var id = UUID()
    let mood: MoodType
    let date: Date
    
    enum MoodType: String, CaseIterable, Codable {
        case anxious = "anxious"
        case sad = "sad"
        case angry = "angry"
        case neutral = "neutral"
        
        var color: Color {
            switch self {
            case .anxious: return Color(red: 0.4, green: 0.2, blue: 0.0) // Brown
            case .sad: return Color(red: 0.0, green: 0.3, blue: 0.6) // Dark blue
            case .angry: return Color(red: 0.6, green: 0.0, blue: 0.0) // Dark red
            case .neutral: return Color(red: 0.3, green: 0.3, blue: 0.3) // Dark gray
            }
        }
    }
}

// MARK: - Mood Storage Manager
class MoodStorage: ObservableObject {
    @Published var moodEntries: [MoodEntry] = []
    private let userDefaults = UserDefaults.standard
    private let moodEntriesKey = "moodEntries"
    
    init() {
        loadMoodEntries()
    }
    
    func addMoodEntry(_ mood: MoodEntry.MoodType) {
        let entry = MoodEntry(mood: mood, date: Date())
        moodEntries.append(entry)
        saveMoodEntries()
    }
    
    func getRecentMoodTrend() -> MoodEntry.MoodType? {
        let recentEntries = moodEntries.suffix(7) // Last 7 entries
        guard !recentEntries.isEmpty else { return nil }
        
        let moodCounts = Dictionary(grouping: recentEntries, by: { $0.mood })
            .mapValues { $0.count }
        
        return moodCounts.max(by: { $0.value < $1.value })?.key
    }
    
    func getMostRecentMood() -> MoodEntry.MoodType? {
        return moodEntries.last?.mood
    }
    
    private func saveMoodEntries() {
        if let encoded = try? JSONEncoder().encode(moodEntries) {
            userDefaults.set(encoded, forKey: moodEntriesKey)
        }
    }
    
    private func loadMoodEntries() {
        if let data = userDefaults.data(forKey: moodEntriesKey),
           let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            moodEntries = decoded
        }
    }
}

// MARK: - Notification Settings Manager
class NotificationSettings: ObservableObject {
    @Published var dailyNotifications: Bool = true
    @Published var notificationTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    
    private let userDefaults = UserDefaults.standard
    private let dailyKey = "dailyNotifications"
    private let timeKey = "notificationTime"
    
    init() {
        loadSettings()
        // Schedule notifications if enabled
        if dailyNotifications {
            scheduleDailyNotifications()
        }
    }
    
    func toggleDailyNotifications() {
        dailyNotifications.toggle()
        saveSettings()
        if dailyNotifications {
            scheduleDailyNotifications()
        } else {
            cancelDailyNotifications()
        }
    }
    
    func updateNotificationTime(_ newTime: Date) {
        notificationTime = newTime
        saveSettings()
        if dailyNotifications {
            scheduleDailyNotifications()
        }
    }
    
    private func saveSettings() {
        userDefaults.set(dailyNotifications, forKey: dailyKey)
        userDefaults.set(notificationTime, forKey: timeKey)
    }
    
    private func loadSettings() {
        dailyNotifications = userDefaults.object(forKey: dailyKey) as? Bool ?? true
        notificationTime = userDefaults.object(forKey: timeKey) as? Date ?? Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    }
    
    private func scheduleDailyNotifications() {
        // Cancel existing notifications first
        cancelDailyNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = "CheerUp!"
        content.body = "Time for your daily dose of positivity!"
        content.sound = .default
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: notificationTime)
        let minute = calendar.component(.minute, from: notificationTime)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyCompliment", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func cancelDailyNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyCompliment"])
    }
}

// MARK: - Streak and Badge System
class StreakTracker: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalDays: Int = 0
    @Published var earnedBadges: [BadgeType] = []
    
    private let userDefaults = UserDefaults.standard
    private let streakKey = "currentStreak"
    private let longestStreakKey = "longestStreak"
    private let totalDaysKey = "totalDays"
    private let badgesKey = "earnedBadges"
    private let lastCheckInKey = "lastCheckIn"
    
    enum BadgeType: String, CaseIterable, Codable {
        case firstCheckIn = "first_check_in"
        case threeDayStreak = "three_day_streak"
        case weekStreak = "week_streak"
        case twoWeekStreak = "two_week_streak"
        case monthStreak = "month_streak"
        case twoMonthStreak = "two_month_streak"
        case threeMonthStreak = "three_month_streak"
        case sixMonthStreak = "six_month_streak"
        case yearStreak = "year_streak"
        case totalDays10 = "total_days_10"
        case totalDays50 = "total_days_50"
        case totalDays100 = "total_days_100"
        case totalDays365 = "total_days_365"
        
        var title: String {
            switch self {
            case .firstCheckIn: return "First Step"
            case .threeDayStreak: return "Getting Started"
            case .weekStreak: return "Week Warrior"
            case .twoWeekStreak: return "Two Week Champion"
            case .monthStreak: return "Monthly Master"
            case .twoMonthStreak: return "Two Month Hero"
            case .threeMonthStreak: return "Quarter Champion"
            case .sixMonthStreak: return "Half Year Hero"
            case .yearStreak: return "Year Legend"
            case .totalDays10: return "Decade Dabbler"
            case .totalDays50: return "Half Century"
            case .totalDays100: return "Century Club"
            case .totalDays365: return "Daily Devotee"
            }
        }
        
        var description: String {
            switch self {
            case .firstCheckIn: return "Completed your first check-in!"
            case .threeDayStreak: return "3-day streak achieved!"
            case .weekStreak: return "7-day streak achieved!"
            case .twoWeekStreak: return "14-day streak achieved!"
            case .monthStreak: return "30-day streak achieved!"
            case .twoMonthStreak: return "60-day streak achieved!"
            case .threeMonthStreak: return "90-day streak achieved!"
            case .sixMonthStreak: return "180-day streak achieved!"
            case .yearStreak: return "365-day streak achieved!"
            case .totalDays10: return "10 total check-ins!"
            case .totalDays50: return "50 total check-ins!"
            case .totalDays100: return "100 total check-ins!"
            case .totalDays365: return "365 total check-ins!"
            }
        }
        
        var icon: String {
            switch self {
            case .firstCheckIn: return "star.fill"
            case .threeDayStreak: return "flame.fill"
            case .weekStreak: return "figure.walk"
            case .twoWeekStreak: return "trophy.fill"
            case .monthStreak: return "crown.fill"
            case .twoMonthStreak: return "star.circle.fill"
            case .threeMonthStreak: return "diamond.fill"
            case .sixMonthStreak: return "medal.fill"
            case .yearStreak: return "rosette"
            case .totalDays10: return "target"
            case .totalDays50: return "party.popper.fill"
            case .totalDays100: return "gift.fill"
            case .totalDays365: return "sparkles"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .firstCheckIn: return .yellow
            case .threeDayStreak: return .orange
            case .weekStreak: return .blue
            case .twoWeekStreak: return .yellow
            case .monthStreak: return .purple
            case .twoMonthStreak: return .cyan
            case .threeMonthStreak: return .pink
            case .sixMonthStreak: return .red
            case .yearStreak: return .green
            case .totalDays10: return .mint
            case .totalDays50: return .indigo
            case .totalDays100: return .teal
            case .totalDays365: return .yellow
            }
        }
    }
    
    init() {
        loadData()
        checkStreak()
    }
    
    func recordCheckIn() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastCheckIn = userDefaults.object(forKey: lastCheckInKey) as? Date
        
        // Check if this is a new day
        if lastCheckIn == nil || !Calendar.current.isDate(lastCheckIn!, inSameDayAs: today) {
            updateStreak()
            totalDays += 1
            checkForBadges()
            saveData()
        }
    }
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastCheckIn = userDefaults.object(forKey: lastCheckInKey) as? Date
        
        if let lastCheckIn = lastCheckIn {
            let daysBetween = Calendar.current.dateComponents([.day], from: lastCheckIn, to: today).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysBetween > 1 {
                // Streak broken
                currentStreak = 1
            }
            // If daysBetween == 0, it's the same day, don't update
        } else {
            // First check-in
            currentStreak = 1
        }
        
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        userDefaults.set(today, forKey: lastCheckInKey)
    }
    
    private func checkForBadges() {
        let newBadges: [BadgeType] = [
            .firstCheckIn,
            .threeDayStreak,
            .weekStreak,
            .twoWeekStreak,
            .monthStreak,
            .twoMonthStreak,
            .threeMonthStreak,
            .sixMonthStreak,
            .yearStreak,
            .totalDays10,
            .totalDays50,
            .totalDays100,
            .totalDays365
        ]
        
        for badge in newBadges {
            if !earnedBadges.contains(badge) {
                let shouldEarn = shouldEarnBadge(badge)
                if shouldEarn {
                    earnedBadges.append(badge)
                }
            }
        }
    }
    
    private func shouldEarnBadge(_ badge: BadgeType) -> Bool {
        switch badge {
        case .firstCheckIn:
            return totalDays >= 1
        case .threeDayStreak:
            return currentStreak >= 3
        case .weekStreak:
            return currentStreak >= 7
        case .twoWeekStreak:
            return currentStreak >= 14
        case .monthStreak:
            return currentStreak >= 30
        case .twoMonthStreak:
            return currentStreak >= 60
        case .threeMonthStreak:
            return currentStreak >= 90
        case .sixMonthStreak:
            return currentStreak >= 180
        case .yearStreak:
            return currentStreak >= 365
        case .totalDays10:
            return totalDays >= 10
        case .totalDays50:
            return totalDays >= 50
        case .totalDays100:
            return totalDays >= 100
        case .totalDays365:
            return totalDays >= 365
        }
    }
    
    private func checkStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastCheckIn = userDefaults.object(forKey: lastCheckInKey) as? Date
        
        if let lastCheckIn = lastCheckIn {
            let daysBetween = Calendar.current.dateComponents([.day], from: lastCheckIn, to: today).day ?? 0
            
            if daysBetween > 1 {
                // Streak broken
                currentStreak = 0
                saveData()
            }
        }
    }
    
    private func saveData() {
        userDefaults.set(currentStreak, forKey: streakKey)
        userDefaults.set(longestStreak, forKey: longestStreakKey)
        userDefaults.set(totalDays, forKey: totalDaysKey)
        
        if let encoded = try? JSONEncoder().encode(earnedBadges) {
            userDefaults.set(encoded, forKey: badgesKey)
        }
    }
    
    private func loadData() {
        currentStreak = userDefaults.integer(forKey: streakKey)
        longestStreak = userDefaults.integer(forKey: longestStreakKey)
        totalDays = userDefaults.integer(forKey: totalDaysKey)
        
        if let data = userDefaults.data(forKey: badgesKey),
           let decoded = try? JSONDecoder().decode([BadgeType].self, from: data) {
            earnedBadges = decoded
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var moodStorage = MoodStorage()
    @StateObject private var notificationSettings = NotificationSettings()
    @StateObject private var streakTracker = StreakTracker()
    @State private var showMoodTracker = true
    
    let compliments = ["You are a precious stardust!"]
    @State private var currentCompliment: String? = nil
    @State private var backgroundColor: Color = Color.black
    @State private var bounce: Bool = false
    @State private var showAboutPopup: Bool = false
    @State private var complimentOpacity: Double = 0.0
    @State private var isTransitioning: Bool = false

    var body: some View {
        Group {
            if showMoodTracker {
                MoodTrackerView(
                    moodStorage: moodStorage,
                    notificationSettings: notificationSettings,
                    streakTracker: streakTracker,
                    onMoodSelected: {
                        showMoodTracker = false
                    }
                )
            } else {
                HomePageView(
                    moodStorage: moodStorage,
                    showMoodTracker: $showMoodTracker,
                    backgroundColor: $backgroundColor,
                    bounce: $bounce,
                    showAboutPopup: $showAboutPopup,
                    complimentOpacity: $complimentOpacity,
                    isTransitioning: $isTransitioning,
                    currentCompliment: $currentCompliment,
                    compliments: compliments,
                    generateCompliment: generateCompliment,
                    getMoodAdaptedCompliment: getMoodAdaptedCompliment
                )
            }
        }
        .onAppear {
            requestNotificationPermission()
            // Check if it's a new day and reset mood tracker if needed
            if !checkIfMoodSelectedToday() {
                showMoodTracker = true
            }
        }
        .lockRotation()
    }

    func generateCompliment() {
        if isTransitioning { return } // Prevent animation conflicts
        isTransitioning = true

        withAnimation(.easeInOut(duration: 0.5)) {
            complimentOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let selectedCompliment = getMoodAdaptedCompliment()
            currentCompliment = selectedCompliment
            
            withAnimation(.easeInOut(duration: 0.5)) {
                complimentOpacity = 1.0
                backgroundColor = Color(
                    red: Double.random(in: 0...0.7),
                    green: Double.random(in: 0...0.7),
                    blue: Double.random(in: 0...0.7)
                )
            }
            isTransitioning = false
        }
    }
    
    func checkIfMoodSelectedToday() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return moodStorage.moodEntries.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: today)
        }
    }
    
    func getMoodAdaptedCompliment() -> String {
        guard let currentMood = moodStorage.getMostRecentMood() else {
            return compliments.randomElement() ?? "You are amazing!"
        }
        
        let moodSpecificCompliments: [MoodEntry.MoodType: [String]] = [
            .sad: [
                "You're stronger than you think!",
                "This feeling is temporary, but your strength is permanent!",
                "You've overcome challenges before, and you'll overcome this too!",
                "Your resilience is inspiring!",
                "Even on tough days, you're still amazing!",
                "You're not alone in this!",
                "Your courage to keep going is admirable!",
                "Better days are ahead, and you deserve them!",
                "You're doing better than you think!",
                "Your feelings are valid, and so is your strength.",
                "You have survived 100% of your worst days!",
                "Your pain is real, but so is your strength!",
                "You're allowed to feel sad - it shows you care!",
                "Every storm runs out of rain eventually!",
                "You're braver than you believe and stronger than you seem!",
                "Your heart is healing, even when it doesn't feel like it!",
                "You've got this, even when it feels like you don't!",
                "Your tears are proof of your capacity to feel deeply!",
                "You're not broken - you're human!",
                "Tomorrow is a new day with new possibilities!",
                "You are loved and valued!",
                "Your sadness shows your beautiful depth of feeling!",
                "You have the power to turn this around!",
                "Your strength is growing even in this moment!",
                "You are worthy of happiness and joy!",
                "Your sadness is a sign of your beautiful, caring heart!",
                "You're allowed to feel sad - it's part of being human!",
                "Your tears are healing waters for your soul!",
                "You have the strength to weather any emotional storm!",
                "Your sadness shows you have the capacity for deep love!",
                "You're not alone in your feelings - many people care about you!",
                "Your pain is temporary, but your growth is permanent!",
                "You have survived every difficult moment in your life!",
                "Your sadness doesn't define you - your resilience does!",
                "You're learning to be gentle with yourself - that's beautiful!",
                "Your feelings are valid, and your experience matters!",
                "You have the power to find light even in dark moments!",
                "Your sadness shows you're alive and feeling deeply!",
                "You're building emotional strength with every challenge!",
                "Your heart is healing, even when it doesn't feel like it!",
                "You have the wisdom to know that this too shall pass!",
                "Your sadness is a teacher, not a punishment!",
                "You're growing stronger through every difficult experience!",
                "You have the inner light to guide you through any darkness!"
            ],
            .angry: [
                "Your passion shows you care deeply!",
                "It's okay to feel this way - you're human!",
                "Your energy can be channeled into something amazing!",
                "You have the power to transform this feeling!",
                "Your intensity shows your commitment to what matters!",
                "Take a deep breath - you've got this!",
                "Your fire can light up the world in positive ways!",
                "You're allowed to feel, and you're still wonderful!",
                "This feeling will pass, but your strength remains!",
                "You have the power to choose your response!",
                "Your anger shows you have boundaries and standards!",
                "You're not wrong for feeling this way!",
                "Your passion is a superpower when channeled right!",
                "You have every right to feel angry sometimes!",
                "Your fire can forge something beautiful!",
                "You're learning to use your energy wisely!",
                "Your intensity is a gift, not a curse!",
                "You're growing stronger through every challenge!",
                "Your feelings are valid and important!",
                "You have the wisdom to handle this situation!",
                "Even strong emotions are part of your beautiful depth!",
                "This storm in you will calm — you control the waves!",
                "You're powerful even in moments of frustration!",
                "Every emotion you feel teaches you something valuable!",
                "Your awareness of your anger shows emotional growth!",
                "You can turn this heat into determination and focus!",
                "It's okay to pause — peace is waiting for you!",
                "Your honesty with yourself is admirable!",
                "You care deeply — that's what makes you human!",
                "The fact that you feel means your heart is alive!",
                "You can take this energy and build something great!",
                "Your courage to face your feelings is inspiring!",
                "You're learning to find calm in chaos!",
                "Even fire needs rest — take your time.",
                "You're strong enough to let go when it's time.",
                "Your awareness brings healing every time you breathe.",
                "You are not defined by your anger, but by your heart.",
                "You're doing your best, and that's enough right now.",
                "You have what it takes to turn this moment around.",
                "The world needs your passion — in your own time.",
                "You are grounded, even when emotions rise high.",
                "You are in control, even when it feels messy.",
                "You've made it through worse — you'll make it through this.",
                "You're growing, not breaking.",
                "Peace is closer than you think — just breathe.",
                "Your calm will return — it always does.",
                "Your strength is showing, even in frustration.",
                "You're allowed to slow down and reset.",
                "You have so much light — don't let anger dim it.",
                "Every deep feeling reminds you that you care.",
                "Your anger shows you have strong values!",
                "You can use this energy to create positive change!",
                "Your passion is a sign of your caring heart!",
                "Your anger shows you have strong convictions and values!",
                "You have the power to channel this energy into positive action!",
                "Your intensity is a gift when directed toward what matters!",
                "You're allowed to feel angry - it shows you care deeply!",
                "Your anger is temporary, but your passion is permanent!",
                "You have the wisdom to know when to pause and breathe!",
                "Your fire can light the way for positive change!",
                "You're learning to use your energy wisely - that's growth!",
                "Your anger shows you have boundaries and self-respect!",
                "You have the strength to transform frustration into determination!",
                "Your passion is a superpower when channeled correctly!",
                "You're not wrong for feeling this way - your feelings are valid!",
                "You have the power to choose how you respond to this energy!",
                "Your anger shows you have a strong sense of justice!",
                "You're building emotional intelligence with every challenge!",
                "Your fire can forge something beautiful from this moment!",
                "You have the courage to face your feelings honestly!",
                "Your anger is a messenger - listen to what it's telling you!",
                "You have the inner strength to handle any emotional storm!"
            ],
            .anxious: [
                "Your feelings are completely valid and understandable.",
                "You're stronger than your anxiety - you've got this.",
                "It's okay to feel anxious - you're human.",
                "Your courage to face each day is truly admirable.",
                "You're not alone in this feeling.",
                "Your anxiety doesn't define you - your strength does.",
                "You've overcome anxious moments before, and you will again.",
                "Your self-awareness shows incredible emotional intelligence.",
                "It's okay to take things one step at a time.",
                "Your feelings are temporary, but your resilience is permanent.",
                "You're doing better than you think you are.",
                "Your anxiety shows you care deeply about things.",
                "You have the tools and strength to handle this.",
                "It's perfectly okay to feel overwhelmed sometimes.",
                "Your courage to keep going is inspiring.",
                "You're not broken - you're beautifully human.",
                "Your feelings are real, and so is your ability to cope.",
                "You've survived 100% of your anxious days so far.",
                "Your anxiety is just one part of your complex, wonderful self.",
                "You're allowed to feel anxious and still be amazing.",
                "Your awareness of your anxiety shows incredible strength.",
                "You have the power to calm your mind and find peace.",
                "Your anxiety is temporary, but your courage is permanent.",
                "You're learning to manage your feelings - that's growth.",
                "Your sensitivity is a gift, not a weakness.",
                "You have survived every anxious moment before this one.",
                "Your anxiety shows you have a caring, thoughtful heart.",
                "You're stronger than you feel right now.",
                "Your feelings are valid, and so is your strength.",
                "You have everything you need to get through this.",
                "Your anxiety is a sign of your deep caring nature.",
                "You're building resilience with every anxious moment you face.",
                "Your feelings are messengers, not masters - you're in control.",
                "You have the wisdom to know when to slow down and breathe.",
                "Your anxiety shows you're alive and feeling deeply.",
                "You're not failing - you're learning to navigate your emotions.",
                "Your courage to acknowledge anxiety is incredibly brave.",
                "You have survived every single anxious moment in your life.",
                "Your anxiety doesn't make you weak - it makes you human.",
                "You're allowed to feel anxious and still be worthy of love.",
                "Your sensitivity is a superpower in a world that needs more care.",
                "You're growing stronger with every challenge you face.",
                "Your anxiety is temporary, but your strength is forever.",
                "You have the power to transform anxiety into awareness.",
                "You're not alone in feeling this way - many people understand.",
                "Your anxiety shows you have a beautiful, complex inner world.",
                "You're learning to be gentle with yourself - that's progress.",
                "Your feelings are valid, and your journey is important.",
                "You have the inner resources to handle whatever comes your way."
            ],
            .neutral: [
                "You're perfectly balanced and that's beautiful!",
                "Your calm presence is a gift!",
                "You handle life with such grace!",
                "Your steady nature is admirable!",
                "You're exactly where you need to be!",
                "Your peacefulness is inspiring!",
                "You bring stability to those around you!",
                "Your balanced approach to life is wonderful!",
                "You're a steady force of good in this world!",
                "Your calm confidence is beautiful!",
                "Your zen energy is absolutely refreshing!",
                "You're the calm in everyone's storm!",
                "Your peaceful presence is a blessing!",
                "You handle everything with such poise!",
                "Your balanced perspective is truly valuable!",
                "You're exactly the right amount of everything!",
                "Your steady energy is exactly what the world needs!",
                "You're perfectly content and that's perfect!",
                "Your calm confidence is incredibly attractive!",
                "You make peace look effortless and beautiful!",
                "Your stability is a superpower!",
                "You bring peace to every situation!",
                "Your balanced energy is exactly what's needed!",
                "You're a rock of stability in a chaotic world!",
                "Your calmness is a gift to everyone around you!",
                "You make being centered look absolutely beautiful!",
                "Your peaceful energy is healing!",
                "You're proof that balance is beautiful!",
                "Your steady presence makes everything better!",
                "You're exactly the calm the world needs right now!",
                "Your balanced energy creates harmony wherever you go!",
                "You have the gift of finding peace in any situation!",
                "Your steady presence is a beacon of stability!",
                "You're proof that strength comes in many forms!",
                "Your calm confidence is incredibly attractive!",
                "You have the wisdom to know when to be still!",
                "Your peaceful nature is a blessing to those around you!",
                "You're creating a sanctuary of calm in a chaotic world!",
                "Your balanced approach to life is truly inspiring!",
                "You have the power to bring peace to any moment!",
                "Your steady energy is exactly what's needed right now!",
                "You're a master of finding the middle ground!",
                "Your calm presence makes everything feel more manageable!",
                "You have the gift of being present and centered!",
                "Your peaceful energy is like a gentle breeze!",
                "You're proof that balance is the key to everything!",
                "Your steady nature is a gift in an uncertain world!",
                "You have the wisdom to know that peace is powerful!",
                "Your calm confidence is a superpower in disguise!"
            ]
        ]
        
        let moodCompliments = moodSpecificCompliments[currentMood] ?? compliments
        return moodCompliments.randomElement() ?? compliments.randomElement() ?? "You are amazing!"
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permission granted")
            } else {
                print("Permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

// MARK: - About Popup View
struct AboutPopupView: View {
    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Text("About CheerUp!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        MessageBubble(text: "Hey, what's this app about?", isUser: true, sender: "You")
                        MessageBubble(text: "CheerUp! is an app made to boost your mood and emotional well-being. Just pick how you feel!", isUser: false, sender: "CheerUp!")
                        MessageBubble(text: "Say less! Wait, how does it work though?", isUser: true, sender: "You")
                        MessageBubble(text: "Simply choose your current mood, and it will generate uplifting compliments based on how you're feeling.", isUser: false, sender: "CheerUp!")
                        MessageBubble(text: "I see. Preciate it!", isUser: true, sender: "You")
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Message Bubble Component
struct MessageBubble: View {
    let text: String
    let isUser: Bool
    let sender: String
    
    var body: some View {
        HStack {
            if !isUser { Spacer() }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
                Text(text)
                    .padding()
                    .background(isUser ? Color.blue : Color.gray.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(15)
                
                Text(sender)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, isUser ? 0 : 5)
                    .padding(.trailing, isUser ? 5 : 0)
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            
            if isUser { Spacer() }
        }
        .padding(.horizontal)
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @ObservedObject var notificationSettings: NotificationSettings
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Alerts")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                VStack(spacing: 20) {
                    Text("Choose when you'd like to receive your daily compliment")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        HStack {
                            Text("Notifications")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { notificationSettings.dailyNotifications },
                                set: { _ in notificationSettings.toggleDailyNotifications() }
                            ))
                        }
                        
                        if notificationSettings.dailyNotifications {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Time")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                DatePicker("", selection: Binding(
                                    get: { notificationSettings.notificationTime },
                                    set: { notificationSettings.updateNotificationTime($0) }
                                ), displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .colorScheme(.dark)
                                .accentColor(.white)
                            }
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut(duration: 0.3), value: notificationSettings.dailyNotifications)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding()
                .frame(width: 200)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                )
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Streak View
struct StreakView: View {
    @ObservedObject var streakTracker: StreakTracker
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Text("Your Streak")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Current Streak Display
                    VStack(spacing: 15) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("\(streakTracker.currentStreak)")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Day Streak")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                    )
                    
                    // Stats
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(streakTracker.longestStreak)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Best Streak")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                        )
                        
                        VStack {
                            Text("\(streakTracker.totalDays)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Total Days")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    
                    // Badges Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Badges Earned")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if streakTracker.earnedBadges.isEmpty {
                            Text("Complete your first check-in to earn your first badge!")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding()
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                                ForEach(streakTracker.earnedBadges, id: \.self) { badge in
                                    VStack(spacing: 8) {
                                        Image(systemName: badge.icon)
                                            .font(.system(size: 25))
                                            .foregroundColor(badge.iconColor)
                                        
                                        Text(badge.title)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // All Available Badges
                    VStack(alignment: .leading, spacing: 15) {
                        Text("All Badges")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                            ForEach(StreakTracker.BadgeType.allCases, id: \.self) { badge in
                                VStack(spacing: 8) {
                                    Image(systemName: badge.icon)
                                        .font(.system(size: 25))
                                        .foregroundColor(badge.iconColor)
                                        .opacity(streakTracker.earnedBadges.contains(badge) ? 1.0 : 0.3)
                                    
                                    Text(badge.title)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(streakTracker.earnedBadges.contains(badge) ? .white : .gray)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(streakTracker.earnedBadges.contains(badge) ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                }
            }
            
            VStack {
                Spacer()
                
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding()
                .frame(width: 200)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                )
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Home Page View (Compliment Display)
struct HomePageView: View {
    @ObservedObject var moodStorage: MoodStorage
    @Binding var showMoodTracker: Bool
    @Binding var backgroundColor: Color
    @Binding var bounce: Bool
    @Binding var showAboutPopup: Bool
    @Binding var complimentOpacity: Double
    @Binding var isTransitioning: Bool
    @Binding var currentCompliment: String?
    let compliments: [String]
    let generateCompliment: () -> Void
    let getMoodAdaptedCompliment: () -> String
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack {
                Spacer()
                Text("CheerUp!")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: bounce ? -10 : 10)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                            bounce.toggle()
                        }
                    }
                
                Spacer()
                ZStack {
                    if let compliment = currentCompliment {
                        Text(compliment)
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.3))
                                    .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal, 30)
                            .multilineTextAlignment(.center)
                            .opacity(complimentOpacity)
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut(duration: 0.3), value: complimentOpacity)
                            .zIndex(2)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    generateCompliment()
                }) {
                    Text("Tap Here!")
                        .font(.title2)
                        .padding()
                        .frame(width: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                        )
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                // Back arrow button
                HStack {
                    Button(action: {
                        showMoodTracker = true
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 1)
                            )
                    }
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.leading, 20)
                
                Spacer()
                
                Text("Created by\nChristopher Ogbonnaya")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .padding()
        }
    }
}

// MARK: - Mood Tracker View
struct MoodTrackerView: View {
    @ObservedObject var moodStorage: MoodStorage
    @ObservedObject var notificationSettings: NotificationSettings
    @ObservedObject var streakTracker: StreakTracker
    let onMoodSelected: () -> Void
    @State private var selectedMood: MoodEntry.MoodType? = nil
    @State private var backgroundColor: Color = Color.black
    @State private var showAboutPopup: Bool = false
    @State private var showNotificationSettings: Bool = false
    @State private var showStreakView: Bool = false
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App title
                Text("CheerUp!")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                // Mood selection
                VStack(spacing: 20) {
                    Text("How are you feeling?")
                        .font(.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                        ForEach(MoodEntry.MoodType.allCases, id: \.self) { mood in
                            Button(action: {
                                selectedMood = mood
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    backgroundColor = mood.color.opacity(0.3)
                                }
                            }) {
                                Text(mood.rawValue.capitalized)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 120, height: 80)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedMood == mood ? mood.color.opacity(0.8) : mood.color.opacity(0.4))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(selectedMood == mood ? Color.white : Color.clear, lineWidth: 2)
                                            )
                                    )
                            }
                            .scaleEffect(selectedMood == mood ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: selectedMood)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Log mood button
                if let mood = selectedMood {
                    Button(action: {
                        moodStorage.addMoodEntry(mood)
                        streakTracker.recordCheckIn()
                        onMoodSelected()
                    }) {
                        Text("Let's CheerUp!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding()
                            .frame(width: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                            )
                    }
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeInOut(duration: 0.3), value: selectedMood)
                }
                
                Spacer()
                
                // Bottom buttons - About, Streak, and Notifications
                HStack(spacing: 20) {
                    // About button
                    Button(action: {
                        showAboutPopup = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "info.circle.fill")
                                .font(.title3)
                            Text("About")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 70, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.2))
                                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 1)
                        )
                    }
                    .sheet(isPresented: $showAboutPopup) {
                        AboutPopupView()
                    }
                    
                    // Streak button
                    Button(action: {
                        showStreakView = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                            Text("\(streakTracker.currentStreak)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(width: 70, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.2))
                                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 1)
                        )
                    }
                    .sheet(isPresented: $showStreakView) {
                        StreakView(streakTracker: streakTracker)
                    }
                    
                    // Notification settings button
                    Button(action: {
                        showNotificationSettings = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.title3)
                            Text("Alerts")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 70, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.2))
                                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 1)
                        )
                    }
                    .sheet(isPresented: $showNotificationSettings) {
                        NotificationSettingsView(notificationSettings: notificationSettings)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear {
            backgroundColor = Color.black
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

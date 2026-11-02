import SwiftUI

// MARK: - Wheel Outcome Category
enum WheelOutcomeType: String, CaseIterable, Identifiable {
    case happy
    case chaos

    var id: String { rawValue }

    var badgeText: String {
        switch self {
        case .happy:  return "💛 HAPPY"
        case .chaos:  return "🌀 CHAOS"
        }
    }

    var accentColor: Color {
        switch self {
        case .happy:  return Color(hex: 0x22C55E) // Vibrant green
        case .chaos:  return Color(hex: 0xDF2955) // Cosmic crimson
        }
    }
}

// MARK: - Wheel Outcome Item
struct WheelOutcome: Identifiable {
    let id = UUID()
    let type: WheelOutcomeType
    let emoji: String
    let titleEn: String
    let titleFr: String
    let textEn: String
    let textFr: String
    let mood: MascotMood
    let timerSeconds: Int?
    let weight: Int

    var title: String {
        LanguageManager.shared.isFrench ? titleFr : titleEn
    }

    var text: String {
        LanguageManager.shared.isFrench ? textFr : textEn
    }

    init(
        type: WheelOutcomeType,
        emoji: String,
        titleEn: String,
        titleFr: String,
        textEn: String,
        textFr: String,
        mood: MascotMood,
        timerSeconds: Int? = nil,
        weight: Int = 10
    ) {
        self.type = type
        self.emoji = emoji
        self.titleEn = titleEn
        self.titleFr = titleFr
        self.textEn = textEn
        self.textFr = textFr
        self.mood = mood
        self.timerSeconds = timerSeconds
        self.weight = weight
    }
}

// MARK: - Wheel Segments Data
struct WheelSegment: Identifiable {
    let id: Int
    let color: Color
}

// MARK: - Master Wheels Dataset
enum WheelsData {
    static let segments: [WheelSegment] = [
        WheelSegment(id: 0,  color: Color(hex: 0x00A896)), // CheerUp Teal
        WheelSegment(id: 1,  color: Color(hex: 0xFF4B5C)), // Coral Red
        WheelSegment(id: 2,  color: Color(hex: 0x3D7BFF)), // Sky Blue
        WheelSegment(id: 3,  color: Color(hex: 0xFFC83D)), // Warm Yellow
        WheelSegment(id: 4,  color: Color(hex: 0x2EDB8A)), // Mint Green
        WheelSegment(id: 5,  color: Color(hex: 0x8B5CF6)), // Soft Violet
        WheelSegment(id: 6,  color: Color(hex: 0x028090)), // Deep Teal
        WheelSegment(id: 7,  color: Color(hex: 0xFF6B81)), // Rose Pink
        WheelSegment(id: 8,  color: Color(hex: 0x54A0FF)), // Soft Azure
        WheelSegment(id: 9,  color: Color(hex: 0xFECA57)), // Sunny Amber
        WheelSegment(id: 10, color: Color(hex: 0x1DD1A1)), // Fresh Emerald
        WheelSegment(id: 11, color: Color(hex: 0x5F27CD))  // Royal Indigo
    ]

    static let outcomes: [WheelOutcome] = [
        // Bizarre & Fun Challenges (Replaced compliments)
        WheelOutcome(type: .happy, emoji: "🦩", titleEn: "Flamingo Stance", titleFr: "Flamant Rose", textEn: "Balance on one leg like a flamingo for 8 seconds.", textFr: "Tenez sur une seule jambe pendant 8s.", mood: .sus, timerSeconds: 8),
        WheelOutcome(type: .happy, emoji: "👽", titleEn: "Alien Contact", titleFr: "Signal Alien", textEn: "Make high-pitched alien beeping noises right now.", textFr: "Faites des bruits d'extraterrestre suraigus.", mood: .wow),
        WheelOutcome(type: .happy, emoji: "🐱", titleEn: "Meow Order", titleFr: "Ordre Miaou", textEn: "Meow three times with total seriousness.", textFr: "Miaulez trois fois très sérieusement.", mood: .dizzy),
        WheelOutcome(type: .happy, emoji: "🕶️", titleEn: "Slow Motion", titleFr: "Mode Ralenti", textEn: "Do everything in dramatic slow motion for 10 seconds.", textFr: "Bougez au ralenti pendant 10 secondes.", mood: .sus, timerSeconds: 10),
        WheelOutcome(type: .happy, emoji: "🦖", titleEn: "T-Rex Mode", titleFr: "Mode T-Rex", textEn: "Tuck your elbows in and let out a tiny T-Rex roar.", textFr: "Rentrez les coudes et rugissez en T-Rex.", mood: .party),
        WheelOutcome(type: .happy, emoji: "🧼", titleEn: "Invisible Wash", titleFr: "Savon Imaginaire", textEn: "Aggressively wash hands with imaginary soap.", textFr: "Lavez-vous les mains au savon invisible.", mood: .dizzy, timerSeconds: 8),
        WheelOutcome(type: .happy, emoji: "🦀", titleEn: "Crab Walk", titleFr: "Mode Crabe", textEn: "Take two sideways steps and snap your crab claws.", textFr: "Faites deux pas de côté en pinçant l'air.", mood: .sus),
        WheelOutcome(type: .happy, emoji: "🧙‍♂️", titleEn: "Cast a Spell", titleFr: "Faux Sortilège", textEn: "Point at the nearest wall and shout a made-up spell.", textFr: "Pointez le mur et criez un sort inventé.", mood: .wow),
        WheelOutcome(type: .happy, emoji: "🧘", titleEn: "Bizarre Zen", titleFr: "Zen Étrange", textEn: "Chant a deep “Ooooom” until the timer runs out.", textFr: "Chantez un long « Oooom » jusqu'au bip.", mood: .happy, timerSeconds: 8),
        WheelOutcome(type: .happy, emoji: "🤫", titleEn: "Breaking News", titleFr: "Flash Info", textEn: "Whisper urgent breaking news to your nearest object.", textFr: "Chuchotez un scoop urgent à un objet proche.", mood: .dizzy),
        WheelOutcome(type: .happy, emoji: "😱", titleEn: "Soap Opera", titleFr: "Télénovela", textEn: "Gasp loudly like you just saw a telenovela plot twist.", textFr: "Prenez un air ultra choqué façon soap-opéra.", mood: .wow),
        WheelOutcome(type: .happy, emoji: "🐧", titleEn: "Penguin Waddle", titleFr: "Pingouin", textEn: "Lock knees, flap arms, and waddle like a penguin.", textFr: "Bras collés, marchez comme un pingouin.", mood: .party, timerSeconds: 7),

        // Chaos Outcomes
        WheelOutcome(type: .chaos, emoji: "🍕", titleEn: "Pizza Phone", titleFr: "Tel Pizza", textEn: "Hold phone like pizza. Say “mmm”.", textFr: "Tel façon pizza. Dites « mmm ».", mood: .sus),
        WheelOutcome(type: .chaos, emoji: "🐔", titleEn: "Chicken Mode", titleFr: "Mode Poulet", textEn: "Cluck like a chicken for 10 seconds.", textFr: "Faites la poule pendant 10s.", mood: .wow, timerSeconds: 10),
        WheelOutcome(type: .chaos, emoji: "🙃", titleEn: "Upside Down", titleFr: "À l’envers", textEn: "Universe flipped. Enjoy.", textFr: "Monde inversé. Profitez.", mood: .dizzy),
        WheelOutcome(type: .chaos, emoji: "🕺", titleEn: "Dance Order", titleFr: "Danse !", textEn: "Dance like nobody is watching.", textFr: "Dansez sans retenue.", mood: .party, timerSeconds: 10),
        WheelOutcome(type: .chaos, emoji: "🥔", titleEn: "Potato Alert", titleFr: "Alerte Patate", textEn: "You are now a potato.", textFr: "Vous êtes une patate.", mood: .sus),
        WheelOutcome(type: .chaos, emoji: "🧦", titleEn: "Sock Mystery", titleFr: "Chaussettes", textEn: "Introduce two socks to each other.", textFr: "Présentez deux chaussettes.", mood: .sus),
        WheelOutcome(type: .chaos, emoji: "📢", titleEn: "Dramatic Entrance", titleFr: "Entrée Star", textEn: "Announce “I have arrived!”", textFr: "Dites « Je suis là ! »", mood: .wow),
        WheelOutcome(type: .chaos, emoji: "🦆", titleEn: "Duck Invasion", titleFr: "Invasion Canard", textEn: "Ducks took over. Resistance is futile.", textFr: "Les canards attaquent !", mood: .dizzy),
        WheelOutcome(type: .chaos, emoji: "🤫", titleEn: "Secret Mission", titleFr: "Mission Secrète", textEn: "Walk like a spy. Do not blink.", textFr: "Marchez comme un espion.", mood: .sus, timerSeconds: 15),
        WheelOutcome(type: .chaos, emoji: "🫠", titleEn: "CheerUp Meltdown", titleFr: "CheerUp Fond", textEn: "CheerUp is melting into pixels.", textFr: "CheerUp fond en pixels.", mood: .dizzy),
        WheelOutcome(type: .chaos, emoji: "🗣️", titleEn: "Backwards Talk", titleFr: "À l'envers", textEn: "Say your name backwards out loud.", textFr: "Dites votre nom à l'envers.", mood: .wow),
        WheelOutcome(type: .chaos, emoji: "🌀", titleEn: "Absolute Nonsense", titleFr: "Non-sens", textEn: "Banana telescope purple Tuesday.", textFr: "Banane télescope mardi violet.", mood: .dizzy),
        WheelOutcome(type: .chaos, emoji: "🚀", titleEn: "Rocket Launch", titleFr: "Fusée", textEn: "Count 5 to 1 with rocket noises.", textFr: "Comptez 5 à 1 façon fusée.", mood: .wow, timerSeconds: 6),
        WheelOutcome(type: .chaos, emoji: "👁️", titleEn: "Stare Down", titleFr: "Fixette", textEn: "Stare without blinking for 8 seconds.", textFr: "Fixez 8s sans ciller.", mood: .sus, timerSeconds: 8),
        WheelOutcome(type: .chaos, emoji: "🧊", titleEn: "Freeze Frame", titleFr: "Statue", textEn: "Freeze in your current pose. Don’t move!", textFr: "Ne bougez plus d'un poil !", mood: .wow, timerSeconds: 7),
        WheelOutcome(type: .chaos, emoji: "🤖", titleEn: "Robot Mode", titleFr: "Robot", textEn: "Say “BEEP BOOP I AM HUMAN” out loud.", textFr: "Dites « BIP BOP HUMAIN ».", mood: .dizzy),
        WheelOutcome(type: .chaos, emoji: "🎸", titleEn: "Air Guitar Solo", titleFr: "Air Guitar", textEn: "Unleash an epic air guitar solo right now.", textFr: "Solo d'air guitar maintenant !", mood: .party, timerSeconds: 8),
        WheelOutcome(type: .chaos, emoji: "🗿", titleEn: "Stone Face", titleFr: "Visage de Pierre", textEn: "No smiling allowed for 10 seconds.", textFr: "Interdit de sourire 10s.", mood: .sus, timerSeconds: 10)
    ]

    static var idleLines: [String] {
        LanguageManager.shared.isFrench
            ? ["Tourne-moi !", "Jour de chance ?", "Allez, tourne !", "Prêt quand tu veux !"]
            : ["Spin me!", "Feeling lucky?", "Ooh, spin it!", "Ready when you are!"]
    }

    static var spinLines: [String] {
        LanguageManager.shared.isFrench
            ? ["Youhouuu !", "Ça tourne !", "Où ça s'arrête ?", "Accrochez-vous !"]
            : ["Wheeeee!", "Whoa whoa whoa!", "Where will it land?", "Hold onto your pixels!"]
    }

    static var happyLines: [String] {
        LanguageManager.shared.isFrench
            ? ["Défi relevé ?", "À vous de jouer !", "C'est parti !", "Montrez ce que vous valez !"]
            : ["Challenge accepted?", "Your turn!", "Let's see it!", "Show what you got!"]
    }

    static var chaosLines: [String] {
        LanguageManager.shared.isFrench
            ? ["Je te l'avais dit !", "Chaos total !", "Bonne chance !", "C'est parti !"]
            : ["Told you so!", "Absolute chaos!", "Haha, good luck!", "What have we done?!"]
    }
}

// MARK: - Wheels Particle (Confetti)
struct WheelsConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var rotation: Double
    var vr: Double
    var size: CGFloat
    var color: Color
    var opacity: Double
}

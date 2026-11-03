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
    let titleEs: String
    let textEn: String
    let textFr: String
    let textEs: String
    let mood: MascotMood
    let timerSeconds: Int?
    let weight: Int

    var title: String {
        switch LanguageManager.shared.currentLanguage {
        case .french:  return titleFr
        case .spanish: return titleEs
        case .english: return titleEn
        }
    }

    var text: String {
        switch LanguageManager.shared.currentLanguage {
        case .french:  return textFr
        case .spanish: return textEs
        case .english: return textEn
        }
    }

    init(
        type: WheelOutcomeType,
        emoji: String,
        titleEn: String,
        titleFr: String,
        titleEs: String,
        textEn: String,
        textFr: String,
        textEs: String,
        mood: MascotMood,
        timerSeconds: Int? = nil,
        weight: Int = 10
    ) {
        self.type = type
        self.emoji = emoji
        self.titleEn = titleEn
        self.titleFr = titleFr
        self.titleEs = titleEs
        self.textEn = textEn
        self.textFr = textFr
        self.textEs = textEs
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

// MARK: - Wheels Data & Outcomes
struct WheelsData {
    static let segments: [WheelSegment] = [
        WheelSegment(id: 0,  color: Color(hex: 0xFF4B5C)), // Coral Red
        WheelSegment(id: 1,  color: Color(hex: 0xFF8838)), // Tangerine
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
        // Bizarre & Fun Challenges
        WheelOutcome(type: .happy, emoji: "🦩", titleEn: "Flamingo Stance", titleFr: "Flamant Rose", titleEs: "Flamenco", textEn: "Balance on one leg like a flamingo for 8 seconds.", textFr: "Tenez sur une seule jambe pendant 8s.", textEs: "Mantén el equilibrio en un pie 8s.", mood: .sus, timerSeconds: 8),
        WheelOutcome(type: .happy, emoji: "👽", titleEn: "Alien Contact", titleFr: "Signal Alien", titleEs: "Contacto Alien", textEn: "Make high-pitched alien beeping noises right now.", textFr: "Faites des bruits d'extraterrestre suraigus.", textEs: "Haz sonidos agudos de alien ya.", mood: .wow),
        WheelOutcome(type: .happy, emoji: "🐱", titleEn: "Meow Order", titleFr: "Ordre Miaou", titleEs: "Orden Miau", textEn: "Meow three times with total seriousness.", textFr: "Miaulez trois fois très sérieusement.", textEs: "Maúlla 3 veces con total seriedad.", mood: .dizzy),
        WheelOutcome(type: .happy, emoji: "🕶️", titleEn: "Slow Motion", titleFr: "Mode Ralenti", titleEs: "Cámara Lenta", textEn: "Do everything in dramatic slow motion for 10 seconds.", textFr: "Bougez au ralenti pendant 10 secondes.", textEs: "Muévete en cámara lenta durante 10s.", mood: .sus, timerSeconds: 10),
        WheelOutcome(type: .happy, emoji: "🦖", titleEn: "T-Rex Mode", titleFr: "Mode T-Rex", titleEs: "Modo T-Rex", textEn: "Tuck your elbows in and let out a tiny T-Rex roar.", textFr: "Rentrez les coudes et rugissez en T-Rex.", textEs: "Pega los codos y ruge como un T-Rex.", mood: .party),
        WheelOutcome(type: .happy, emoji: "🧼", titleEn: "Invisible Wash", titleFr: "Savon Imaginaire", titleEs: "Jabón Invisible", textEn: "Aggressively wash hands with imaginary soap.", textFr: "Lavez-vous les mains au savon invisible.", textEs: "Lávate las manos con jabón invisible.", mood: .dizzy, timerSeconds: 8),
        WheelOutcome(type: .happy, emoji: "🦀", titleEn: "Crab Walk", titleFr: "Mode Crabe", titleEs: "Cangrejo", textEn: "Take two sideways steps and snap your crab claws.", textFr: "Faites deux pas de côté en pinçant l'air.", textEs: "Da dos pasos de lado haciendo pinzas.", mood: .sus),
        WheelOutcome(type: .happy, emoji: "🧙‍♂️", titleEn: "Cast a Spell", titleFr: "Faux Sortilège", titleEs: "Hechizo", textEn: "Point at the nearest wall and shout a made-up spell.", textFr: "Pointez le mur et criez un sort inventé.", textEs: "Apunta a la pared y grita un hechizo inventado.", mood: .wow),
        WheelOutcome(type: .happy, emoji: "🧘", titleEn: "Bizarre Zen", titleFr: "Zen Étrange", titleEs: "Zen Bizarro", textEn: "Chant a deep “Ooooom” until the timer runs out.", textFr: "Chantez un long « Oooom » jusqu'au bip.", textEs: "Entona un « Oooom » profundo hasta el timbre.", mood: .happy, timerSeconds: 8),
        WheelOutcome(type: .happy, emoji: "🤫", titleEn: "Breaking News", titleFr: "Flash Info", titleEs: "Última Hora", textEn: "Whisper urgent breaking news to your nearest object.", textFr: "Chuchotez un scoop urgent à un objet proche.", textEs: "Susurra una noticia urgente al objeto más cercano.", mood: .dizzy),
        WheelOutcome(type: .happy, emoji: "😱", titleEn: "Soap Opera", titleFr: "Télénovela", titleEs: "Telenovela", textEn: "Gasp loudly like you just saw a telenovela plot twist.", textFr: "Prenez un air ultra choqué façon soap-opéra.", textEs: "Respira hondo con dramatismo de telenovela.", mood: .wow),
        WheelOutcome(type: .happy, emoji: "🐧", titleEn: "Penguin Waddle", titleFr: "Pingouin", titleEs: "Paso Pingüino", textEn: "Lock knees, flap arms, and waddle like a penguin.", textFr: "Bras collés, marchez comme un pingouin.", textEs: "Junta las rodillas y camina como pingüino.", mood: .party, timerSeconds: 7),

        // Chaos Outcomes
        WheelOutcome(type: .chaos, emoji: "🍕", titleEn: "Pizza Phone", titleFr: "Tel Pizza", titleEs: "Pizza Móvil", textEn: "Hold phone like pizza. Say “mmm”.", textFr: "Tel façon pizza. Dites « mmm ».", textEs: "Sostén el móvil como pizza. Di « mmm ».", mood: .sus),
        WheelOutcome(type: .chaos, emoji: "🐔", titleEn: "Chicken Mode", titleFr: "Mode Poulet", titleEs: "Modo Gallina", textEn: "Cluck like a chicken for 10 seconds.", textFr: "Faites la poule pendant 10s.", textEs: "Cacarea como gallina durante 10s.", mood: .wow, timerSeconds: 10),
        WheelOutcome(type: .chaos, emoji: "🙃", titleEn: "Upside Down", titleFr: "À l’envers", titleEs: "Del Revés", textEn: "Universe flipped. Enjoy.", textFr: "Monde inversé. Profitez.", textEs: "Universo invertido. Disfruta.", mood: .dizzy),
        WheelOutcome(type: .chaos, emoji: "🕺", titleEn: "Dance Order", titleFr: "Danse !", titleEs: "¡A Bailar!", textEn: "Dance like nobody is watching.", textFr: "Dansez sans retenue.", textEs: "Baila como si nadie te mirara.", mood: .party, timerSeconds: 10),
        WheelOutcome(type: .chaos, emoji: "🥔", titleEn: "Potato Alert", titleFr: "Alerte Patate", titleEs: "Alerta Patata", textEn: "You are now a potato.", textFr: "Vous êtes une patate.", textEs: "Ahora eres una patata.", mood: .sus),
        WheelOutcome(type: .chaos, emoji: "🧦", titleEn: "Sock Mystery", titleFr: "Chaussettes", titleEs: "Calcetines", textEn: "Introduce two socks to each other.", textFr: "Présentez deux chaussettes.", textEs: "Presenta a dos calcetines entre sí.", mood: .sus),
        WheelOutcome(type: .chaos, emoji: "📢", titleEn: "Dramatic Entrance", titleFr: "Entrée Star", titleEs: "Entrada Triunfal", textEn: "Announce “I have arrived!”", textFr: "Dites « Je suis là ! »", textEs: "Anuncia con voz alta: «¡He llegado!»", mood: .wow),
        WheelOutcome(type: .chaos, emoji: "🦆", titleEn: "Duck Invasion", titleFr: "Invasion Canard", titleEs: "Invasión Patos", textEn: "Ducks took over. Resistance is futile.", textFr: "Les canards attaquent !", textEs: "¡Los patos dominan! No te resistas.", mood: .dizzy),
        WheelOutcome(type: .chaos, emoji: "🤫", titleEn: "Secret Mission", titleFr: "Mission Secrète", titleEs: "Misión Secreta", textEn: "Walk like a spy. Do not blink.", textFr: "Marchez comme un espion.", textEs: "Camina como espía. No parpadees.", mood: .sus, timerSeconds: 15),
        WheelOutcome(type: .chaos, emoji: "🫠", titleEn: "CheerUp Meltdown", titleFr: "CheerUp Fond", titleEs: "CheerUp se Derrite", textEn: "CheerUp is melting into pixels.", textFr: "CheerUp fond en pixels.", textEs: "CheerUp se derrite en píxeles.", mood: .dizzy),
        WheelOutcome(type: .chaos, emoji: "🗣️", titleEn: "Backwards Talk", titleFr: "À l'envers", titleEs: "Al Revés", textEn: "Say your name backwards out loud.", textFr: "Dites votre nom à l'envers.", textEs: "Di tu nombre al revés en voz alta.", mood: .wow),
        WheelOutcome(type: .chaos, emoji: "🌀", titleEn: "Absolute Nonsense", titleFr: "Non-sens", titleEs: "Disparate", textEn: "Banana telescope purple Tuesday.", textFr: "Banane télescope mardi violet.", textEs: "Plátano telescopio martes morado.", mood: .dizzy),
        WheelOutcome(type: .chaos, emoji: "🚀", titleEn: "Rocket Launch", titleFr: "Fusée", titleEs: "Cohete", textEn: "Count 5 to 1 with rocket noises.", textFr: "Comptez 5 à 1 façon fusée.", textEs: "Cuenta 5 a 1 con ruidos de cohete.", mood: .wow, timerSeconds: 6),
        WheelOutcome(type: .chaos, emoji: "👁️", titleEn: "Stare Down", titleFr: "Fixette", titleEs: "Duelo Visual", textEn: "Stare without blinking for 8 seconds.", textFr: "Fixez 8s sans ciller.", textEs: "Mira sin parpadear durante 8s.", mood: .sus, timerSeconds: 8),
        WheelOutcome(type: .chaos, emoji: "🧊", titleEn: "Freeze Frame", titleFr: "Statue", titleEs: "Estatua", textEn: "Freeze in your current pose. Don’t move!", textFr: "Ne bougez plus d'un poil !", textEs: "¡Quédate inmóvil en tu postura actual!", mood: .wow, timerSeconds: 7),
        WheelOutcome(type: .chaos, emoji: "🤖", titleEn: "Robot Mode", titleFr: "Robot", titleEs: "Modo Robot", textEn: "Say “BEEP BOOP I AM HUMAN” out loud.", textFr: "Dites « BIP BOP HUMAIN ».", textEs: "Di « BIP BOP SOY HUMANO » en voz alta.", mood: .dizzy),
        WheelOutcome(type: .chaos, emoji: "🎸", titleEn: "Air Guitar Solo", titleFr: "Air Guitar", titleEs: "Air Guitar", textEn: "Unleash an epic air guitar solo right now.", textFr: "Solo d'air guitar maintenant !", textEs: "¡Toca un solo épico de guitarra aérea!", mood: .party, timerSeconds: 8),
        WheelOutcome(type: .chaos, emoji: "🗿", titleEn: "Stone Face", titleFr: "Visage de Pierre", titleEs: "Cara de Piedra", textEn: "No smiling allowed for 10 seconds.", textFr: "Interdit de sourire 10s.", textEs: "Prohibido sonreír durante 10s.", mood: .sus, timerSeconds: 10)
    ]

    static var idleLines: [String] {
        switch LanguageManager.shared.currentLanguage {
        case .french:
            return ["Tourne-moi !", "Jour de chance ?", "Allez, tourne !", "Prêt quand tu veux !"]
        case .spanish:
            return ["¡Gírame!", "¿Día de suerte?", "¡Dale, gira!", "¡Listo cuando quieras!"]
        case .english:
            return ["Spin me!", "Feeling lucky?", "Ooh, spin it!", "Ready when you are!"]
        }
    }

    static var spinLines: [String] {
        switch LanguageManager.shared.currentLanguage {
        case .french:
            return ["Youhouuu !", "Ça tourne !", "Où ça s'arrête ?", "Accrochez-vous !"]
        case .spanish:
            return ["¡Yujuuu!", "¡Está girando!", "¿Dónde caerá?", "¡Agárrate a tus píxeles!"]
        case .english:
            return ["Wheeeee!", "Whoa whoa whoa!", "Where will it land?", "Hold onto your pixels!"]
        }
    }

    static var happyLines: [String] {
        switch LanguageManager.shared.currentLanguage {
        case .french:
            return ["Défi relevé ?", "À vous de jouer !", "C'est parti !", "Montrez ce que vous valez !"]
        case .spanish:
            return ["¿Aceptas el reto?", "¡Tu turno!", "¡A ver cómo lo haces!", "¡A por todas!"]
        case .english:
            return ["Challenge accepted?", "Your turn!", "Let's see it!", "Show what you got!"]
        }
    }

    static var chaosLines: [String] {
        switch LanguageManager.shared.currentLanguage {
        case .french:
            return ["Je te l'avais dit !", "Chaos total !", "Bonne chance !", "C'est parti !"]
        case .spanish:
            return ["¡Te lo advertí!", "¡Caos absoluto!", "Jaja, ¡buena suerte!", "¡¿Qué hemos hecho?!"]
        case .english:
            return ["Told you so!", "Absolute chaos!", "Haha, good luck!", "What have we done?!"]
        }
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

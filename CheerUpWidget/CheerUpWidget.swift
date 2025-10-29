//
//  CheerUpWidget.swift
//  CheerUpWidget
//
//  Created by Christopher Ogbonnaya on 2025-02-27.
//

import WidgetKit
import SwiftUI

// ✅ Compliment Data
let compliments = [
    "You are loved and appreciated!",
    "You have a great sense of humour!",
    "You're a fantastic problem solver!",
    "You light up the room!",
    "You have a wonderful smile!",
    "You're so thoughtful!",
    "Your creativity is inspiring!",
    "You're a great listener!",
    "You make people feel appreciated!",
    "You are a joy to be around!",
    "You bring out the best in others!",
    "You have a heart of gold!",
    "Your kindness is contagious!",
    "You're stronger than you think!",
    "Your positivity is refreshing!",
    "You are full of amazing ideas!",
    "You're an incredible friend!",
    "You have an amazing way with words!",
    "You're making a difference in the world!",
    "Your confidence is inspiring!",
    "You're going to achieve great things!",
    "You have an incredible work ethic!",
    "Your determination is admirable!",
    "You have a beautiful soul!",
    "You're an excellent communicator!",
    "You're a natural leader!",
    "You bring warmth to everyone around you!",
    "Your laugh is contagious!",
    "You're a true ray of sunshine!",
    "You make the world a better place just by being in it!",
    "You are deeply valued by those around you!",
    "You are a fantastic storyteller!",
    "Your generosity knows no bounds!",
    "Your passion is truly inspiring!",
    "You handle challenges with such grace!",
    "Your enthusiasm is contagious!",
    "You make even the simplest moments special!",
    "Your kindness makes a real impact!",
    "You always know how to cheer people up!",
    "Your intelligence is truly impressive!",
    "You make learning new things exciting!",
    "You have a wonderful presence!",
    "You inspire people to be their best selves!",
    "You are truly one of a kind!",
    "You have a rare and beautiful soul!",
    "You're always there when someone needs support!",
    "You have a natural ability to make people feel safe!",
    "You're a great human!",
    "You're the type of person who brings positive vibes!",
    "Your ideas are always so original and refreshing!",
    "You have an eye for beauty in the world!",
    "Your patience is admirable!",
    "You always find the silver lining in situations!",
    "You're a master at lifting people's spirits!",
    "Your hugs are the best!",
    "You make everyone feel welcome and included!",
    "You're an incredible problem-solver!",
    "Your heart is as big as the universe!",
    "You inspire me every day!",
    "You're like a breath of fresh air!",
    "You radiate happiness!",
    "Your sense of humour makes life more fun!",
    "You have a natural charm that draws people in!",
    "You're an amazing listener!",
    "Your words always bring comfort!",
    "You make the world feel like a better place!",
    "You have a way of making everyone feel important!",
    "Your energy is uplifting!",
    "You bring out the best in every situation!",
    "You're an absolute crystal gem!",
    "You're a powerhouse of talent and passion!",
    "You are more courageous than you realise!",
    "You have a heart full of compassion!",
    "Your smile can brighten even the darkest day!",
    "You have an adventurous spirit that's contagious!",
    "You're such an incredible friend and supporter!",
    "You're the type of person who makes life exciting!",
    "Your resilience is nothing short of amazing!",
    "You're an absolute inspiration!",
    "You give the best advice!",
    "Your warmth and kindness never go unnoticed!",
    "You always know how to make someone feel better!",
    "You have the most wonderful laugh!",
    "Your honesty is something truly special!",
    "You always put others at ease!",
    "You're like sunshine on a rainy day!",
    "You are a blessing to everyone around you!",
    "You make people feel like they matter!",
    "You are truly unforgettable!",
    "You have a magnetic personality!",
    "You are the definition of grace and kindness!",
    "You are a walking source of encouragement!",
    "You bring so much joy into the world!",
    "You're the reason someone smiles today!",
    "You're proof that good people exist in the world!",
    "Your optimism makes everything feel possible!",
    "You have a big heart!",
    "You make the world a brighter place!",
    "You have an incredible presence that lights up a room!",
    "You spread love and kindness wherever you go!",
    "You make people believe in themselves!",
    "You are simply amazing, just as you are!",
    "You are loved by so many!",
    "You're a brilliant individual!",
    "You are truly invincible!",
    "It's all peace and love!",
    "You're unique in your own way!",
    "You're fine as fuck!",
    "You are HIM/HER/THEY!",
    "You neither hear, speak, nor see any evil.",
    "You are very special!",
    "Today is your DAY!",
    "You make silence feel comfortable!",
    "Your smile could brighten space!",
    "You turn moments into memories!",
    "Your confidence is magnetic!",
    "You make people feel at home!",
    "Your vibe is a masterpiece!",
    "Dreams chase you, not the other way!",
    "Your presence feels like good luck!",
    "You make creativity look effortless!",
    "Your laughter is pure joy!",
    "Even the sun envies you!",
    "Empathy is your superpower!",
    "You radiate good vibes!",
    "Your natural born leader!",
    "You can do anything!",
    "You’re a walking masterpiece!",
    "Your thoughtfulness is rare!",
    "You shine your own way!",
    "You deserve a Hall of Fame!",
    "Your mind is pure brilliance!",
    "You make everyone feel seen!",
    "Resilience looks like you!",
    "Obstacles bow to you!",
    "Your ideas travel far!",
    "You radiate pure joy!",
    "Your optimism is uplifting!",
    "You inspire self-belief!",
    "Your humor is gold!",
    "You turn Mondays into Fridays!",
    "You make challenges exciting!",
    "Your presence is a gift!",
    "You bring out the best in yourself!",
    "You’re effortlessly cool!",
    "You got unmatched steez!",
    "Confidence suits you!",
    "Your perspective is refreshing!",
    "You brighten bad days!",
    "Your laughter heals!",
    "You make wisdom fun!",
    "Every moment with you shines!",
    "Your mindset is unstoppable!",
    "You’re a natural motivator!",
    "You turn setbacks into comebacks!",
    "You make the world warmer!",
    "You shine bright like a diamond!",
    "You are a precious stardust!"

]

struct CheerUpEntry: TimelineEntry {
    let date: Date
    let compliment: String
}

struct CheerUpProvider: TimelineProvider {
    func placeholder(in context: Context) -> CheerUpEntry {
        CheerUpEntry(date: Date(), compliment: compliments[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (CheerUpEntry) -> Void) {
        let entry = CheerUpEntry(date: Date(), compliment: compliments.randomElement() ?? "")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CheerUpEntry>) -> Void) {
        var entries: [CheerUpEntry] = []
        let currentDate = Date()

        // Create entries for the next 24 hours, updating every 30 minutes
        for halfHourOffset in 0..<48 { // 48 half-hour intervals = 24 hours
            let entryDate = Calendar.current.date(byAdding: .minute, value: halfHourOffset * 30, to: currentDate)!
            let entry = CheerUpEntry(date: entryDate, compliment: compliments.randomElement() ?? "")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// Teal, Black & White Theme Widget
struct CheerUpWidgetEntryView: View {
    var entry: CheerUpEntry
    @Environment(\.widgetFamily) var family
    
    // Responsive font size based on widget family - larger for better space usage
    private var fontSize: CGFloat {
        switch family {
        case .systemSmall:
            return 14
        case .systemMedium:
            return 18
        case .systemLarge:
            return 22
        default:
            return 18
        }
    }
    
    // Responsive padding based on widget family - reduced for more text space
    private var padding: CGFloat {
        switch family {
        case .systemSmall:
            return 6
        case .systemMedium:
            return 8
        case .systemLarge:
            return 12
        default:
            return 8
        }
    }
    
    // Line limit based on widget size - increased for better space usage
    private var lineLimit: Int {
        switch family {
        case .systemSmall:
            return 4
        case .systemMedium:
            return 6
        case .systemLarge:
            return 10
        default:
            return 6
        }
    }

    var body: some View {
        ZStack {
            // Teal background - matches container background exactly
            Color(red: 0.0, green: 0.4, blue: 0.4)
                .ignoresSafeArea()
            
            // Subtle black overlay for better contrast
            Color.black.opacity(0.1)
                .ignoresSafeArea()

            // Text takes up maximum available space
            VStack(spacing: 2) {
                Spacer()
                
                // White text with responsive sizing - takes more space
                Text(entry.compliment)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(lineLimit)
                    .minimumScaleFactor(0.6)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
            .padding(padding)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .containerBackground(Color(red: 0.1, green: 0.2, blue: 0.2), for: .widget)
    }
}

struct CheerUpWidget: Widget {
    let kind: String = "CheerUpWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CheerUpProvider()) { entry in
            CheerUpWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("CheerUp Widget")
        .description("Get random compliments every 30 minutes!")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    CheerUpWidget()
} timeline: {
    CheerUpEntry(date: .now, compliment: compliments[0])
    CheerUpEntry(date: .now, compliment: compliments[1])
}

#Preview(as: .systemMedium) {
    CheerUpWidget()
} timeline: {
    CheerUpEntry(date: .now, compliment: compliments[2])
    CheerUpEntry(date: .now, compliment: compliments[3])
}

#Preview(as: .systemLarge) {
    CheerUpWidget()
} timeline: {
    CheerUpEntry(date: .now, compliment: compliments[4])
    CheerUpEntry(date: .now, compliment: compliments[5])
}


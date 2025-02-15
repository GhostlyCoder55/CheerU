import SwiftUI
import UserNotifications

struct ContentView: View {
    let compliments = [
        "You are loved and appreciated!", "You have a great sense of humour!","You're a fantastic problem solver!","You light up the room!","You have a wonderful smile!","You're so thoughtful!", "Your creativity is inspiring!","You're a great listener!","You make people feel appreciated!","You are a joy to be around!","You bring out the best in others!","You have a heart of gold!","Your kindness is contagious!","You're stronger than you think!","Your positivity is refreshing!","You are full of amazing ideas!",
        "You're an incredible friend!","You have an amazing way with words!","You're making a difference in the world!","Your confidence is inspiring!","You're going to achieve great things!","You have an incredible work ethic!","Your determination is admirable!","You have a beautiful soul!","You're an excellent communicator!","You're a natural leader!","You bring warmth to everyone around you!","Your laugh is contagious!"
        ,"You're a true ray of sunshine!","You make the world a better place just by being in it!","You are deeply valued by those around you!","You are a fantastic storyteller!","Your generosity knows no bounds!","Your passion is truly inspiring!","You handle challenges with such grace!","Your enthusiasm is contagious!",
        "You make even the simplest moments special!","Your kindness makes a real impact!","You always know how to cheer people up!","Your intelligence is truly impressive!","You make learning new things exciting!","You have a wonderful presence!","You inspire people to be their best selves!",
        "You are truly one of a kind!","You have a rare and beautiful soul!","You're always there when someone needs support!","You have a natural ability to make people feel safe!","You're a great human!","You're the type of person who brings positive vibes!","Your ideas are always so original and refreshing!",
        "You have an eye for beauty in the world!","Your patience is admirable!","You always find the silver lining in situations!","You're a master at lifting people's spirits!","Your hugs are the best!","You make everyone feel welcome and included!","You're an incredible problem-solver!","Your heart is as big as the universe!","You inspire me every day!","You're like a breath of fresh air!","You radiate happiness!"
        ,"Your sense of humour makes life more fun!","You have a natural charm that draws people in!","You're an amazing listener!","Your words always bring comfort!","You make the world feel like a better place!","You have a way of making everyone feel important!","Your energy is uplifting!","You bring out the best in every situation!","You're an absolute crystal gem!","You're a powerhouse of talent and passion!","You are more courageous than you realise!","You have a heart full of compassion!",
        "Your smile can brighten even the darkest day!","You have an adventurous spirit that's contagious!","You're such an incredible friend and supporter!","You're the type of person who makes life exciting!",
        "Your resilience is nothing short of amazing!","You're an absolute inspiration!","You give the best advice!","Your warmth and kindness never go unnoticed!","You always know how to make someone feel better!","You have the most wonderful laugh!","Your honesty is something truly special!",
        "You always put others at ease!","You're like sunshine on a rainy day!","You are a blessing to everyone around you!","You make people feel like they matter!","You are truly unforgettable!","You have a magnetic personality!","You are the definition of grace and kindness!","You are a walking source of encouragement!","You bring so much joy into the world!","You're the reason someone smiles today!"
        ,"You're proof that good people exist in the world!","Your optimism makes everything feel possible!","You have a big heart!","You make the world a brighter place!","You have an incredible presence that lights up a room!","You spread love and kindness wherever you go!","You make people believe in themselves!","You are simply amazing, just as you are!","You are loved by so many!","You're a brilliant individual!","You are truly invincible!","It's all peace and love!","You're unique in your own way!","You're fine as fuck!", "Pappy! 🍆💦"
        ]
 
        @State private var currentCompliment: String? = nil
        @State private var backgroundColor: Color = Color.black
        @State private var bounce: Bool = false
        @State private var emojiIndex: Int = 0
        @State private var showAboutPopup: Bool = false
        @State private var complimentOpacity: Double = 0.0
        @State private var showEmojis: Bool = true
        @State private var isTransitioning: Bool = false

        let emojiCycle = ["😢","😋", "😱", "😭", "😂","😳","😍","🙁","😫","😁","😡","🥺","😓"]

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
                        // Smooth transition for emoji
                        if showEmojis {
                            Text(emojiCycle[emojiIndex])
                                .font(.system(size: 100))
                                .transition(.opacity) // Use opacity transition for fade effect
                                .zIndex(1)
                                .onAppear {
                                    Timer.scheduledTimer(withTimeInterval: 1.25, repeats: true) { _ in
                                        emojiIndex = (emojiIndex + 1) % emojiCycle.count
                                    }
                                }
                                .animation(.easeInOut(duration: 0.5), value: emojiIndex) // Animate the emoji change
                        }
                        
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
                    .padding(.top, 20)
                    
                    Button("About") {
                        showAboutPopup = true
                    }
                    .foregroundColor(.white)
                    .padding()
                    .sheet(isPresented: $showAboutPopup) {
                        AboutPopupView()
                    }
                    
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
            .onAppear {
                requestNotificationPermission()
            }
        }

    func generateCompliment() {
            if isTransitioning { return } // Prevent animation conflicts
            isTransitioning = true

            withAnimation(.easeInOut(duration: 0.5)) {
                showEmojis = false
                complimentOpacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let randomCompliment = compliments.randomElement() {
                    currentCompliment = randomCompliment
                }
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

        func requestNotificationPermission() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    print("Permission granted")
                    scheduleDailyComplimentNotifications()
                } else {
                    print("Permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }

        func scheduleDailyComplimentNotifications() {
            let times = [9, 21] // 9 AM and 9 PM
            
            for hour in times {
                let content = UNMutableNotificationContent()
                content.title = "Daily Compliment"
                content.body = compliments.randomElement() ?? "Have a great day!"
                content.sound = .default
                
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "dailyCompliment_\(hour)", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            }
        }

        struct AboutPopupView: View {
            var body: some View {
                VStack {
                    Text("About CheerUp!")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            MessageBubble(text: "Ayoo, what's this app about?", isUser: true, sender: "Me")
                            MessageBubble(text: "CheerUp is an app that compliments you with just one tap. We all need a little boost now and then, you feel me?", isUser: false, sender: "Christopher")
                            MessageBubble(text: "It was actually a fun project for me to learn SwiftUI.", isUser: false, sender: "Christopher")
                            MessageBubble(text: "I see. Can I use it whenever?", isUser: true, sender: "Me")
                            MessageBubble(text: "Fo sho!", isUser: false, sender: "Christopher")
                            MessageBubble(text: "Say less. I appreciate you!", isUser: true, sender: "Me")
                            MessageBubble(text: "Enjoy it. Peace!!!", isUser: false, sender: "Christopher")
                        }
                        .padding()
                    }
                }
            }
        }

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
                        .background(isUser ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.black) // Change to white
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
        struct ContentView_Previews: PreviewProvider {
            static var previews: some View {
                ContentView()
            }
        }
}

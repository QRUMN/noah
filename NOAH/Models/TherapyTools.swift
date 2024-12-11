import Foundation

enum TherapyToolType: String, Codable, CaseIterable {
    case cbt = "Cognitive Behavioral Therapy"
    case mindfulness = "Mindfulness Exercises"
    case journalPrompts = "Smart Journaling"
    case moodAnalysis = "Mood Analysis"
    case copingStrategies = "Coping Strategies"
    case stressRelief = "Stress Relief"
}

struct TherapyExercise: Identifiable, Codable {
    let id: String
    let type: TherapyToolType
    let title: String
    let description: String
    let duration: Int // in minutes
    let difficulty: String // "Beginner", "Intermediate", "Advanced"
    let steps: [String]
    let tips: [String]
    let category: String
    var isCompleted: Bool
    let recommendedFrequency: String // "Daily", "Weekly", etc.
}

struct CopingStrategy: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let situation: String
    let techniques: [String]
    let effectiveness: Int // 1-5 rating
    let userFeedback: String?
    let category: String
    let tags: [String]
}

struct ThoughtRecord: Identifiable, Codable {
    let id: String
    let date: Date
    let situation: String
    let automaticThoughts: String
    let emotions: [String]
    let emotionIntensities: [Int] // 1-10 scale
    let evidenceFor: String
    let evidenceAgainst: String
    let balancedThought: String
    let newEmotionIntensities: [Int]
    
    var emotionalChange: Int {
        let oldAverage = emotionIntensities.reduce(0, +) / emotionIntensities.count
        let newAverage = newEmotionIntensities.reduce(0, +) / newEmotionIntensities.count
        return oldAverage - newAverage
    }
}

struct JournalPrompt: Identifiable, Codable {
    let id: String
    let prompt: String
    let category: String
    let followUpQuestions: [String]
    let moodTags: [String]
    let recommendedDuration: Int // in minutes
    let difficulty: String
    let helpfulTips: [String]
}

struct MoodPattern: Identifiable, Codable {
    let id: String
    let userId: String
    let period: String // "daily", "weekly", "monthly"
    let dominantMoods: [String]
    let triggers: [String]
    let timePatterns: [String]
    let activities: [String]
    let suggestions: [String]
    let lastUpdated: Date
}

// Mock AI Response Generator
class TherapyResponseGenerator {
    static func generateCopingStrategy(for situation: String, mood: String) -> CopingStrategy {
        let strategies: [CopingStrategy] = [
            CopingStrategy(
                id: UUID().uuidString,
                title: "Mindful Breathing",
                description: "A simple but effective technique to center yourself",
                situation: "Feeling overwhelmed or anxious",
                techniques: [
                    "Find a quiet space",
                    "Breathe in for 4 counts",
                    "Hold for 4 counts",
                    "Exhale for 4 counts",
                    "Repeat for 5 minutes"
                ],
                effectiveness: 4,
                userFeedback: nil,
                category: "Stress Management",
                tags: ["breathing", "anxiety", "quick-relief"]
            ),
            CopingStrategy(
                id: UUID().uuidString,
                title: "5-4-3-2-1 Grounding",
                description: "Use your senses to ground yourself in the present moment",
                situation: "Feeling disconnected or anxious",
                techniques: [
                    "Name 5 things you can see",
                    "Name 4 things you can touch",
                    "Name 3 things you can hear",
                    "Name 2 things you can smell",
                    "Name 1 thing you can taste"
                ],
                effectiveness: 5,
                userFeedback: nil,
                category: "Anxiety Management",
                tags: ["grounding", "mindfulness", "anxiety"]
            )
        ]
        
        return strategies.randomElement() ?? strategies[0]
    }
    
    static func generateJournalPrompt(based on mood: String) -> JournalPrompt {
        let prompts: [JournalPrompt] = [
            JournalPrompt(
                id: UUID().uuidString,
                prompt: "What's the most challenging part of what you're feeling right now, and how might you show yourself compassion in this moment?",
                category: "Emotional Awareness",
                followUpQuestions: [
                    "What would you say to a friend in this situation?",
                    "How can you be kinder to yourself?",
                    "What small step could you take to feel better?"
                ],
                moodTags: ["anxious", "overwhelmed", "stressed"],
                recommendedDuration: 15,
                difficulty: "Intermediate",
                helpfulTips: [
                    "Take your time to reflect deeply",
                    "There are no wrong answers",
                    "Focus on self-compassion"
                ]
            ),
            JournalPrompt(
                id: UUID().uuidString,
                prompt: "Describe a moment today when you felt at peace. What contributed to that feeling?",
                category: "Positive Psychology",
                followUpQuestions: [
                    "How could you create more moments like this?",
                    "What elements of this experience could you replicate?",
                    "Who or what helped create this peaceful moment?"
                ],
                moodTags: ["calm", "content", "peaceful"],
                recommendedDuration: 10,
                difficulty: "Beginner",
                helpfulTips: [
                    "Focus on sensory details",
                    "Include both external and internal factors",
                    "Consider the role of others"
                ]
            )
        ]
        
        return prompts.randomElement() ?? prompts[0]
    }
    
    static func analyzeMoodPatterns(entries: [ThoughtRecord]) -> MoodPattern {
        // Mock mood pattern analysis
        return MoodPattern(
            id: UUID().uuidString,
            userId: "current-user",
            period: "weekly",
            dominantMoods: ["anxious", "hopeful"],
            triggers: ["work deadlines", "social events"],
            timePatterns: ["morning anxiety", "evening relaxation"],
            activities: ["exercise", "meditation", "socializing"],
            suggestions: [
                "Consider morning meditation to address anxiety",
                "Schedule breaks during work hours",
                "Maintain regular exercise routine"
            ],
            lastUpdated: Date()
        )
    }
}

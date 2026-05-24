import Foundation

enum Env {
    static let supabaseURL = URL(string: "https://gjlztittszelfjubbksy.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdqbHp0aXR0c3plbGZqdWJia3N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczNzcwNzksImV4cCI6MjA4Mjk1MzA3OX0.ksZ4blsKar75mO6THGpZida3kX-L8QVv1pb_ur9L5Rs"
    static var isUITesting: Bool { ProcessInfo.processInfo.arguments.contains("UI_TESTING") }
}

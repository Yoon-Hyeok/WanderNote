import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("홈", systemImage: "house.fill") }
            MapView()
                .tabItem { Label("지도", systemImage: "map.fill") }
            AddView()
                .tabItem { Label("추가", systemImage: "plus.circle.fill") }
            ProfileView()
                .tabItem { Label("프로필", systemImage: "person.crop.circle.fill") }
        }
        .tint(.purple) // 기획서의 보라색 테마 반영
    }
}

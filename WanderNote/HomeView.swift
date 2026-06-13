import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TravelRecord.visitDate, order: .reverse) private var records: [TravelRecord]
    
    @State private var searchText = ""
    @State private var showingTripList = false
    @State private var showingCityList = false
    @State private var showOnlyFavorites = false
    
    var filteredRecords: [TravelRecord] {
            var result = records
            
            if !searchText.isEmpty {
                result = result.filter {
                    $0.placeName.localizedStandardContains(searchText) ||
                    $0.memo.localizedStandardContains(searchText) ||
                    $0.cityName.localizedStandardContains(searchText)
                }
            }
            
            if showOnlyFavorites {
                result = result.filter { $0.isFavorite }
            }
            
            return result
        }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(showOnlyFavorites ? "즐겨찾기" : "최근 여행")
                                .font(.title2)
                                .bold()
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    showOnlyFavorites.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: showOnlyFavorites ? "line.3.horizontal.decrease.circle.fill" : "heart.circle.fill")
                                    Text(showOnlyFavorites ? "전체 보기" : "즐겨찾기")
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(showOnlyFavorites ? Color.gray.opacity(0.15) : Color.red.opacity(0.1))
                                .foregroundColor(showOnlyFavorites ? .primary : .red)
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                if filteredRecords.isEmpty {
                                    Text(showOnlyFavorites ? "아직 즐겨찾기 한 여행이 없어요." : (searchText.isEmpty ? "아직 기록된 여행이 없어요. 첫 여행을 추가해보세요!" : "검색 결과가 없어요."))
                                        .foregroundColor(.gray)
                                        .padding()
                                } else {
                                    ForEach(filteredRecords) { record in
                                        NavigationLink(destination: DetailView(record: record)) {
                                            TravelCardView(record: record)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                modelContext.delete(record)
                                            } label: {
                                                Label("여행 기록 삭제", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                                            Text("여행 통계")
                                                .font(.title2)
                                                .bold()
                                                .padding(.horizontal)
                                            
                                            HStack(spacing: 15) {
                                                Button(action: { showingTripList = true }) {
                                                    StatCard(title: "총 여행 횟수", value: "\(records.count)회")
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                
                                                Button(action: { showingCityList = true }) {
                                                    let uniqueCities = Set(records.map { $0.cityName }).count
                                                    StatCard(title: "방문 도시 수", value: "\(uniqueCities)곳")
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                            .padding(.horizontal)
                                        }
                }
                .padding(.vertical)
            }
            .navigationTitle("WanderNote")
            .searchable(text: $searchText, prompt: "여행지나 메모를 검색해보세요")
            .sheet(isPresented: $showingTripList) {
                TripListView(records: records)
            }
            .sheet(isPresented: $showingCityList) {
                CityListView(records: records)
            }
        }
    }
}

struct TravelCardView: View {
    @Bindable var record: TravelRecord
    
    var body: some View {
        VStack(alignment: .leading) {
            if let photoData = record.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 250, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 250, height: 160)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .imageScale(.large)
                    )
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.placeName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(record.visitDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                Button {
                    record.isFavorite.toggle()
                } label: {
                    Image(systemName: record.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(record.isFavorite ? .red : .gray)
                        .font(.title3)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.top, 8)
            .padding(.horizontal, 5)
        }
        .frame(width: 250)
    }
}

struct StatCard: View {
    var title: String
    var value: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var iconName: String {
        if title.contains("여행") {
            return "airplane.departure"
        } else if title.contains("도시") {
            return "building.2.crop.circle"
        } else {
            return "star.circle"
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconName)
                .font(.system(size: 30))
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

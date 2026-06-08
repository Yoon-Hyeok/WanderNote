import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TravelRecord.visitDate, order: .reverse) private var records: [TravelRecord]
    
    @State private var searchText = ""
    @State private var showingTripList = false
    @State private var showingCityList = false
    
    // 💡 1. 즐겨찾기만 모아보기 위한 상태 변수 추가
    @State private var showOnlyFavorites = false
    
    var filteredRecords: [TravelRecord] {
            // 먼저 원본 데이터를 가져옵니다.
            var result = records
            
            // 💡 2. 검색어가 있다면 검색어로 필터링 (여기에 cityName 조건 추가!)
            if !searchText.isEmpty {
                result = result.filter {
                    $0.placeName.localizedStandardContains(searchText) ||
                    $0.memo.localizedStandardContains(searchText) ||
                    $0.cityName.localizedStandardContains(searchText) // 👈 도시 이름으로도 검색되도록 한 줄 추가!
                }
            }
            
            // 💡 3. 즐겨찾기 모드가 켜져 있다면, 하트(isFavorite)가 true인 것만 남깁니다.
            if showOnlyFavorites {
                result = result.filter { $0.isFavorite }
            }
            
            return result
        }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // 최근 여행 영역
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            // 💡 4. 모드에 따라 제목이 자연스럽게 변경됨
                            Text(showOnlyFavorites ? "즐겨찾기" : "최근 여행")
                                .font(.title2)
                                .bold()
                            
                            Spacer()
                            
                            // 💡 5. 즐겨찾기 필터 버튼 추가
                            Button(action: {
                                // 버튼을 누르면 부드러운 애니메이션과 함께 모드가 전환됩니다.
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
                                    // 💡 6. 상황에 맞는 안내 메시지 출력
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
                    
                    // 여행 통계 영역 (기존과 동일)
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
                                                    // 💡 placeName이 아닌 cityName을 기준으로 중복을 제거(Set)하여 카운트합니다.
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

// 3. 개별 여행 카드 UI 컴포넌트 분리
struct TravelCardView: View {
    // 💡 @Bindable을 사용하면 데이터(isFavorite)가 바뀔 때 화면의 하트도 실시간으로 바뀝니다.
    @Bindable var record: TravelRecord
    
    var body: some View {
        VStack(alignment: .leading) {
            // 사진 영역 (기존과 동일)
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
            
            // 정보 영역 (장소명, 날짜, 좋아요 버튼)
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
                
                // 💡 기존 이미지를 버튼으로 변경
                Button {
                    // 버튼을 누를 때마다 true/false 상태가 뒤집힘(토글)
                    record.isFavorite.toggle()
                } label: {
                    // isFavorite 상태에 따라 꽉 찬 하트(빨간색) / 빈 하트(회색)으로 변경
                    Image(systemName: record.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(record.isFavorite ? .red : .gray)
                        .font(.title3)
                }
                // 카드를 눌렀을 때 DetailView로 넘어가는 터치 영역과 하트 버튼의 터치 영역이 겹치지 않도록 방지
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.top, 8)
            .padding(.horizontal, 5)
        }
        .frame(width: 250)
    }
}

// 💡 그림(아이콘)과 다크 모드를 모두 포함한 완전체 통계 카드
struct StatCard: View {
    var title: String
    var value: String
    
    @Environment(\.colorScheme) var colorScheme
    
    // 💡 제목에 따라 알아서 어울리는 그림(아이콘)을 찾아주는 똑똑한 기능
    var iconName: String {
        if title.contains("여행") {
            return "airplane.departure" // 여행 관련 그림
        } else if title.contains("도시") {
            return "building.2.crop.circle" // 도시 관련 그림
        } else {
            return "star.circle"
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // 💡 실수로 빼먹었던 그림(아이콘) 영역 복구!
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
            Spacer() // 카드를 가로로 꽉 차게 만들어줌
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

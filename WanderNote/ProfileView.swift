import SwiftUI
import SwiftData
import Charts

struct ProfileView: View {
    @Query private var records: [TravelRecord]
    
    @State private var showingTripList = false
    @State private var showingCityList = false
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    var availableYears: [Int] {
        let years = records.map { Calendar.current.component(.year, from: $0.visitDate) }
        let uniqueYears = Array(Set(years)).sorted(by: >)
        return uniqueYears.isEmpty ? [Calendar.current.component(.year, from: Date())] : uniqueYears
    }
    
    var recordsForSelectedYear: [TravelRecord] {
        records.filter { Calendar.current.component(.year, from: $0.visitDate) == selectedYear }
    }
    
    // 💡 핵심 추가: 1월부터 12월까지의 데이터를 무조건 생성해 두는 배열
    var monthlyStats: [(month: Int, count: Int)] {
        (1...12).map { monthIndex in
            let count = recordsForSelectedYear.filter {
                Calendar.current.component(.month, from: $0.visitDate) == monthIndex
            }.count
            return (month: monthIndex, count: count)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 상단 요약 통계 섹션 (기존 동일)
                Section {
                                    HStack(spacing: 15) {
                                        Button(action: { showingTripList = true }) {
                                            StatCard(title: "총 여행 횟수", value: "\(records.count)회")
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: { showingCityList = true }) {
                                            // 💡 여기도 cityName 기준으로 변경!
                                            let uniqueCities = Set(records.map { $0.cityName }).count
                                            StatCard(title: "방문 도시 수", value: "\(uniqueCities)곳")
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets())
                                    .padding(.vertical, 10)
                                }
                
                // 월별 여행 기록 차트 섹션
                Section {
                                    Chart {
                                        ForEach(monthlyStats, id: \.month) { stat in
                                            BarMark(
                                                // 💡 X축 값을 정수가 아닌 "1월", "2월" 형태의 '문자열'로 전달합니다.
                                                x: .value("월", "\(stat.month)월"),
                                                y: .value("여행 횟수", stat.count)
                                            )
                                            .foregroundStyle(Color.purple.gradient)
                                            .cornerRadius(5)
                                        }
                                    }
                                    .frame(height: 250)
                                    .padding(.vertical)
                                    // 💡 문자열 카테고리를 사용하므로 복잡한 X축 강제 고정 코드(chartXScale)를 지워도 됩니다.
                                    .chartXAxis {
                                        AxisMarks { _ in
                                            // 카테고리(문자열) 모드에서는 알아서 텍스트를 막대 정중앙에 배치합니다.
                                            AxisValueLabel()
                                                .font(.caption2) // 12개가 다 들어가도록 폰트 크기만 살짝 줄임
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                                            if let count = value.as(Int.self) {
                                                AxisValueLabel { Text("\(count)회") }
                                                AxisGridLine()
                                            }
                                        }
                                    }
                } header: {
                    HStack {
                        Text("월별 여행 기록")
                            .font(.headline)
                        
                        Spacer()
                        
                        Picker("연도 선택", selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text(String(format: "%d년", year)).tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .textCase(nil)
                }
            }
            .navigationTitle("여행 통계")
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(isPresented: $showingTripList) {
                TripListView(records: records)
            }
            .sheet(isPresented: $showingCityList) {
                CityListView(records: records)
            }
            .onAppear {
                if let latestYear = availableYears.first {
                    selectedYear = latestYear
                }
            }
        }
    }
}

// 💡 전체 여행 기록 리스트 (누르면 상세 화면으로 이동)
struct TripListView: View {
    var records: [TravelRecord]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(records.sorted(by: { $0.visitDate > $1.visitDate })) { record in
                // 💡 NavigationLink로 감싸서 DetailView로 이동
                NavigationLink(destination: DetailView(record: record)) {
                    HStack {
                        Text(record.placeName)
                            .font(.headline)
                        Spacer()
                        Text(record.visitDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("모든 여행 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                        .bold()
                        .tint(.purple)
                }
            }
        }
    }
}

// 💡 방문한 도시 리스트 (placeName이 아닌 cityName을 기준으로 묶어줌)
struct CityListView: View {
    var records: [TravelRecord]
    @Environment(\.dismiss) private var dismiss
    
    // 💡 도시명(cityName)을 기준으로 데이터를 묶고 정렬합니다.
    var cityStats: [(name: String, count: Int, records: [TravelRecord])] {
        // 도시명으로 그룹화 (예: "파리" -> 파리에서 간 여행 기록 배열)
        let grouped = Dictionary(grouping: records, by: { $0.cityName })
        return grouped.map { (name: $0.key, count: $0.value.count, records: $0.value) }
            .sorted { $0.count > $1.count } // 방문 횟수 순으로 정렬
    }
    
    var body: some View {
        NavigationStack {
            List(cityStats, id: \.name) { stat in
                // 💡 도시를 누르면 해당 도시에서 다녀온 기록을 모아서 보여주는 화면으로 이동
                NavigationLink(destination: CityDetailView(cityName: stat.name, records: stat.records)) {
                    HStack {
                        Text(stat.name)
                            .font(.headline)
                        Spacer()
                        Text("\(stat.count)회 방문")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                            .bold()
                    }
                }
            }
            .navigationTitle("방문한 도시")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                        .bold()
                        .tint(.purple)
                }
            }
        }
    }
}

// 💡 특정 도시에서 갔던 장소들을 모아서 보여주는 새로운 화면
struct CityDetailView: View {
    var cityName: String
    var records: [TravelRecord]
    
    var body: some View {
        List(records.sorted(by: { $0.visitDate > $1.visitDate })) { record in
            // 여기서도 기록을 누르면 상세 화면으로 이동
            NavigationLink(destination: DetailView(record: record)) {
                HStack {
                    Text(record.placeName)
                        .font(.headline)
                    Spacer()
                    Text(record.visitDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("\(cityName)에서의 기록")
        .navigationBarTitleDisplayMode(.inline)
    }
}

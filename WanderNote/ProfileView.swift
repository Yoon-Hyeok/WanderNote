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
                Section {
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
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets())
                                    .padding(.vertical, 10)
                                }
                
                Section {
                                    Chart {
                                        ForEach(monthlyStats, id: \.month) { stat in
                                            BarMark(
                                                x: .value("월", "\(stat.month)월"),
                                                y: .value("여행 횟수", stat.count)
                                            )
                                            .foregroundStyle(Color.purple.gradient)
                                            .cornerRadius(5)
                                        }
                                    }
                                    .frame(height: 250)
                                    .padding(.vertical)
                                    .chartXAxis {
                                        AxisMarks { _ in
                                            AxisValueLabel()
                                                .font(.caption2)
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

struct TripListView: View {
    var records: [TravelRecord]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(records.sorted(by: { $0.visitDate > $1.visitDate })) { record in
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

struct CityListView: View {
    var records: [TravelRecord]
    @Environment(\.dismiss) private var dismiss
    
    var cityStats: [(name: String, count: Int, records: [TravelRecord])] {
        let grouped = Dictionary(grouping: records, by: { $0.cityName })
        return grouped.map { (name: $0.key, count: $0.value.count, records: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    var body: some View {
        NavigationStack {
            List(cityStats, id: \.name) { stat in
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

struct CityDetailView: View {
    var cityName: String
    var records: [TravelRecord]
    
    var body: some View {
        List(records.sorted(by: { $0.visitDate > $1.visitDate })) { record in
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

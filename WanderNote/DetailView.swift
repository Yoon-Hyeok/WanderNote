import SwiftUI

struct DetailView: View {
    var record: TravelRecord
    
    // 💡 수정 화면을 띄울지 말지 결정하는 상태 변수
    @State private var isShowingEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // (이전과 동일한 사진, 장소명, 별점, 날짜, 메모 UI 코드)
                if let photoData = record.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 350)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 250)
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text(record.placeName)
                            .font(.largeTitle)
                            .bold()
                        Spacer()
                        
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < record.rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    
                    Text(record.visitDate, style: .date)
                        .foregroundColor(.gray)
                    
                    Divider()
                    
                    Text("여행 메모")
                        .font(.headline)
                    
                    Text(record.memo.isEmpty ? "작성된 메모가 없습니다." : record.memo)
                        .padding(.top, 5)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // 💡 툴바에 수정 버튼 추가
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("수정") {
                    isShowingEditSheet = true
                }
            }
        }
        // 💡 isShowingEditSheet가 true가 되면 EditView를 모달로 띄움
        .sheet(isPresented: $isShowingEditSheet) {
            EditView(record: record)
        }
    }
}

import SwiftUI
import SwiftData
import PhotosUI

struct EditView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 💡 @Bindable을 사용하면 값이 변경될 때 SwiftData DB에 자동으로 동기화됩니다.
    @Bindable var record: TravelRecord
    
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("사진 수정")) {
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        if let photoData = record.photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                Text("새 사진 선택")
                            }
                            .foregroundColor(.purple)
                        }
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                record.photoData = data // 새로운 사진으로 교체
                            }
                        }
                    }
                }
                
                Section(header: Text("기본 정보")) {
                    // record의 속성에 직접 바인딩($)하여 즉시 값을 수정합니다.
                    TextField("장소명", text: $record.placeName)
                    DatePicker("방문 날짜", selection: $record.visitDate, displayedComponents: .date)
                }
                
                Section(header: Text("여행 메모")) {
                    TextEditor(text: $record.memo)
                        .frame(height: 100)
                }
                
                Section(header: Text("별점")) {
                    Stepper("⭐️ \(record.rating)점", value: $record.rating, in: 1...5)
                }
            }
            .navigationTitle("기록 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss() // @Bindable 덕분에 별도의 save() 호출 없이도 자동 반영됨
                    }
                    .bold()
                    .tint(.purple)
                }
            }
        }
    }
}

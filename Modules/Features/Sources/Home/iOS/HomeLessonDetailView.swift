#if os(iOS)
import SwiftUI
import ComposableArchitecture
import DesignSystem

struct HomeLessonDetailView: View {
    @Bindable var store: StoreOf<HomeFeature>
    let categoryID: String
    let subcategoryID: String
    let onSelectNextLesson: (String) -> Void

    init(
        store: StoreOf<HomeFeature>,
        categoryID: String,
        subcategoryID: String,
        onSelectNextLesson: @escaping (String) -> Void = { _ in }
    ) {
        self.store = store
        self.categoryID = categoryID
        self.subcategoryID = subcategoryID
        self.onSelectNextLesson = onSelectNextLesson
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 48) {
                lessonHeaderSection
                definitionSection
                separator
                keyCharacteristicsSection
                separator
                interviewPrepSection

                if let nextLesson = presentation.nextLessonRow {
                    nextLessonButton(nextLesson)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 40)
            .frame(maxWidth: 512, alignment: .leading)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle(presentation.lessonTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "bookmark")
                }
                .tint(Color(red: 0.39, green: 0.45, blue: 0.55))
            }
        }
        .task {
            if store.selectedCategoryID != categoryID {
                store.send(.categorySelected(categoryID))
            }
        }
    }

    private var presentation: HomeLessonPresentation {
        HomeIOSPresentationBuilder.lesson(
            categoryID: categoryID,
            subcategoryID: subcategoryID,
            categories: store.categories,
            selectedCategoryID: store.selectedCategoryID,
            selectedContent: store.selectedContent
        )
    }

    private var lessonHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text(presentation.lessonBadgeText)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(Color(red: 0.0, green: 0.35, blue: 0.74))
    
            Text(presentation.lessonTitle)
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))

            RoundedRectangle(cornerRadius: 999)
                .fill(Color(red: 0.0, green: 0.35, blue: 0.74))
                .frame(width: 48, height: 4)
        }
    }

    private var definitionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            DailyDevSectionTitle("DEFINITION")

            if !presentation.definitionHeadline.isEmpty {
                Text(presentation.definitionHeadline)
                    .font(.system(size: 18, weight: .medium))
                    .lineSpacing(7)
                    .foregroundStyle(Color(red: 0.20, green: 0.26, blue: 0.33))
            }

            if !presentation.definitionBody.isEmpty {
                Text(presentation.definitionBody)
                    .font(.system(size: 16, weight: .regular))
                    .lineSpacing(7)
                    .foregroundStyle(Color(red: 0.28, green: 0.34, blue: 0.41))
            }

            if !presentation.keywordTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presentation.keywordTags, id: \.self) { tag in
                            DailyDevTagChip(tag)
                        }
                    }
                }
            }
        }
    }

    private var keyCharacteristicsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            DailyDevSectionTitle("KEY CHARACTERISTICS")

            VStack(alignment: .leading, spacing: 32) {
                ForEach(presentation.characteristics) { characteristic in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(characteristic.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))

                        Text(characteristic.description)
                            .font(.system(size: 14, weight: .regular))
                            .lineSpacing(6)
                            .foregroundStyle(Color(red: 0.28, green: 0.34, blue: 0.41))
                    }
                }
            }
        }
    }

    private var interviewPrepSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            DailyDevSectionTitle("INTERVIEW PREP")

            if !presentation.interviewPrompts.isEmpty {
                checklistCard(title: "INTERVIEW PROMPTS", items: presentation.interviewPrompts)
            }

            if !presentation.checkQuestions.isEmpty {
                checklistCard(title: "CHECK QUESTIONS", items: presentation.checkQuestions)
            }
        }
    }

    private func nextLessonButton(_ nextLesson: ChapterRow) -> some View {
        Button {
            onSelectNextLesson(nextLesson.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NEXT LESSON")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color(red: 0.58, green: 0.64, blue: 0.72))

                    Text(nextLesson.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(red: 0.0, green: 0.35, blue: 0.74))
            }
            .padding(24)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func checklistCard(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Color(red: 0.39, green: 0.45, blue: 0.55))
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.97, green: 0.98, blue: 0.99))

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.0, green: 0.35, blue: 0.74))

                    Text(item)
                        .font(.system(size: 14, weight: .regular))
                        .lineSpacing(5)
                        .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.23))
                }
                .padding(16)
                .overlay(alignment: .top) {
                    if index > 0 {
                        Divider().background(Color(red: 0.97, green: 0.98, blue: 0.99))
                    }
                }
            }
        }
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.95, green: 0.96, blue: 0.98), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var separator: some View {
        Rectangle()
            .fill(Color(red: 0.95, green: 0.96, blue: 0.98))
            .frame(height: 1)
    }
}
#endif

import ComposableArchitecture
import Entity
import SwiftUI

struct PostView: View {
    @Bindable var store: StoreOf<PostFeature>
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                switch store.phase {
                case .idle, .loading:
                    if store.articles.isEmpty {
                        loadingBody
                    } else {
                        listBody
                    }
                case .content, .reconnecting:
                    listBody
                case .empty:
                    emptyBody
                case .error:
                    errorBody
                }
            }
            .navigationTitle("Tech Posts")
            .refreshable {
                store.send(.refreshRequested)
            }
        }
    }

    @ViewBuilder
    private var loadingBody: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("글 목록을 불러오는 중...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private var emptyBody: some View {
        VStack(spacing: 12) {
            Text("글이 없습니다.")
                .font(.headline)
            Text("다시 불러오려면 새로고침을 눌러주세요.")
                .foregroundStyle(.secondary)
            Button("다시 시도") {
                store.send(.retryTapped)
            }
            .disabled(!store.canRetry)
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private var errorBody: some View {
        VStack(spacing: 12) {
            Text("문제가 발생했습니다")
                .font(.headline)
            Text(store.message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                store.send(.retryTapped)
            }
            .disabled(!store.canRetry)
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private var listBody: some View {
        List {
            if !store.message.isEmpty && store.phase == .reconnecting {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.exclamationmark")
                            .foregroundStyle(.orange)
                        Text(store.message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if store.canRetry {
                            Button("재시도") {
                                store.send(.retryTapped)
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if store.visibleArticles.isEmpty && !store.articles.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("선택한 필터에 맞는 글이 아직 없어요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if store.hasNext {
                            Button("더 불러오기") {
                                store.send(.loadMoreTapped)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }

            ForEach(store.visibleArticles) { article in
                Button {
                    openArticle(article.articleLink)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.blogName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(article.title)
                            .font(.body)
                            .bold()
                            .foregroundStyle(.primary)
                        Text(formatPublishedDate(for: article))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .disabled(URL(string: article.articleLink) == nil)
                .onAppear {
                    store.send(.rowAppeared(article.id))
                }
            }

            if store.phase == .reconnecting || (store.isLoading && !store.articles.isEmpty) {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.filterChips) { chip in
                    filterChip(for: chip)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    private func filterChip(for chip: PostFeature.State.FilterChip) -> some View {
        let isSelected = store.selectedFilterID == chip.id
        let title = chip.title

        return Button {
            store.send(.filterSelected(chip.id))
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func formatPublishedDate(for item: PostArticleListItem) -> String {
        let seconds = TimeInterval(item.publishedAtMillis) / 1000.0
        let date = Date(timeIntervalSince1970: seconds)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func openArticle(_ stringURL: String) {
        guard let url = URL(string: stringURL) else { return }
        openURL(url)
    }
}

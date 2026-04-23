import SwiftUI
import Foundation

// MARK: - Models

public enum QuizQuestionType: String, Hashable {
    case mcq, ox, fill
}

public struct QuizQuestion: Identifiable, Equatable {
    public let id: Int
    public let type: QuizQuestionType
    public let question: String
    public let choices: [String]
    public let correctIndex: Int      // MCQ 정답 인덱스 (-1 = MCQ 아님)
    public let oxAnswer: String       // "O" | "X" | ""
    public let fillAnswer: String     // 빈칸 정답 | ""
    public let explanation: String
    public let concept: String
    public let tag: String

    public init(
        id: Int,
        type: QuizQuestionType,
        question: String,
        choices: [String],
        correctIndex: Int,
        oxAnswer: String,
        fillAnswer: String,
        explanation: String,
        concept: String,
        tag: String
    ) {
        self.id = id
        self.type = type
        self.question = question
        self.choices = choices
        self.correctIndex = correctIndex
        self.oxAnswer = oxAnswer
        self.fillAnswer = fillAnswer
        self.explanation = explanation
        self.concept = concept
        self.tag = tag
    }
}

public struct QuizSet: Equatable {
    public let chapter: String
    public let chapterNum: String
    public let discipline: String
    public let questions: [QuizQuestion]
    public let passingScore: Int
    public var allowsEarlyExit: Bool = false

    public init(
        chapter: String,
        chapterNum: String,
        discipline: String,
        questions: [QuizQuestion],
        passingScore: Int,
        allowsEarlyExit: Bool = false
    ) {
        self.chapter = chapter
        self.chapterNum = chapterNum
        self.discipline = discipline
        self.questions = questions
        self.passingScore = passingScore
        self.allowsEarlyExit = allowsEarlyExit
    }
}

public struct QuizCategory: Identifiable {
    public let id: String
    public let name: String
    public let englishName: String
    public let icon: String
    public let iconColor: Color
    public let iconBackground: Color
    public let questions: [QuizQuestion]

    public init(
        id: String,
        name: String,
        englishName: String,
        icon: String,
        iconColor: Color,
        iconBackground: Color,
        questions: [QuizQuestion]
    ) {
        self.id = id
        self.name = name
        self.englishName = englishName
        self.icon = icon
        self.iconColor = iconColor
        self.iconBackground = iconBackground
        self.questions = questions
    }

    public var questionsByType: [(label: String, tag: String, items: [QuizQuestion])] {
        let mcq  = questions.filter { $0.type == .mcq }
        let ox   = questions.filter { $0.type == .ox }
        let fill = questions.filter { $0.type == .fill }
        var out: [(String, String, [QuizQuestion])] = []
        if !mcq.isEmpty  { out.append(("객관식", "Multiple Choice", mcq)) }
        if !ox.isEmpty   { out.append(("OX", "True / False", ox)) }
        if !fill.isEmpty { out.append(("빈칸", "Fill in Blank", fill)) }
        return out
    }

    public func toQuizSet() -> QuizSet {
        QuizSet(chapter: name, chapterNum: "—", discipline: name,
                questions: questions, passingScore: 80)
    }
}
// MARK: - Quiz Bank

public let quizBank: [QuizCategory] = [
    QuizCategory(
        id: "data-structures",
        name: "자료구조",
        englishName: "Data Structures",
        icon: "square.grid.3x3",
        iconColor: Color(red: 0.17, green: 0.39, blue: 0.92),
        iconBackground: Color(red: 0.94, green: 0.97, blue: 1.0),
        questions: dsQuestions
    ),
    QuizCategory(
        id: "algorithms",
        name: "알고리즘",
        englishName: "Algorithms",
        icon: "sum",
        iconColor: Color(red: 0.88, green: 0.52, blue: 0.0),
        iconBackground: Color(red: 1.0, green: 0.98, blue: 0.92),
        questions: algoQuestions
    ),
    QuizCategory(
        id: "operating-systems",
        name: "운영체제",
        englishName: "Operating System",
        icon: "terminal",
        iconColor: Color(red: 0.58, green: 0.26, blue: 0.91),
        iconBackground: Color(red: 0.98, green: 0.96, blue: 1.0),
        questions: osQuestions
    ),
    QuizCategory(
        id: "databases",
        name: "데이터베이스",
        englishName: "Database",
        icon: "cylinder",
        iconColor: Color(red: 0.05, green: 0.62, blue: 0.43),
        iconBackground: Color(red: 0.93, green: 0.99, blue: 0.96),
        questions: dbQuestions
    ),
    QuizCategory(
        id: "networking",
        name: "네트워크",
        englishName: "Network",
        icon: "point.3.filled.connected.trianglepath.dotted",
        iconColor: Color(red: 0.93, green: 0.13, blue: 0.36),
        iconBackground: Color(red: 1.0, green: 0.95, blue: 0.96),
        questions: netQuestions
    ),
]

// MARK: - Legacy (기존 플로우 호환)

public let dummyQuizSet = quizBank[0].toQuizSet()

public struct WrongNoteItem: Identifiable {
    public let id = UUID()
    public let chapterNum: String
    public let chapter: String
    public let question: String
    public let tag: String
    public let type: String
    public let relativeDate: String
    public let wrongCount: Int

    public init(
        chapterNum: String,
        chapter: String,
        question: String,
        tag: String,
        type: String,
        relativeDate: String,
        wrongCount: Int
    ) {
        self.chapterNum = chapterNum
        self.chapter = chapter
        self.question = question
        self.tag = tag
        self.type = type
        self.relativeDate = relativeDate
        self.wrongCount = wrongCount
    }
}

public let dummyWrongNotes: [WrongNoteItem] = [
    WrongNoteItem(
        chapterNum: "01",
        chapter: "자료구조",
        question: "동적 배열의 append는 평균 ___ 시간으로 동작한다.",
        tag: "Amortized",
        type: "빈칸",
        relativeDate: "3일 전",
        wrongCount: 2
    ),
    WrongNoteItem(
        chapterNum: "03",
        chapter: "데이터베이스",
        question: "해시 충돌을 해결하는 체이닝과 오픈 어드레싱의 차이는?",
        tag: "Collision",
        type: "객관식",
        relativeDate: "1주 전",
        wrongCount: 1
    ),
    WrongNoteItem(
        chapterNum: "02",
        chapter: "알고리즘",
        question: "DFS 구현에 더 적합한 자료구조는 큐이다.",
        tag: "DFS/BFS",
        type: "OX",
        relativeDate: "2주 전",
        wrongCount: 3
    ),
    WrongNoteItem(
        chapterNum: "04",
        chapter: "운영체제",
        question: "교착상태 발생 조건 중 선점 가능이 포함된다.",
        tag: "Deadlock",
        type: "OX",
        relativeDate: "2주 전",
        wrongCount: 1
    ),
]

// MARK: - Question Banks

private let dsQuestions: [QuizQuestion] = [
    QuizQuestion(id: 101, type: .mcq,
                 question: "연결리스트에서 맨 앞에 노드를 추가할 때의 시간복잡도는?",
                 choices: ["O(1)", "O(log n)", "O(n)", "O(n log n)"],
                 correctIndex: 0, oxAnswer: "", fillAnswer: "",
                 explanation: "head 포인터만 바꾸면 되므로 O(1)입니다.",
                 concept: "연결리스트", tag: "Time Complexity"),
    QuizQuestion(id: 102, type: .ox,
                 question: "배열은 연결리스트보다 CPU 캐시 지역성이 좋다.",
                 choices: [], correctIndex: -1, oxAnswer: "O", fillAnswer: "",
                 explanation: "배열은 연속 메모리 배치로 캐시라인 히트율이 높습니다.",
                 concept: "배열", tag: "Memory"),
    QuizQuestion(id: 103, type: .fill,
                 question: "동적 배열의 append는 amortized 분석 시 평균 ___ 시간으로 동작한다.",
                 choices: [], correctIndex: -1, oxAnswer: "", fillAnswer: "O(1)",
                 explanation: "리사이즈 비용을 전체 삽입에 분산하면 평균 O(1)입니다.",
                 concept: "동적 배열", tag: "Amortized"),
    QuizQuestion(id: 104, type: .mcq,
                 question: "다음 중 배열이 연결리스트보다 유리한 상황은?",
                 choices: ["중간 삽입이 잦다", "인덱스 조회가 잦다", "크기 예측 불가", "맨 앞 삽입이 잦다"],
                 correctIndex: 1, oxAnswer: "", fillAnswer: "",
                 explanation: "배열의 인덱스 접근은 O(1)입니다.",
                 concept: "자료구조 선택", tag: "Trade-off"),
    QuizQuestion(id: 105, type: .ox,
                 question: "연결리스트에서 i번째 원소 조회는 O(1)이다.",
                 choices: [], correctIndex: -1, oxAnswer: "X", fillAnswer: "",
                 explanation: "O(n)입니다. head부터 순차 탐색이 필요합니다.",
                 concept: "연결리스트", tag: "Time Complexity"),
    QuizQuestion(id: 106, type: .mcq,
                 question: "스택(Stack)의 특성으로 올바른 것은?",
                 choices: ["FIFO", "LIFO", "Random Access", "양방향 삽입"],
                 correctIndex: 1, oxAnswer: "", fillAnswer: "",
                 explanation: "스택은 Last In, First Out 구조입니다.",
                 concept: "스택", tag: "기본 개념"),
    QuizQuestion(id: 107, type: .ox,
                 question: "큐(Queue)는 BFS 구현에 주로 사용된다.",
                 choices: [], correctIndex: -1, oxAnswer: "O", fillAnswer: "",
                 explanation: "BFS는 레벨 순서 탐색이므로 FIFO 큐가 적합합니다.",
                 concept: "큐", tag: "활용"),
    QuizQuestion(id: 108, type: .fill,
                 question: "해시 테이블의 평균 탐색 시간복잡도는 ___이다.",
                 choices: [], correctIndex: -1, oxAnswer: "", fillAnswer: "O(1)",
                 explanation: "해시 함수로 인덱스를 직접 계산하므로 평균 O(1)입니다.",
                 concept: "해시 테이블", tag: "Time Complexity"),
]

private let algoQuestions: [QuizQuestion] = [
    QuizQuestion(id: 201, type: .mcq,
                 question: "버블 정렬의 최악 시간복잡도는?",
                 choices: ["O(n)", "O(n log n)", "O(n²)", "O(log n)"],
                 correctIndex: 2, oxAnswer: "", fillAnswer: "",
                 explanation: "버블 정렬은 매 패스마다 n번 비교, n패스가 필요해 O(n²)입니다.",
                 concept: "정렬", tag: "Time Complexity"),
    QuizQuestion(id: 202, type: .ox,
                 question: "이진 탐색(Binary Search)은 정렬된 배열에서만 사용 가능하다.",
                 choices: [], correctIndex: -1, oxAnswer: "O", fillAnswer: "",
                 explanation: "이진 탐색은 중간값과의 비교로 절반씩 제거하므로 정렬이 전제입니다.",
                 concept: "탐색", tag: "전제 조건"),
    QuizQuestion(id: 203, type: .mcq,
                 question: "DFS(깊이 우선 탐색) 구현에 주로 사용되는 자료구조는?",
                 choices: ["큐", "스택", "힙", "연결리스트"],
                 correctIndex: 1, oxAnswer: "", fillAnswer: "",
                 explanation: "DFS는 재귀 또는 명시적 스택으로 구현합니다.",
                 concept: "그래프 탐색", tag: "DFS"),
    QuizQuestion(id: 204, type: .ox,
                 question: "퀵 정렬의 최악 시간복잡도는 O(n log n)이다.",
                 choices: [], correctIndex: -1, oxAnswer: "X", fillAnswer: "",
                 explanation: "이미 정렬된 경우 피벗이 항상 최솟값이 되어 O(n²)이 됩니다.",
                 concept: "정렬", tag: "Time Complexity"),
    QuizQuestion(id: 205, type: .fill,
                 question: "합병 정렬(Merge Sort)의 시간복잡도는 항상 ___이다.",
                 choices: [], correctIndex: -1, oxAnswer: "", fillAnswer: "O(n log n)",
                 explanation: "분할과 병합 단계 모두 일정하므로 항상 O(n log n)입니다.",
                 concept: "정렬", tag: "Time Complexity"),
    QuizQuestion(id: 206, type: .mcq,
                 question: "다이나믹 프로그래밍의 핵심 조건 두 가지는?",
                 choices: ["최적 부분구조 + 중복 부분문제", "탐욕 선택 + 최적 부분구조",
                           "분할 정복 + 메모이제이션", "재귀 + 정렬"],
                 correctIndex: 0, oxAnswer: "", fillAnswer: "",
                 explanation: "DP는 최적 부분구조와 겹치는 부분문제 두 조건을 만족해야 합니다.",
                 concept: "DP", tag: "개념"),
    QuizQuestion(id: 207, type: .ox,
                 question: "그리디 알고리즘은 항상 전역 최적해를 보장한다.",
                 choices: [], correctIndex: -1, oxAnswer: "X", fillAnswer: "",
                 explanation: "그리디는 지역 최적을 선택하므로 전역 최적을 보장하지 않는 경우가 많습니다.",
                 concept: "그리디", tag: "특성"),
    QuizQuestion(id: 208, type: .fill,
                 question: "이진 탐색의 시간복잡도는 ___이다.",
                 choices: [], correctIndex: -1, oxAnswer: "", fillAnswer: "O(log n)",
                 explanation: "매 단계마다 탐색 범위가 절반으로 줄어듭니다.",
                 concept: "탐색", tag: "Time Complexity"),
]

private let osQuestions: [QuizQuestion] = [
    QuizQuestion(id: 301, type: .mcq,
                 question: "교착상태(Deadlock) 발생 4가지 조건에 해당하지 않는 것은?",
                 choices: ["상호 배제", "점유 대기", "선점 가능", "환형 대기"],
                 correctIndex: 2, oxAnswer: "", fillAnswer: "",
                 explanation: "선점 불가능(Non-preemption)이 조건입니다. 선점 가능이면 교착상태가 발생하지 않습니다.",
                 concept: "교착상태", tag: "조건"),
    QuizQuestion(id: 302, type: .ox,
                 question: "세마포어(Semaphore)는 뮤텍스와 달리 여러 프로세스의 동시 접근을 허용할 수 있다.",
                 choices: [], correctIndex: -1, oxAnswer: "O", fillAnswer: "",
                 explanation: "카운팅 세마포어는 초기값에 따라 복수 접근이 가능합니다.",
                 concept: "동기화", tag: "세마포어"),
    QuizQuestion(id: 303, type: .mcq,
                 question: "페이지 교체 알고리즘 중 벨레이디의 역설(Belady's Anomaly)이 발생하는 것은?",
                 choices: ["LRU", "OPT", "FIFO", "LFU"],
                 correctIndex: 2, oxAnswer: "", fillAnswer: "",
                 explanation: "FIFO에서는 프레임 수를 늘려도 페이지 폴트가 증가하는 역설이 발생합니다.",
                 concept: "페이지 교체", tag: "FIFO"),
    QuizQuestion(id: 304, type: .ox,
                 question: "스레드는 같은 프로세스 내에서 코드, 데이터, 힙 영역을 공유한다.",
                 choices: [], correctIndex: -1, oxAnswer: "O", fillAnswer: "",
                 explanation: "스레드끼리는 메모리 공간을 공유하며 스택 영역만 독립적으로 갖습니다.",
                 concept: "스레드", tag: "메모리"),
    QuizQuestion(id: 305, type: .fill,
                 question: "현재 실행 중인 프로세스를 강제로 중단하고 다른 프로세스에 CPU를 할당하는 방식을 ___ 스케줄링이라 한다.",
                 choices: [], correctIndex: -1, oxAnswer: "", fillAnswer: "선점형",
                 explanation: "선점형 스케줄링은 OS가 CPU를 강제로 회수할 수 있습니다.",
                 concept: "스케줄링", tag: "개념"),
    QuizQuestion(id: 306, type: .mcq,
                 question: "가상 메모리(Virtual Memory)의 주된 목적은?",
                 choices: ["CPU 속도 향상", "실제 메모리보다 큰 프로세스 실행",
                           "디스크 용량 절약", "캐시 일관성 유지"],
                 correctIndex: 1, oxAnswer: "", fillAnswer: "",
                 explanation: "가상 메모리는 보조 기억 장치를 활용해 물리 메모리 제한을 넘어선 실행을 가능하게 합니다.",
                 concept: "가상 메모리", tag: "개념"),
    QuizQuestion(id: 307, type: .ox,
                 question: "컨텍스트 스위칭 시 PCB(Process Control Block)에 현재 상태가 저장된다.",
                 choices: [], correctIndex: -1, oxAnswer: "O", fillAnswer: "",
                 explanation: "PCB에는 레지스터, PC, 메모리 정보 등 프로세스 상태가 저장됩니다.",
                 concept: "프로세스", tag: "PCB"),
    QuizQuestion(id: 308, type: .fill,
                 question: "메모리 단편화 중 할당된 블록 사이에 사용할 수 없는 작은 공간이 생기는 현상을 ___ 단편화라 한다.",
                 choices: [], correctIndex: -1, oxAnswer: "", fillAnswer: "외부",
                 explanation: "외부 단편화는 전체 여유 공간은 충분하나 연속되지 않아 할당이 불가한 현상입니다.",
                 concept: "메모리 관리", tag: "단편화"),
]

private let dbQuestions: [QuizQuestion] = [
    QuizQuestion(id: 401, type: .mcq,
                 question: "ACID 속성 중 'I'가 의미하는 것은?",
                 choices: ["Integrity", "Index", "Isolation", "Integration"],
                 correctIndex: 2, oxAnswer: "", fillAnswer: "",
                 explanation: "Isolation(격리성): 동시에 실행되는 트랜잭션이 서로 영향을 주지 않아야 합니다.",
                 concept: "트랜잭션", tag: "ACID"),
    QuizQuestion(id: 402, type: .ox,
                 question: "인덱스(Index)는 SELECT 성능을 높이지만 INSERT/UPDATE 성능은 낮출 수 있다.",
                 choices: [], correctIndex: -1, oxAnswer: "O", fillAnswer: "",
                 explanation: "인덱스 추가 시 쓰기 작업마다 인덱스도 갱신되므로 쓰기 비용이 증가합니다.",
                 concept: "인덱스", tag: "Trade-off"),
    QuizQuestion(id: 403, type: .mcq,
                 question: "트랜잭션 격리 수준 중 가장 엄격한 것은?",
                 choices: ["READ UNCOMMITTED", "READ COMMITTED",
                           "REPEATABLE READ", "SERIALIZABLE"],
                 correctIndex: 3, oxAnswer: "", fillAnswer: "",
                 explanation: "SERIALIZABLE은 완전한 순차 실행을 보장하며 동시성은 가장 낮습니다.",
                 concept: "트랜잭션", tag: "격리 수준"),
    QuizQuestion(id: 404, type: .ox,
                 question: "정규화(Normalization)를 많이 할수록 조회 성능이 항상 좋아진다.",
                 choices: [], correctIndex: -1, oxAnswer: "X", fillAnswer: "",
                 explanation: "지나친 정규화는 JOIN 연산 증가로 오히려 조회 성능이 저하될 수 있습니다.",
                 concept: "정규화", tag: "Trade-off"),
    QuizQuestion(id: 405, type: .fill,
                 question: "다른 테이블의 기본 키(PK)를 참조하는 키를 ___ 키라 한다.",
                 choices: [], correctIndex: -1, oxAnswer: "", fillAnswer: "외래",
                 explanation: "외래 키(Foreign Key)는 테이블 간 관계를 정의하고 참조 무결성을 보장합니다.",
                 concept: "관계형 DB", tag: "Key"),
    QuizQuestion(id: 406, type: .mcq,
                 question: "SQL에서 GROUP BY와 함께 사용되며 그룹에 조건을 거는 절은?",
                 choices: ["WHERE", "HAVING", "ORDER BY", "LIMIT"],
                 correctIndex: 1, oxAnswer: "", fillAnswer: "",
                 explanation: "HAVING은 GROUP BY 결과에 조건을 적용합니다. WHERE는 그룹화 이전에 적용됩니다.",
                 concept: "SQL", tag: "쿼리"),
    QuizQuestion(id: 407, type: .ox,
                 question: "NoSQL 데이터베이스는 항상 ACID를 보장한다.",
                 choices: [], correctIndex: -1, oxAnswer: "X", fillAnswer: "",
                 explanation: "NoSQL은 일반적으로 CAP 정리에 따라 일관성보다 가용성·분산을 우선하며 BASE 모델을 따릅니다.",
                 concept: "NoSQL", tag: "특성"),
    QuizQuestion(id: 408, type: .fill,
                 question: "데이터베이스에서 중복 없이 각 행을 유일하게 식별하는 키를 ___ 키라 한다.",
                 choices: [], correctIndex: -1, oxAnswer: "", fillAnswer: "기본(Primary)",
                 explanation: "기본 키(Primary Key)는 NULL을 허용하지 않으며 테이블당 하나만 존재합니다.",
                 concept: "관계형 DB", tag: "Key"),
]

private let netQuestions: [QuizQuestion] = [
    QuizQuestion(id: 501, type: .mcq,
                 question: "HTTP 상태 코드 404가 의미하는 것은?",
                 choices: ["서버 내부 오류", "요청 리소스 없음", "권한 없음", "요청 성공"],
                 correctIndex: 1, oxAnswer: "", fillAnswer: "",
                 explanation: "404 Not Found: 요청한 리소스가 서버에 존재하지 않습니다.",
                 concept: "HTTP", tag: "상태 코드"),
    QuizQuestion(id: 502, type: .ox,
                 question: "TCP는 연결 지향적이며 데이터 전달의 신뢰성을 보장한다.",
                 choices: [], correctIndex: -1, oxAnswer: "O", fillAnswer: "",
                 explanation: "TCP는 3-way handshake, 순서 보장, 재전송으로 신뢰성을 확보합니다.",
                 concept: "TCP", tag: "특성"),
    QuizQuestion(id: 503, type: .mcq,
                 question: "TCP 3-way Handshake의 올바른 순서는?",
                 choices: ["ACK → SYN → SYN-ACK", "SYN → SYN-ACK → ACK",
                           "SYN-ACK → SYN → ACK", "SYN → ACK → SYN-ACK"],
                 correctIndex: 1, oxAnswer: "", fillAnswer: "",
                 explanation: "SYN(연결 요청) → SYN-ACK(응답) → ACK(확인) 순으로 연결이 수립됩니다.",
                 concept: "TCP", tag: "Handshake"),
    QuizQuestion(id: 504, type: .ox,
                 question: "UDP는 데이터 전달을 보장하지 않아 실시간 스트리밍에 적합하다.",
                 choices: [], correctIndex: -1, oxAnswer: "O", fillAnswer: "",
                 explanation: "UDP는 연결 설정과 재전송 없이 빠른 전송이 가능해 지연 허용도가 낮은 서비스에 적합합니다.",
                 concept: "UDP", tag: "특성"),
    QuizQuestion(id: 505, type: .fill,
                 question: "IP 주소를 MAC 주소로 변환하는 프로토콜은 ___이다.",
                 choices: [], correctIndex: -1, oxAnswer: "", fillAnswer: "ARP",
                 explanation: "ARP(Address Resolution Protocol)는 네트워크 계층의 IP를 링크 계층의 MAC으로 매핑합니다.",
                 concept: "프로토콜", tag: "ARP"),
    QuizQuestion(id: 506, type: .mcq,
                 question: "OSI 7계층에서 HTTP가 동작하는 계층은?",
                 choices: ["전송 계층", "네트워크 계층", "응용 계층", "세션 계층"],
                 correctIndex: 2, oxAnswer: "", fillAnswer: "",
                 explanation: "HTTP는 7계층인 응용 계층(Application Layer)에서 동작합니다.",
                 concept: "OSI 모델", tag: "계층"),
    QuizQuestion(id: 507, type: .ox,
                 question: "HTTPS는 HTTP에 SSL/TLS 암호화를 적용한 프로토콜이다.",
                 choices: [], correctIndex: -1, oxAnswer: "O", fillAnswer: "",
                 explanation: "HTTPS는 SSL/TLS 핸드셰이크를 통해 암호화된 통신 채널을 수립합니다.",
                 concept: "HTTPS", tag: "보안"),
    QuizQuestion(id: 508, type: .fill,
                 question: "DNS의 역할은 도메인 이름을 ___ 주소로 변환하는 것이다.",
                 choices: [], correctIndex: -1, oxAnswer: "", fillAnswer: "IP",
                 explanation: "DNS(Domain Name System)는 사람이 읽기 쉬운 도메인을 컴퓨터가 사용하는 IP로 변환합니다.",
                 concept: "DNS", tag: "역할"),
]

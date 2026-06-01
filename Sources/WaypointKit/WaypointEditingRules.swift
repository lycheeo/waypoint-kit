import CoreLocation
import Foundation

public struct RouteListEditingConversationTurn: Equatable {
    public var role: String
    public var text: String

    public init(role: String, text: String) {
        self.role = role
        self.text = text
    }
}

public struct RouteListEditResolveContext {
    public var currentPoints: [Waypoint]
    public var currentLocationPoint: Waypoint?
    public var userPrompt: String
    public var targetCity: String?
    public var structuredIntent: RouteListEditStructuredIntent?
    public var constraints: RouteEditActiveConstraints
    public var candidatePoints: [String: Waypoint]

    public init(
        currentPoints: [Waypoint],
        currentLocationPoint: Waypoint?,
        userPrompt: String,
        targetCity: String?,
        structuredIntent: RouteListEditStructuredIntent?,
        constraints: RouteEditActiveConstraints,
        candidatePoints: [String: Waypoint] = [:]
    ) {
        self.currentPoints = currentPoints
        self.currentLocationPoint = currentLocationPoint
        self.userPrompt = userPrompt
        self.targetCity = targetCity
        self.structuredIntent = structuredIntent
        self.constraints = constraints
        self.candidatePoints = candidatePoints
    }

    public var userRequestedCurrentLocation: Bool {
        if let requested = structuredIntent?.requestedCurrentLocation {
            return requested
        }
        return userPrompt.contains("current location") ||
            userPrompt.contains("当前位置") ||
            userPrompt.contains("当前定位") ||
            userPrompt.contains("我的位置") ||
            userPrompt.contains("从这里") ||
            userPrompt.contains("从这儿")
    }

    public var userRequestedFood: Bool {
        if let requested = structuredIntent?.requestedFood {
            return requested
        }
        return ["lunch", "dinner", "restaurant", "food", "中午", "午餐", "晚餐", "吃饭", "吃", "餐厅", "本地菜", "美食", "早餐", "宵夜"]
            .contains { userPrompt.localizedCaseInsensitiveContains($0) }
    }

    public var routeTheme: String {
        structuredIntent?.routeTheme ?? userPrompt
    }

    public var intentText: String {
        [
            structuredIntent?.targetCity,
            structuredIntent?.routeTheme,
            structuredIntent?.pace,
            structuredIntent?.mobility,
            structuredIntent?.personalNeeds?.joined(separator: " "),
            structuredIntent?.requiredPlaceKinds?.joined(separator: " "),
            structuredIntent?.avoidPlaceKinds?.joined(separator: " ")
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }

    public var existingCurrentLocationPoint: Waypoint? {
        currentPoints.first { RouteListEditingPointRules.isCurrentLocationPoint($0) }
    }

    public func shouldDropUnrequestedFoodTarget(_ target: RouteListEditTargetPoint) -> Bool {
        guard !userRequestedFood else { return false }
        let text = "\(target.displayName ?? "") \(target.searchQuery ?? "") \(target.placeQuery ?? "") \(target.purpose ?? "") \(target.placeKind ?? "")"
        return target.placeKind == "food" ||
            ["餐", "饭", "粉", "菜", "酒楼", "茶餐厅", "火锅", "咖啡", "酒店", "宾馆"].contains { text.contains($0) }
    }

    public var searchCenter: CLLocationCoordinate2D? {
        currentLocationPoint?.coordinate ?? averageCoordinate(for: currentPoints)
    }

    public var searchRadius: CLLocationDistance {
        currentPoints.isEmpty ? 200_000 : 120_000
    }

    public func preferredPoint(
        from points: [Waypoint],
        target: RouteListEditTargetPoint,
        query: String
    ) -> Waypoint? {
        points
            .map { point in
                (point: point, score: candidateScore(point, target: target, query: query))
            }
            .filter { $0.score > 20 }
            .sorted { $0.score > $1.score }
            .first?.point
    }

    private func candidateScore(_ point: Waypoint, target: RouteListEditTargetPoint, query: String) -> Int {
        let pointText = RouteListEditingPointRules.text(for: point)
        let normalizedPointName = RouteListEditingPointRules.normalizedName(point.name)
        let expected = RouteListEditingPointRules.normalizedName(target.displayName ?? target.searchQuery ?? target.placeQuery ?? query)
        let city = RouteListEditingPointRules.normalizedName(target.city ?? targetCity ?? RouteListEditingTextRules.inferredCityText(from: query))
        var score = 0

        if !city.isEmpty,
           RouteListEditingPointRules.normalizedName(point.cityName ?? "").contains(city.replacingOccurrences(of: "市", with: "")) {
            score += 40
        }

        if normalizedPointName == expected {
            score += 120
        } else if normalizedPointName.contains(expected) || expected.contains(normalizedPointName) {
            score += 80
        } else {
            score += Set(expected).reduce(0) { score, character in
                normalizedPointName.contains(character) ? score + 7 : score
            }
        }

        switch target.placeKind {
        case "food":
            score += RouteListEditingPointRules.isFoodPoint(point) ? 90 : -90
        case "indoor":
            score += RouteListEditingPointRules.isIndoorPoint(point) ? 90 : -80
        case "family", "scenic", "nature":
            score += ["风景名胜", "体育休闲", "科教文化", "公园", "动物", "乐园", "科技"].contains { pointText.contains($0) } ? 45 : 0
        default:
            break
        }

        if ["公交", "停车", "道路", "售票", "游客中心", "入口", "出口"].contains(where: { pointText.contains($0) }) {
            score -= 120
        }
        if isAdministrativeOrUtilityPoint(pointText, point: point) {
            score -= 260
        }
        if !userRequestedFood, RouteListEditingPointRules.isFoodPoint(point) {
            score -= 220
        }
        if constraints.noSea, RouteListEditingPointRules.isSeaPoint(point) {
            score -= 300
        }
        if constraints.noMuseum, pointText.contains("博物馆") {
            score -= 220
        }
        if constraints.noCommercial, RouteListEditingPointRules.isCommercialPoint(point) {
            score -= 160
        }

        if let center = searchCenter, !currentPoints.isEmpty {
            let distance = CLLocation(latitude: center.latitude, longitude: center.longitude)
                .distance(from: CLLocation(latitude: point.latitude, longitude: point.longitude))
            if distance > 220_000, !isRegionExplicitlyMentioned(point) {
                score -= 90
            }
        }

        return score
    }

    private func isAdministrativeOrUtilityPoint(_ text: String, point: Waypoint) -> Bool {
        let nameAndCategory = "\(point.name) \(point.poiCategory ?? "")"
        let administrativeKeywords = ["管理处", "办公室", "委员会", "政府", "公司", "售票处", "公交站", "停车场", "入口", "出口"]
        let lodgingKeywords = ["酒店", "宾馆", "民宿"]

        if userRequestedFood, RouteListEditingPointRules.isFoodPoint(point) {
            return administrativeKeywords.contains { nameAndCategory.contains($0) }
        }

        return administrativeKeywords.contains { nameAndCategory.contains($0) } ||
            lodgingKeywords.contains { nameAndCategory.contains($0) }
    }

    private func isRegionExplicitlyMentioned(_ point: Waypoint) -> Bool {
        let text = "\(userPrompt) \(targetCity ?? "") \(routeTheme)"
        let regionValues = [
            point.cityName,
            point.districtName,
            point.adcode,
            Optional(point.name),
            Optional(point.address)
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        return regionValues.contains { text.contains($0) }
    }

    private func averageCoordinate(for points: [Waypoint]) -> CLLocationCoordinate2D? {
        guard !points.isEmpty else { return nil }
        let latitude = points.reduce(0) { $0 + $1.latitude } / Double(points.count)
        let longitude = points.reduce(0) { $0 + $1.longitude } / Double(points.count)
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

public struct RouteEditActiveConstraints {
    public var noSea: Bool
    public var noMuseum: Bool
    public var noCommercial: Bool
    public var requiresNonMuseumVariety: Bool

    public init(
        noSea: Bool = false,
        noMuseum: Bool = false,
        noCommercial: Bool = false,
        requiresNonMuseumVariety: Bool = false
    ) {
        self.noSea = noSea
        self.noMuseum = noMuseum
        self.noCommercial = noCommercial
        self.requiresNonMuseumVariety = requiresNonMuseumVariety
    }

    public init(
        conversationTurns: [RouteListEditingConversationTurn],
        userPrompt: String,
        planConstraints: RouteListEditConstraints?
    ) {
        let historyText = conversationTurns
            .map(\.text)
            .suffix(8)
            .joined(separator: " ")
        let text = "\(historyText) \(userPrompt)"
        noSea = text.contains("不要海边") || text.contains("不去海边") || text.contains("不要看海") ||
            (planConstraints?.avoid ?? []).contains { $0.contains("海边") || $0.contains("看海") }
        noMuseum = text.contains("不要博物馆") ||
            (planConstraints?.avoid ?? []).contains { $0.contains("博物馆") }
        requiresNonMuseumVariety = text.contains("不要全是博物馆") ||
            text.contains("别全是博物馆") ||
            text.contains("不全是博物馆") ||
            text.contains("穿插一个轻松逛") ||
            text.contains("穿插轻松逛")
        noCommercial = text.contains("不要太商业") || text.contains("不商业") || text.contains("换自然一点") || text.contains("自然一点") ||
            text.contains("不要商场") || text.contains("不要购物中心") || text.contains("非商场") || text.contains("商场里") ||
            (planConstraints?.avoid ?? []).contains { $0.contains("商业") || $0.contains("购物") || $0.contains("商场") }
    }
}

public enum RouteListEditingPointRules {
    public static func isSamePlace(_ left: Waypoint, _ right: Waypoint) -> Bool {
        if left.name == right.name { return true }
        let leftLocation = CLLocation(latitude: left.latitude, longitude: left.longitude)
        let rightLocation = CLLocation(latitude: right.latitude, longitude: right.longitude)
        return leftLocation.distance(from: rightLocation) < 100
    }

    public static func normalizedName(_ value: String) -> String {
        value
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "·", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "（", with: "")
            .replacingOccurrences(of: "）", with: "")
            .lowercased()
    }

    public static func text(for point: Waypoint) -> String {
        "\(point.name) \(point.address) \(point.cityName ?? "") \(point.districtName ?? "") \(point.poiCategory ?? "")"
    }

    public static func isCurrentLocationPoint(_ point: Waypoint) -> Bool {
        point.source == .gps || normalizedName(point.name) == normalizedName("当前位置")
    }

    public static func isFoodPoint(_ point: Waypoint) -> Bool {
        let pointText = text(for: point)
        return ["餐", "菜", "饭", "酒楼", "茶", "美食", "餐饮服务", "中餐厅", "火锅", "咖啡"].contains {
            pointText.contains($0)
        }
    }

    public static func isExperiencePoint(_ point: Waypoint) -> Bool {
        !isCurrentLocationPoint(point) && !isFoodPoint(point)
    }

    public static func isSeaPoint(_ point: Waypoint) -> Bool {
        let pointText = text(for: point)
        return ["海边", "沙滩", "海岸", "情侣路", "渔女", "海滩", "湾仔", "海鲜街", "较场尾", "看海"].contains {
            pointText.contains($0)
        }
    }

    public static func isIndoorPoint(_ point: Waypoint) -> Bool {
        let pointText = text(for: point)
        let hasIndoorSignal = ["馆", "中心", "商场", "室内", "博物", "科技", "剧场", "影城", "书店", "展览", "购物服务", "科学"].contains {
            pointText.contains($0)
        }
        let hasOutdoorSignal = ["公园", "沙滩", "海边", "海岸", "户外", "动物世界", "飞鸟乐园", "城墙", "不夜城", "芙蓉园", "遗址公园", "景山", "香山"].contains {
            pointText.contains($0)
        }
        return hasIndoorSignal && !hasOutdoorSignal
    }

    public static func isCommercialPoint(_ point: Waypoint) -> Bool {
        let pointText = text(for: point)
        return ["购物", "商场", "购物中心", "综合市场", "特色商业街", "酒店", "民宿", "商业", "百货", "步行街", "古街", "锦里", "宽窄巷子", "春熙路", "太古里", "IFS", "万象城", "万达"].contains {
            pointText.contains($0)
        }
    }
}

public enum RouteListEditingTextRules {
    public static func normalizedOptional(_ text: String?) -> String? {
        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    public static func normalizedCity(_ city: String?) -> String? {
        guard let value = normalizedOptional(city) else { return nil }
        if value.contains("珠海") { return "珠海市" }
        if value.contains("广州") { return "广州市" }
        if value.contains("郴州") { return "郴州市" }
        if value.contains("杭州") { return "杭州市" }
        if value.contains("成都") { return "成都市" }
        if value.contains("厦门") { return "厦门市" }
        if value.contains("北京") { return "北京市" }
        if value.contains("苏州") { return "苏州市" }
        if value.contains("南京") { return "南京市" }
        if value.contains("西安") { return "西安市" }
        if value.contains("长沙") { return "长沙市" }
        if value.contains("桂林") { return "桂林市" }
        if value.contains("深圳") || value.contains("大鹏") || value.contains("南山") || value.contains("福田") { return "深圳市" }
        return value
    }

    public static func inferredCityText(from text: String) -> String {
        if text.contains("珠海") { return "珠海市" }
        if text.contains("广州") { return "广州市" }
        if text.contains("郴州") { return "郴州市" }
        if text.contains("杭州") { return "杭州市" }
        if text.contains("成都") { return "成都市" }
        if text.contains("厦门") { return "厦门市" }
        if text.contains("北京") { return "北京市" }
        if text.contains("苏州") { return "苏州市" }
        if text.contains("南京") { return "南京市" }
        if text.contains("西安") { return "西安市" }
        if text.contains("长沙") { return "长沙市" }
        if text.contains("桂林") { return "桂林市" }
        if text.contains("深圳") || text.contains("大鹏") || text.contains("南山") { return "深圳市" }
        return ""
    }

    public static func isCurrentLocationTarget(_ target: RouteListEditTargetPoint) -> Bool {
        let text = "\(target.displayName ?? "") \(target.searchQuery ?? "") \(target.placeQuery ?? "") \(target.addressHint ?? "") \(target.placeKind ?? "") \(target.purpose ?? "")"
        if text.contains("当前位置") || text.contains("当前定位") || text.contains("我的位置") || text.contains("返回起点") || text.contains("回到起点") {
            return true
        }
        if target.placeKind == "return", text.contains("起点") {
            return true
        }
        return false
    }

    public static func isCurrentLocationText(_ text: String) -> Bool {
        text.contains("当前位置") || text.contains("当前定位") || text.contains("我的位置") ||
            text.contains("返回起点") || text.contains("回到起点")
    }

    public static func isGenericSearchQuery(_ query: String) -> Bool {
        let normalized = RouteListEditingPointRules.normalizedName(query)
        if normalized.contains("本地菜餐厅") || normalized.contains("本地餐厅") || normalized.contains("当地菜餐厅") {
            return true
        }
        let genericValues = [
            "珠海", "珠海市", "深圳", "深圳市", "广州", "广州市", "郴州", "郴州市", "杭州", "杭州市", "成都", "成都市",
            "厦门", "厦门市", "北京", "北京市", "苏州", "苏州市", "南京", "南京市", "西安", "西安市", "长沙", "长沙市",
            "桂林", "桂林市", "南山", "餐厅", "景点", "本地菜",
            "海边", "看海", "亲子", "室内", "返回", "回程", "目的地", "终点", "起点"
        ]
        return genericValues.contains(normalized)
    }

    public static func defaultStayMinutes(for target: RouteListEditTargetPoint) -> Int {
        switch target.placeKind {
        case "food": 75
        case "scenic", "family", "indoor", "nature": 90
        default: 45
        }
    }

    public static func isCurrentLocationOnlyAnswer(_ text: String) -> Bool {
        let value = RouteListEditingPointRules.normalizedName(text)
        return value == "当前位置" || value == "用当前位置" || value == "我的位置"
    }
}

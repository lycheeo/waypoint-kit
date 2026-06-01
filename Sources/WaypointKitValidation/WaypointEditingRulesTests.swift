import WaypointKit

struct WaypointEditingRulesTests {
    func testSamePlaceUsesRouteEditingToleranceAndNameFallback() {
        let first = Waypoint(name: "人民广场", address: "上海市黄浦区", latitude: 31.2304, longitude: 121.4737)
        let sameNameFarAway = Waypoint(name: "人民广场", address: "different", latitude: 22.0, longitude: 113.0)
        let nearby = Waypoint(name: "人民广场地铁站", address: "上海市黄浦区", latitude: 31.23045, longitude: 121.47375)
        let farAway = Waypoint(name: "外滩", address: "上海市黄浦区", latitude: 31.2397, longitude: 121.4998)

        XCTAssertTrue(RouteListEditingPointRules.isSamePlace(first, sameNameFarAway))
        XCTAssertTrue(RouteListEditingPointRules.isSamePlace(first, nearby))
        XCTAssertFalse(RouteListEditingPointRules.isSamePlace(first, farAway))
    }
    func testPointSemanticCategories() {
        let food = Waypoint(
            name: "猪肉婆私房菜",
            address: "珠海市香洲区",
            latitude: 22.27,
            longitude: 113.55,
            poiCategory: "餐饮服务;中餐厅"
        )
        let sea = Waypoint(
            name: "黄厝海滩",
            address: "厦门市思明区",
            latitude: 24.43,
            longitude: 118.16,
            poiCategory: "风景名胜;海滩"
        )
        let indoor = Waypoint(
            name: "四川科技馆",
            address: "成都市青羊区",
            latitude: 30.66,
            longitude: 104.06,
            poiCategory: "科教文化服务;科技馆"
        )
        let commercial = Waypoint(
            name: "太古里",
            address: "成都市锦江区",
            latitude: 30.65,
            longitude: 104.08,
            poiCategory: "购物服务;购物中心"
        )
        let current = Waypoint(
            name: "当前位置",
            address: "深圳市南山区",
            latitude: 22.53,
            longitude: 113.93,
            source: .gps
        )

        XCTAssertTrue(RouteListEditingPointRules.isFoodPoint(food))
        XCTAssertTrue(RouteListEditingPointRules.isSeaPoint(sea))
        XCTAssertTrue(RouteListEditingPointRules.isIndoorPoint(indoor))
        XCTAssertTrue(RouteListEditingPointRules.isCommercialPoint(commercial))
        XCTAssertTrue(RouteListEditingPointRules.isCurrentLocationPoint(current))
        XCTAssertFalse(RouteListEditingPointRules.isExperiencePoint(food))
    }
    func testCityNormalizationAndInference() {
        XCTAssertEqual(RouteListEditingTextRules.normalizedCity("大鹏新区"), "深圳市")
        XCTAssertEqual(RouteListEditingTextRules.normalizedCity("北京"), "北京市")
        XCTAssertEqual(RouteListEditingTextRules.inferredCityText(from: "想去郴州看丹霞"), "郴州市")
        XCTAssertNil(RouteListEditingTextRules.normalizedOptional("   "))
    }
    func testCurrentLocationTargetDetection() {
        let currentLocation = target(displayName: "当前位置", placeKind: "origin")
        let returnToOrigin = target(displayName: "返回起点", placeKind: "return")
        let regularPlace = target(displayName: "黄厝海滩", placeKind: "scenic")

        XCTAssertTrue(RouteListEditingTextRules.isCurrentLocationTarget(currentLocation))
        XCTAssertTrue(RouteListEditingTextRules.isCurrentLocationTarget(returnToOrigin))
        XCTAssertFalse(RouteListEditingTextRules.isCurrentLocationTarget(regularPlace))
        XCTAssertTrue(RouteListEditingTextRules.isCurrentLocationOnlyAnswer("用当前位置"))
    }
    func testSearchAndStayRules() {
        XCTAssertTrue(RouteListEditingTextRules.isGenericSearchQuery("本地菜餐厅"))
        XCTAssertTrue(RouteListEditingTextRules.isGenericSearchQuery("珠海"))
        XCTAssertFalse(RouteListEditingTextRules.isGenericSearchQuery("台州府城墙"))
        XCTAssertEqual(RouteListEditingTextRules.defaultStayMinutes(for: target(placeKind: "food")), 75)
        XCTAssertEqual(RouteListEditingTextRules.defaultStayMinutes(for: target(placeKind: "indoor")), 90)
        XCTAssertEqual(RouteListEditingTextRules.defaultStayMinutes(for: target(placeKind: "other")), 45)
    }
    func testPreferredPointFiltersAdministrativePOIs() {
        let context = RouteListEditResolveContext(
            currentPoints: [],
            currentLocationPoint: nil,
            userPrompt: "珠海一日游，加一个看海点",
            targetCity: "珠海市",
            structuredIntent: RouteListEditStructuredIntent(targetCity: "珠海市", routeTheme: "看海"),
            constraints: RouteEditActiveConstraints()
        )
        let target = target(displayName: "珠海渔女", city: "珠海市", placeKind: "scenic")
        let candidates = [
            Waypoint(name: "珠海渔女停车场", address: "珠海市香洲区", latitude: 22.25, longitude: 113.58, poiCategory: "停车场", cityName: "珠海市"),
            Waypoint(name: "珠海渔女", address: "珠海市香洲区", latitude: 22.25, longitude: 113.58, poiCategory: "风景名胜", cityName: "珠海市")
        ]

        XCTAssertEqual(context.preferredPoint(from: candidates, target: target, query: "珠海渔女")?.name, "珠海渔女")
    }
    func testPromptBuilderIncludesCurrentWaypointsAndHistory() {
        let prompt = RouteListEditingPromptBuilder.userPromptForEdit(
            currentPoints: [
                Waypoint(name: "People's Square", address: "Shanghai", latitude: 31.2304, longitude: 121.4737)
            ],
            userPrompt: "replace the final stop",
            conversationTurns: [
                RouteListEditingConversationTurn(role: "assistant", text: "What city?")
            ]
        )

        XCTAssertTrue(prompt.contains("People's Square"))
        XCTAssertTrue(prompt.contains("replace the final stop"))
        XCTAssertTrue(prompt.contains("Do not invent coordinates"))
    }
    func testToolSchemasExposeEditAndSearchTools() {
        let edit = RouteListEditingToolSchemas.openAIEditToolSchema
        let search = RouteListEditingToolSchemas.searchPOIsToolSchema

        XCTAssertEqual(edit["name"] as? String, "edit_route_points")
        XCTAssertEqual(search["name"] as? String, "search_pois")
    }

    private func target(
        displayName: String? = nil,
        city: String? = nil,
        placeKind: String? = nil
    ) -> RouteListEditTargetPoint {
        RouteListEditTargetPoint(displayName: displayName, city: city, placeKind: placeKind)
    }
}

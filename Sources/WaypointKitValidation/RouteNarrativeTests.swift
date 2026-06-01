import WaypointKit

struct RouteNarrativeTests {
    func testDialogueScenariosProduceSpecificProposalNarratives() {
        let scenarios = [
            zhuhaiDialogue(),
            localEditDialogue(),
            chengduFamilyDialogue()
        ]

        for scenario in scenarios {
            XCTAssertEqual(scenario.turns.count, 3, scenario.name)
            for turn in scenario.turns {
                let proposal = proposalForTurn(turn)
                let text = RouteChangeProposalNarrative.assistantText(for: proposal)
                let lines = RouteChangeProposalNarrative.changeLines(for: proposal)

                XCTAssertTrue(text.contains("proposal"), turn.name)
                XCTAssertFalse(lines.isEmpty, turn.name)
                XCTAssertTrue(lines.contains { $0.contains(turn.expectedKeyword) }, turn.name)
                XCTAssertFalse(RouteChangeProposalNarrative.cardTitle(for: proposal).isEmpty, turn.name)
            }
        }
    }
    func testFailureNarrativeKeepsCurrentListSafeAndActionable() {
        let message = RouteEditingFailureNarrative.message(from: "model output could not parse, waypoint list was not changed.")

        XCTAssertTrue(message.contains("was not changed"))
        XCTAssertTrue(message.contains("Reason: model output could not parse"))
        XCTAssertTrue(message.contains("retry"))
        XCTAssertTrue(RouteEditingFailureNarrative.isFailureMessage("model output could not parse, waypoint list was not changed."))
        XCTAssertFalse(RouteEditingFailureNarrative.isFailureMessage("Where do you want to start?"))
    }

    private func proposalForTurn(_ turn: DialogueTurn) -> RouteChangeProposal {
        RouteChangeProposal(
            baseRouteVersion: 1,
            source: .ai,
            userPrompt: turn.name,
            beforePoints: turn.before,
            proposedPoints: turn.after,
            proposedRouteName: nil,
            summary: turn.summary,
            changes: RouteChangeDiffBuilder.changes(before: turn.before, after: turn.after),
            warnings: RouteChangeDiffBuilder.warnings(for: turn.after)
        )
    }

    private func zhuhaiDialogue() -> DialogueScenario {
        let initial = [
            point("深圳湾口岸", "深圳市南山区", 22.50, 113.94),
            point("珠海渔女", "珠海市香洲区", 22.25, 113.58),
            point("猪肉婆私房菜(珠海店)", "珠海市香洲区", 22.27, 113.55),
            point("珠海日月贝", "珠海市香洲区", 22.28, 113.59)
        ]
        let indoor = [
            initial[0],
            point("珠海太空中心", "珠海市金湾区", 22.08, 113.37),
            initial[2],
            initial[3]
        ]
        let returning = indoor + [point("南山文体中心", "深圳市南山区", 22.53, 113.93)]
        return DialogueScenario(name: "珠海", turns: [
            DialogueTurn(name: "从深圳湾口岸出发去珠海一日游", before: [], after: initial, summary: "Prepared Zhuhai day trip.", expectedKeyword: "Add"),
            DialogueTurn(name: "不要海边太多，加一个室内点", before: initial, after: indoor, summary: "Reduced coastal stops and added indoor option.", expectedKeyword: "Replace"),
            DialogueTurn(name: "最后回深圳南山", before: indoor, after: returning, summary: "Added return point.", expectedKeyword: "Add")
        ])
    }

    private func localEditDialogue() -> DialogueScenario {
        let old = [
            point("深圳湾公园", "深圳市南山区", 22.52, 113.94),
            point("欢乐海岸", "深圳市南山区", 22.53, 113.98),
            point("世界之窗", "深圳市南山区", 22.54, 113.97)
        ]
        let originChanged = [point("深圳湾口岸", "深圳市南山区", 22.50, 113.94)] + old.dropFirst()
        let withFood = originChanged + [point("麦当劳(世界之窗店)", "深圳市南山区", 22.54, 113.97)]
        var deleted = withFood
        deleted.remove(at: 1)
        return DialogueScenario(name: "局部编辑", turns: [
            DialogueTurn(name: "起点改成深圳湾口岸，其他不变", before: old, after: originChanged, summary: "Only replaced origin.", expectedKeyword: "Replace"),
            DialogueTurn(name: "最后加一个附近麦当劳", before: originChanged, after: withFood, summary: "Added McDonald's at the end.", expectedKeyword: "Add"),
            DialogueTurn(name: "删掉第二个点", before: withFood, after: deleted, summary: "Deleted second point.", expectedKeyword: "Remove")
        ])
    }

    private func chengduFamilyDialogue() -> DialogueScenario {
        let initial = [
            point("成都大熊猫繁育研究基地", "成都市成华区", 30.74, 104.14),
            point("成都自然博物馆", "成都市成华区", 30.68, 104.10),
            point("蓉小馆", "成都市武侯区", 30.58, 104.06),
            point("东安湖公园", "成都市龙泉驿区", 30.57, 104.27)
        ]
        var rainy = initial
        rainy[3] = point("四川科技馆", "成都市青羊区", 30.66, 104.06)
        var relaxed = rainy
        relaxed.remove(at: 1)
        return DialogueScenario(name: "成都亲子", turns: [
            DialogueTurn(name: "成都亲子一日游，不要太商业", before: [], after: initial, summary: "Prepared family route.", expectedKeyword: "Add"),
            DialogueTurn(name: "下雨了，尽量室内", before: initial, after: rainy, summary: "Added indoor stop.", expectedKeyword: "Replace"),
            DialogueTurn(name: "太赶了，少一个点但午餐保留", before: rainy, after: relaxed, summary: "Removed one non-food stop.", expectedKeyword: "Remove")
        ])
    }

    private func point(_ name: String, _ address: String, _ latitude: Double, _ longitude: Double) -> Waypoint {
        Waypoint(name: name, address: address, latitude: latitude, longitude: longitude)
    }
}

private struct DialogueScenario {
    var name: String
    var turns: [DialogueTurn]
}

private struct DialogueTurn {
    var name: String
    var before: [Waypoint]
    var after: [Waypoint]
    var summary: String
    var expectedKeyword: String
}

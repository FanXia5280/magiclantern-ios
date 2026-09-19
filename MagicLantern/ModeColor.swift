import Foundation

/// 按模式名称解析出代表色（用于卡片左侧的小色点）
enum ModeColor {

    private static let red = FlowData.red
    private static let yellow = FlowData.yellow
    private static let green = FlowData.green
    private static let cyan = FlowData.cyan
    private static let blue = FlowData.blue
    private static let purple = FlowData.purple
    private static let white = FlowData.white
    private static let orange = 0xFF8000
    private static let pink = 0xFF3D8A

    /// 彩虹（多色效果用）
    private static let rainbow = FlowData.rainbow

    static func colors(forName name: String) -> [Int] {
        // 1) 多色 / 炫彩类
        if hit(name, ["七彩", "七色", "幻彩", "彩虹", "自动循环", "炫彩", "迪斯科", "烟花", "聚会", "派对"]) {
            return rainbow
        }

        // 2) 场景类按语义映射
        if let scene = sceneColors(name) {
            return scene
        }

        // 3) 按名称里的颜色词提取（支持多色组合）
        var list: [Int] = []
        if name.contains("红") { list.append(red) }
        if name.contains("绿") { list.append(green) }
        if name.contains("蓝") { list.append(blue) }
        if name.contains("黄") { list.append(yellow) }
        if name.contains("青") { list.append(cyan) }
        if name.contains("紫") { list.append(purple) }
        if name.contains("白") { list.append(white) }
        if name.contains("橙") { list.append(orange) }
        if name.contains("粉") { list.append(pink) }

        if list.isEmpty {
            list = [blue, purple]
        }
        return list
    }

    private static func sceneColors(_ name: String) -> [Int]? {
        if hit(name, ["日出", "日落", "烛光", "火焰", "警报", "万圣节"]) {
            return [orange, red]
        }
        if hit(name, ["海洋", "流水", "睡眠", "星空"]) {
            return [blue, cyan]
        }
        if hit(name, ["森林"]) {
            return [green, cyan]
        }
        if hit(name, ["雪花"]) {
            return [white, cyan]
        }
        if hit(name, ["浪漫", "情人节", "约会", "结婚纪念日"]) {
            return [pink, purple]
        }
        if hit(name, ["圣诞"]) {
            return [red, green]
        }
        if hit(name, ["生日", "柔和", "阅读", "工作", "电影"]) {
            return [yellow, orange]
        }
        if hit(name, ["闪电"]) {
            return [white, blue]
        }
        return nil
    }

    private static func hit(_ name: String, _ keys: [String]) -> Bool {
        for k in keys where name.contains(k) {
            return true
        }
        return false
    }
}

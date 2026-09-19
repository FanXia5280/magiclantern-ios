import Foundation

/// 固件"双色流动"效果表（设备端执行，点一次永久生效）
enum FlowData {

    static let red = 0xFF0000
    static let yellow = 0xFFFF00
    static let green = 0x00FF00
    static let cyan = 0x00FFFF
    static let blue = 0x0000FF
    static let purple = 0xFF00FF
    static let white = 0xFFFFFF
    static let black = 0x000000

    static let rainbow = [red, yellow, green, cyan, blue, purple]

    struct Group {
        let title: String
        let names: [String]
        let cmds: [Int]
        let colors: [[Int]]
    }

    static let groups: [Group] = [

        Group(title: "交替渐变 · 两色来回渐变",
              names: ["七色渐变", "红黄交替渐变", "红紫交替渐变",
                      "绿青交替渐变", "绿黄交替渐变", "蓝紫交替渐变"],
              cmds: [199, 200, 201, 202, 203, 204],
              colors: [rainbow,
                       [red, yellow],
                       [red, purple],
                       [green, cyan],
                       [green, yellow],
                       [blue, purple]]),

        Group(title: "双色流水 · 正向 / 反向",
              names: ["正向红绿流水", "反向红绿流水", "正向绿蓝流水", "反向绿蓝流水",
                      "正向黄蓝流水", "反向黄蓝流水", "正向黄青流水", "反向黄青流水",
                      "正向青紫流水", "反向青紫流水", "正向黑白流水", "反向黑白流水"],
              cmds: [45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56],
              colors: [[red, green], [red, green],
                       [green, blue], [green, blue],
                       [yellow, blue], [yellow, blue],
                       [yellow, cyan], [yellow, cyan],
                       [cyan, purple], [cyan, purple],
                       [black, white], [black, white]]),

        Group(title: "多色流水 · 正向 / 反向",
              names: ["正向七彩流水", "反向七彩流水", "正向蓝绿红流水",
                      "反向红绿蓝流水", "正向紫青黄流水", "反向黄青紫流水"],
              cmds: [39, 40, 41, 42, 43, 44],
              colors: [rainbow, rainbow,
                       [blue, green, red],
                       [red, green, blue],
                       [purple, cyan, yellow],
                       [yellow, cyan, purple]]),

        Group(title: "双色流动 · 正向 / 反向",
              names: ["正向白红白流动", "反向白红白流动", "正向白绿白流动", "反向白绿白流动",
                      "正向白蓝白流动", "反向白蓝白流动", "正向白黄白流动", "反向白黄白流动",
                      "正向白青白流动", "反向白青白流动", "正向白紫白流动", "反向白紫白流动",
                      "正向红白红流动", "反向红白红流动", "正向绿白绿流动", "反向绿白绿流动",
                      "正向蓝白蓝流动", "反向蓝白蓝流动", "正向黄白黄流动", "反向黄白黄流动",
                      "正向青白青流动", "反向青白青流动", "正向紫白紫流动", "反向紫白紫流动"],
              cmds: [143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154,
                     155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166],
              colors: [[white, red], [white, red],
                       [white, green], [white, green],
                       [white, blue], [white, blue],
                       [white, yellow], [white, yellow],
                       [white, cyan], [white, cyan],
                       [white, purple], [white, purple],
                       [red, white], [red, white],
                       [green, white], [green, white],
                       [blue, white], [blue, white],
                       [yellow, white], [yellow, white],
                       [cyan, white], [cyan, white],
                       [purple, white], [purple, white]]),

        Group(title: "单色拖尾 · 正向 / 反向（黑底）",
              names: ["正向七彩拖尾", "反向七彩拖尾", "正向红色拖尾", "反向红色拖尾",
                      "正向绿色拖尾", "反向绿色拖尾", "正向蓝色拖尾", "反向蓝色拖尾",
                      "正向黄色拖尾", "反向黄色拖尾", "正向青色拖尾", "反向青色拖尾",
                      "正向紫色拖尾", "反向紫色拖尾", "正向白色拖尾", "反向白色拖尾"],
              cmds: [23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38],
              colors: [rainbow, rainbow,
                       [red, black], [red, black],
                       [green, black], [green, black],
                       [blue, black], [blue, black],
                       [yellow, black], [yellow, black],
                       [cyan, black], [cyan, black],
                       [purple, black], [purple, black],
                       [white, black], [white, black]]),

        Group(title: "开合 · 闭幕 / 拉幕",
              names: ["七彩闭幕", "七彩拉幕", "红绿蓝闭幕", "红绿蓝拉幕",
                      "黄青紫闭幕", "黄青紫拉幕", "红色闭幕", "红色拉幕",
                      "绿色闭幕", "绿色拉幕", "蓝色闭幕", "蓝色拉幕",
                      "黄色闭幕", "黄色拉幕", "青色闭幕", "青色拉幕",
                      "紫色闭幕", "紫色拉幕", "白色闭幕", "白色拉幕"],
              cmds: [57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76],
              colors: [rainbow, rainbow,
                       [red, green, blue], [red, green, blue],
                       [yellow, cyan, purple], [yellow, cyan, purple],
                       [red, black], [red, black],
                       [green, black], [green, black],
                       [blue, black], [blue, black],
                       [yellow, black], [yellow, black],
                       [cyan, black], [cyan, black],
                       [purple, black], [purple, black],
                       [white, black], [white, black]])
    ]
}

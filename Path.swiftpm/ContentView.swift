import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .trailing) {
            Circle()
                .frame(width: 50, height: 50)
                .foregroundColor(.red)
                .alignmentGuide(.trailing) { d in
                    d[.trailing]
                }
            Circle()
                .frame(width: 50, height: 50)
                .foregroundColor(.green)
                .alignmentGuide(.trailing) { d in
                    d[.trailing] - 20
                }
            Circle()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
                .alignmentGuide(.trailing) { d in
                    d[.trailing] - 40
                }
        }
        .shadow(radius: 10)
        .foregroundColor(.white)
        .frame(width: 100)
        .padding()
        .background(
            Warhead()
                .foregroundColor(.gray)
        )
    }
}


/// 三角形
struct Traignle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: .zero)
            path.addLine(to: .init(x: 0, y: rect.height))
            path.addLine(to: .init(x: rect.width, y: rect.height/2))
            path.closeSubpath()
        }
    }
}


/// 半圆
struct Semicircle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            // 画笔移动到圆的中心点
            path.move(to: .init(x: rect.width/2, y: rect.height/2))
            // 画一个圆弧
            path.addArc(
                // 圆的中心点
                center: .init(x: rect.width/2, y: rect.height/2),
                // 圆的半径
                radius: rect.width/2,
                // 开始角度
                startAngle: .degrees(0), // 注意角度的变化：右 0 度 ，下 90 度，左 180 度。
                // 结束角度
                endAngle: .degrees(180),
                // 逆时针
                clockwise: false)
        }
    }
}

/// 子弹头
///
/// 这不是一个优雅的做法，因为需要两步绘才制完成。
struct Warhead: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            // 先画一个半圆
            let center = CGPoint(x: rect.height/2, y: rect.height/2)
            path.move(to: center)
            path.addArc(center: center, radius: rect.height/2, startAngle: .degrees(90), endAngle: .degrees(90+180), clockwise: false)
            // 再画一个矩形
            path.addLines([
                .init(x: center.x, y: .zero),
                .init(x: rect.width, y: .zero),
                .init(x: rect.width, y: rect.height),
                .init(x: center.x, y:  rect.height),
            ])
            path.closeSubpath()
        }
    }
}

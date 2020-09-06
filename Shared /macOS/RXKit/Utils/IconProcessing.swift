import simd
import Cocoa

/// Basic kmeans clustering for finding colors in icons
public class IconProcessing {

    // MARK: - Types -

    private typealias Pixel = SIMD3<Float>

    // MARK: - Properties -

    private static let imageSize: CGFloat = 128
    private static let minMeanPercentage: CGFloat = 0.1
    private static let maxIterations = 20

    // MARK: - Run -

    public static func run(for appFilePath: String, colorCount: Int) -> [RXColor] {

        var imagePixels = [Pixel]()
        var means = [Pixel]()
        var clusters = [[Pixel]]()

        let icon = NSWorkspace.shared.icon(forFile: appFilePath)
        var rect = NSRect(x: 0, y: 0, width: imageSize, height: imageSize)
        guard let rep = icon.representations
                .sorted(by: { $0.size.width < $1.size.height })
                .first(where: { min($0.size.width, $0.size.height) >= imageSize }),
              let image = rep.cgImage(forProposedRect: &rect, context: nil, hints: nil),
              let dataProviderData = image.dataProvider?.data else {
            return []
        }

        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(dataProviderData)
        for y in 0..<image.height {
            let offset = image.width * y
            for x in 0..<image.width {
                let index = (offset + x) * 4
                if data[index + 3] == 255 {
                    let pixel = Pixel(Float(data[index]), Float(data[index + 1]), Float(data[index + 2]))
                    imagePixels.append(pixel)
                }
            }
        }

        for _ in 0..<colorCount {
            guard let random = imagePixels.randomElement() else { fatalError() }
            means.append(random)
            clusters.append([])
        }

        func updateMeans() {
            means = clusters.map { pixels -> Pixel in
                let sum = pixels.reduce(Pixel(0, 0, 0), +)
                return sum / Float(pixels.count)
            }
        }

        func updateClusters() -> Bool {
            var newClusters = Array(repeating: [Pixel](), count: clusters.count)
            for pixel in imagePixels {
                var minMean = (index: 0, distance: Float(1000))
                for (index, mean) in means.enumerated() {
                    // https://www.compuphase.com/cmetric.htm
                    let rmean = (mean[0] + pixel[0]) / 2
                    let diff = (mean - pixel) * (mean - pixel)

                    let firstTerm = (512 + rmean) * diff[0]
                    let secondTerm = 4 * diff[1]
                    let thirdTerm = (767 - rmean) * diff[2]

                    let distance = simd.sqrt(firstTerm + secondTerm + thirdTerm)

                    if distance < minMean.distance {
                        minMean = (index: index, distance: distance)
                    }
                }
                newClusters[minMean.index].append(pixel)
            }

            if newClusters == clusters {
                return false
            } else {
                clusters = newClusters
                return true
            }
        }

        var iterations = 0
        while updateClusters() && iterations < maxIterations {
            updateMeans()
            iterations += 1
        }

        let pixelCount = CGFloat(imagePixels.count)
        let filteredMeans: [Pixel] = means
            .enumerated()
            .map { (pixel: $0.element, percent: CGFloat(clusters[$0.offset].count) / pixelCount) }
            .filter { $0.percent > minMeanPercentage }
            .sorted(by: { $0.percent > $1.percent })
            .map { $0.pixel / 255 }

        var colors = filteredMeans
            .map { NSColor(red: CGFloat($0[0]), green: CGFloat($0[1]), blue: CGFloat($0[2]), alpha: 1)}
            .map { RXColor($0) }
        if colors.count < colorCount, let topColor = colors.first {
            for _ in 0..<(colorCount - colors.count) {
                colors.append(topColor)
            }
        }
        return colors
    }

}

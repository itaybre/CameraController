//
//  NewSliderView.swift
//  CameraController
//
//  Created by Itay Brenner on 17/6/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI
import AppKit

struct Slider: View {
    @Binding var value: Float
    @Environment(\.isEnabled) var isEnabled: Bool

    @State var lastCoordinateValue: Float = 0.0
    @State private var isDragging = false
    @State private var isResetClick = false
    @State private var lastThumbClick: Date?
    let sliderRange: ClosedRange<Float>
    let step: Float
    let defaultValue: Float?
    let minTrackColor: Color = Constants.Colors.accentColor
    let maxTrackColor: Color = Constants.Colors.sliderBackground
    let disabledColor: Color = Constants.Colors.disabledSlider
    let activeThumbColor: Color = Constants.Colors.activeThumbSlider
    let disabledThumbColor: Color = Constants.Colors.disabledThumbSlider

    init(value: Binding<Float>,
         step: Float = 1,
         sliderRange: ClosedRange<Float> = 0...100,
         defaultValue: Float? = nil) {
        _value = value
        self.step = step
        self.sliderRange = sliderRange
        self.defaultValue = defaultValue
        self.lastCoordinateValue = lastCoordinateValue
    }

    var body: some View {
        GeometryReader { geoReader in
            let thumbHeight = geoReader.size.height
            let thumbWidth = geoReader.size.height
            let radius = geoReader.size.height * 0.5
            let maxValue = geoReader.size.width - thumbWidth

            let scaleFactor = Float(maxValue) / (sliderRange.upperBound - sliderRange.lowerBound)
            let lower = sliderRange.lowerBound
            let sliderVal = (self.value - lower) * scaleFactor

            let activeColor = isEnabled ? minTrackColor : disabledColor
            let thumbColor = isEnabled ? activeThumbColor : disabledThumbColor

            ZStack {
                Rectangle()
                    .foregroundColor(maxTrackColor)
                    .frame(width: geoReader.size.width, height: geoReader.size.height * 0.95)
                    .clipShape(RoundedRectangle(cornerRadius: radius))
                HStack {
                    Rectangle()
                        .foregroundColor(activeColor)
                        .frame(width: CGFloat(sliderVal) + thumbWidth/2, height: geoReader.size.height * 0.95)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: radius))
                HStack {
                    RoundedRectangle(cornerRadius: radius)
                        .foregroundColor(thumbColor)
                        .frame(width: thumbWidth, height: thumbHeight)
                        .shadow(radius: 5)
                        .offset(x: CGFloat(sliderVal))
                    Spacer()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            isResetClick = isThumbDoubleClick(at: value.startLocation.x,
                                                              thumbStart: CGFloat(sliderVal),
                                                              thumbWidth: thumbWidth)
                        }
                        // Double-clicking the thumb resets to the default instead of dragging
                        if isResetClick {
                            if let defaultValue = defaultValue {
                                self.value = defaultValue
                            }
                            return
                        }
                        let percentage = min(
                            max(
                                Float(value.location.x-thumbWidth/2) / Float(geoReader.size.width-thumbWidth),
                                0),
                            1
                        )
                        let tmpValue = percentageToValueInRange(percentage, sliderRange)
                        self.value = tmpValue - tmpValue.truncatingRemainder(dividingBy: step)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .allowsHitTesting(self.isEnabled)
        }
        .frame(height: 22)
    }

    private func isThumbDoubleClick(at location: CGFloat, thumbStart: CGFloat, thumbWidth: CGFloat) -> Bool {
        guard defaultValue != nil,
              (thumbStart...thumbStart + thumbWidth).contains(location) else {
            lastThumbClick = nil
            return false
        }

        let now = Date()
        if let lastThumbClick = lastThumbClick,
           now.timeIntervalSince(lastThumbClick) <= NSEvent.doubleClickInterval {
            self.lastThumbClick = nil
            return true
        }
        lastThumbClick = now
        return false
    }

    private func percentageToValueInRange(_ percentage: Float, _ range: ClosedRange<Float>) -> Float {
        return range.lowerBound + (range.upperBound - range.lowerBound) * percentage
    }
}

#if DEBUG
struct NewSliderView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(Float(40.0)) { value in
            VStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Regular")
                    Slider(value: value)
                        .frame(width: 320, height: 30)
                }
                Divider()
                VStack(alignment: .leading, spacing: 5) {
                    Text("Disabled")
                    Slider(value: value)
                        .frame(width: 320, height: 30)
                }
                Divider()
                VStack(alignment: .leading, spacing: 5) {
                    Text("With steps")
                    Slider(value: value, step: 10)
                        .frame(width: 320, height: 30)
                }
            }
            .frame(width: 320, height: 180)
            .padding()
        }
    }
}
#endif

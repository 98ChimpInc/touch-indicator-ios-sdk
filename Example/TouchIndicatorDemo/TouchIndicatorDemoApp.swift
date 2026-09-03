//
//  TouchIndicatorDemoApp.swift
//  TouchIndicatorDemo
//
//  Exercises the package the way a host app would: a persisted toggle drives
//  enable()/disable(), and every surface that could break under a badly
//  configured recogniser (buttons, scroll, pinch, sheet, alert) is on screen.
//

import SwiftUI
import TouchIndicator

@main
struct TouchIndicatorDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @AppStorage("showTapIndicators") private var showTapIndicators = false
    @State private var tapCount = 0
    @State private var pinchScale: CGFloat = 1
    @State private var isSheetPresented = false
    @State private var isAlertPresented = false
    @State private var isSheetAlertPresented = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Toggle("Show tap indicators", isOn: $showTapIndicators)

                    Button("Tapped \(tapCount) times") { tapCount += 1 }
                        .buttonStyle(.borderedProminent)

                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 80))
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(Color.secondary.opacity(0.15))
                        .scaleEffect(pinchScale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { pinchScale = $0 }
                                .onEnded { _ in pinchScale = 1 }
                        )
                        .accessibilityLabel("Pinch target")

                    Button("Present sheet") { isSheetPresented = true }
                    Button("Present alert") { isAlertPresented = true }

                    ForEach(0 ..< 40) { row in
                        Text("Scroll row \(row)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("TouchIndicator")
            .sheet(isPresented: $isSheetPresented) {
                VStack(spacing: 24) {
                    Text("Inside a sheet").font(.title)
                    Button("Tapped \(tapCount) times") { tapCount += 1 }
                        .buttonStyle(.borderedProminent)
                    Button("Present alert") { isSheetAlertPresented = true }
                }
                .alert("Alert over sheet", isPresented: $isSheetAlertPresented) {
                    Button("OK") {}
                }
            }
            .alert("Inside an alert", isPresented: $isAlertPresented) {
                Button("OK") {}
            }
        }
        .navigationViewStyle(.stack)
        .onAppear(perform: applyIndicatorSetting)
        .onChange(of: showTapIndicators) { _ in applyIndicatorSetting() }
    }

    private func applyIndicatorSetting() {
        if showTapIndicators {
            TouchIndicator.enable()
        } else {
            TouchIndicator.disable()
        }
    }
}

import SwiftUI

struct CheckBoxButton: View {
    let isChecked: Bool
    let isDimmed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isChecked ? "checkmark.square" : "square")
                .font(.system(size: 24, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isChecked ? HWTheme.freshGreen : (isDimmed ? HWTheme.tertiaryText : HWTheme.softBlueGray))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isChecked ? "已勾选" : "未勾选")
    }
}

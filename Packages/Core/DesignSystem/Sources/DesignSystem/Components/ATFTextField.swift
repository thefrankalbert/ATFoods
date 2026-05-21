// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFTextField.swift
import SwiftUI

public struct ATFTextField: View {
    let label: String?
    @Binding var text: String
    let placeholder: String
    let isMultiline: Bool
    let suffix: String?
    let error: String?
    let hint: String?
    let isSecure: Bool
    let rightIcon: ATFIcon?

    @FocusState private var isFocused: Bool

    public init(
        _ label: String? = nil,
        text: Binding<String>,
        placeholder: String = "",
        multiline: Bool = false,
        suffix: String? = nil,
        error: String? = nil,
        hint: String? = nil,
        secure: Bool = false,
        rightIcon: ATFIcon? = nil
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.isMultiline = multiline
        self.suffix = suffix
        self.error = error
        self.hint = hint
        self.isSecure = secure
        self.rightIcon = rightIcon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label {
                Text(label)
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfText2)
                    .padding(.leading, 4)
            }

            ZStack(alignment: .trailing) {
                Group {
                    if isMultiline {
                        TextEditor(text: $text)
                            .frame(minHeight: 96)
                            .padding(14)
                            .scrollContentBackground(.hidden)
                    } else if isSecure {
                        SecureField(placeholder, text: $text)
                            .padding(.horizontal, 14)
                            .padding(.trailing, suffix != nil ? 56 : 14)
                    } else {
                        TextField(placeholder, text: $text)
                            .padding(.horizontal, 14)
                            .padding(.trailing, suffix != nil ? 56 : (rightIcon != nil ? 44 : 14))
                    }
                }
                .frame(height: isMultiline ? nil : 52)
                .font(.atfBody)
                .foregroundStyle(Color.atfText1)
                .background(Color.atfSurface)
                .clipShape(RoundedRectangle(cornerRadius: ATFRadius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: ATFRadius.input)
                        .strokeBorder(
                            error != nil ? Color.atfDanger :
                            isFocused ? Color.atfAccent :
                            Color.atfBorder,
                            lineWidth: 1
                        )
                )
                .focused($isFocused)

                if let suffix {
                    Text(suffix)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.atfText3)
                        .padding(.trailing, 14)
                }
                if let rightIcon {
                    ATFIconView(rightIcon, size: 18, color: .atfText3)
                        .padding(.trailing, 10)
                }
            }

            if let error {
                HStack(spacing: 4) {
                    ATFIconView(.alert, size: 12, color: .atfDanger)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.atfDanger)
                }
                .padding(.leading, 4)
            } else if let hint {
                Text(hint)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.atfText3)
                    .padding(.leading, 4)
            }
        }
    }
}

#Preview("ATFTextField") {
    @Previewable @State var email = "mariam@chezflora.cm"
    @Previewable @State var pass = ""
    @Previewable @State var price = "3800"
    @Previewable @State var desc = ""

    VStack(spacing: 16) {
        ATFTextField("Adresse e-mail", text: $email, placeholder: "mariam@chezflora.cm")
        ATFTextField("Mot de passe", text: $pass, placeholder: "••••••••",
                     error: "Identifiants invalides", secure: true)
        ATFTextField("Prix *", text: $price, placeholder: "3 800", suffix: "FCFA")
        ATFTextField("Description", text: $desc,
                     placeholder: "Décris le plat…", multiline: true,
                     hint: "\(desc.count)/500")
    }
    .padding()
}

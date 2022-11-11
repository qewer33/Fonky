import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2 as Layouts
import QtQuick.Dialogs 1.3 as Dialogs

import org.kde.kirigami 2.15 as Kirigami

import "../lib"

Kirigami.ScrollablePage {
    id: page
    title: "Font Information"

    onCardIndexChanged: updateData();

    property var card
    property var cardIndex
    property var fontData
    property var fontInstalled
    property int fontVariantCount
    property int fontSize: 32

    function updateData() {
        card = fontsPage.getCardAtIndex(cardIndex);
        fontData = card.fontData;
        fontInstalled = card.installed;
        fontVariantCount = fontData.variants.length;
        title = fontData.family;
    }

    function getDevImportLink() {
        let variants = [];

        for (let i = 0; i < fontData.variants.length; i++) {
            let v = fontData.variants[i];
            let n = v.includes("italic") ? "1" : "0";
            let ve = v.replace("italic", "") == "regular" ? "400" : v;
            
            variants.push(n + ":" + ve);
        }

        return `https://fonts.googleapis.com/css2?family=${fontData.family.replace(" ", "+")}:ital,wght@${variants.join(";")}&display=swap`
    }

    actions {
        contextualActions: [
            Kirigami.Action {
                text: "Save"
                iconName: "document-save"

                onTriggered: {
                    saveDialog.visible = true;
                }
            },
            Kirigami.Action {
                text: !fontInstalled ? "Install" : "Remove"
                iconName: !fontInstalled ? "install" : "delete"
                enabled: !fontsPage.getCardAtIndex(cardIndex).installing

                onTriggered: fontsPage.getCardAtIndex(cardIndex).installRemoveFont();
            }
        ]
    }

    // Save folder selection dialog
    Dialogs.FileDialog {
        id: saveDialog
        title: "Please choose a folder"
        folder: shortcuts.home
        selectFolder: true
        onAccepted: {
            taskQueue.save_font_family(cardIndex, fontData.family, Object.keys(fontData.files).join(";"), Object.values(fontData.files).join(";"), saveDialog.folder.toString().replace("file://", ""));
        }
    }

    // Developer information overlay sheet
    Kirigami.OverlaySheet {
        id: developerInfoSheet
        title: "Developer Information"
        parent: applicationWindow().overlay

        Layouts.ColumnLayout {
            Layouts.Layout.preferredWidth: 720

            Layouts.RowLayout {
                Controls.Label {
                    text: "HTML link"
                    Layouts.Layout.fillWidth: true
                }

                Controls.Button {
                    text: "Copy to Clipboard"
                    icon.name: "edit-copy"
                    Layouts.Layout.alignment: Qt.AlignRight

                    onClicked: {
                        htmlLinkText.selectAll();
                        htmlLinkText.copy();
                    }
                }
            }

            Controls.TextArea {
                id: htmlLinkText
                readOnly: true
                Layouts.Layout.fillWidth: true
                textFormat: TextEdit.MarkdownText
                text: {
                    return `
\`\`\`
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="${getDevImportLink()}" rel= "stylesheet">
\`\`\``;
                }
            }
        
            Layouts.RowLayout {
                Controls.Label {
                    text: "CSS @import"
                    Layouts.Layout.fillWidth: true
                }

                Controls.Button {
                    text: "Copy to Clipboard"
                    icon.name: "edit-copy"
                    Layouts.Layout.alignment: Qt.AlignRight

                    onClicked: {
                        cssImportText.selectAll();
                        cssImportText.copy();
                    }
                }
            }

            Controls.TextArea {
                id: cssImportText
                readOnly: true
                Layouts.Layout.fillWidth: true
                textFormat: TextEdit.MarkdownText
                text: "```@import url('" + getDevImportLink() + "')```"
            }

            Layouts.RowLayout {
                Controls.Label {
                    text: "CSS rule to use family"
                    Layouts.Layout.fillWidth: true
                }

                Controls.Button {
                    text: "Copy to Clipboard"
                    icon.name: "edit-copy"
                    Layouts.Layout.alignment: Qt.AlignRight

                    onClicked: {
                        cssRuleText.selectAll();
                        cssRuleText.copy();
                    }
                }
            }

            Controls.TextArea {
                id: cssRuleText
                readOnly: true
                Layouts.Layout.fillWidth: true
                textFormat: TextEdit.MarkdownText
                text: "```font-family: '" + fontData.family + "', serif;```"
            }
        }
    }

    Controls.BusyIndicator {
        anchors.centerIn: parent
        visible: !fontsPage.getCardAtIndex(cardIndex).fontLoaded
        running: true
    }

    Layouts.ColumnLayout {
        spacing: 50
        visible: fontsPage.getCardAtIndex(cardIndex).fontLoaded

        Layouts.RowLayout {
            id: header
            Layouts.Layout.alignment: Qt.AlignHCenter

            Controls.Label {
                text: fontData.family
                font.pointSize: 32
                font.family: webFontRegular.name
            }
        }

        Controls.Label {
            text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
            Layouts.Layout.fillWidth: true
            Layouts.Layout.maximumWidth: 1280
            Layouts.Layout.alignment: Qt.AlignHCenter
            wrapMode: Text.WordWrap
            font.family: webFontRegular.name
            font.pointSize: 18
        }

        Layouts.ColumnLayout {
            spacing: 15
            Layouts.Layout.maximumWidth: 1280
            Layouts.Layout.alignment: Qt.AlignHCenter

            Layouts.RowLayout {
                Controls.TextField {
                    text: previewText
                    Layouts.Layout.fillWidth: true

                    onTextChanged: previewText = text
                }

                Controls.SpinBox {
                    id: previewSizeSpinBox
                    Layouts.Layout.minimumWidth: 60
                    from: 5
                    to: 60
                    stepSize: 1
                    value: fontSize

                    onValueChanged: fontSize = value
                }
            }

            Item {
                implicitHeight: previewLayout.height
                Layouts.Layout.fillWidth: true
                clip: true

                Layouts.ColumnLayout {
                    id: previewLayout

                    Repeater {
                        id: repeater
                        model: fontVariantCount

                        Layouts.ColumnLayout {
                            Controls.Label {
                                text: fontData.variants[index]
                                font.pointSize: 10
                            }

                            Controls.Label {
                                text: previewText
                                font.pointSize: fontSize
                                font.family: loader.name
                                font.italic: fontData.variants[index].includes("italic")
                                font.weight: {
                                    switch (true) {
                                        case fontData.variants[index].includes("100"):
                                            return Font.Thin
                                            break;
                                        case fontData.variants[index].includes("200"):
                                            return Font.ExtraLight
                                            break;
                                        case fontData.variants[index].includes("300"):
                                            return Font.Light
                                            break;
                                        case fontData.variants[index].includes("regular"):
                                            return Font.Normal
                                            break;
                                        case fontData.variants[index].includes("500"):
                                            return Font.Medium
                                            break;
                                        case fontData.variants[index].includes("600"):
                                            return Font.DemiBold
                                            break;
                                        case fontData.variants[index].includes("700"):
                                            return Font.Bold
                                            break;
                                        case fontData.variants[index].includes("800"):
                                            return Font.ExtraBold
                                            break;
                                        case fontData.variants[index].includes("900"):
                                            return Font.Black
                                            break;
                                        default:
                                            return Font.Normal
                                    }
                                }

                                FontLoader {
                                    id: loader
                                    source: fontData.files[fontData.variants[index]]
                                }
                            }
                        }
                    }
                }
            }

            Kirigami.FormLayout {
                Controls.Label {
                    Kirigami.FormData.label: "Family Name"
                    text: fontData.family
                    color: Kirigami.Theme.disabledTextColor
                }

                Controls.Label {
                    Kirigami.FormData.label: "Variants"
                    text: fontData.variants.join("\n")
                    color: Kirigami.Theme.disabledTextColor
                }

                Controls.Label {
                    Kirigami.FormData.label: "Subsets"
                    text: fontData.subsets.join("\n")
                    color: Kirigami.Theme.disabledTextColor
                }

                Controls.Label {
                    Kirigami.FormData.label: "Category"
                    text: fontData.category
                    color: Kirigami.Theme.disabledTextColor
                }

                Controls.Label {
                    Kirigami.FormData.label: "Version"
                    text: fontData.version
                    color: Kirigami.Theme.disabledTextColor
                }

                Controls.Label {
                    Kirigami.FormData.label: "Last Updated"
                    text: fontData.lastModified
                    color: Kirigami.Theme.disabledTextColor
                }

                Controls.Button {
                    text: "Open on Google Fonts"
                    icon.name: "link"

                    onClicked: Qt.openUrlExternally(`https://fonts.google.com/specimen/${fontData.family.replace(" ", "+")}`)
                }

                Controls.Button {
                    text: "Developer Information"
                    icon.name: "format-text-code"

                    onClicked: developerInfoSheet.open()
                }
            }
        }

        FontLoader {
            id: webFontRegular
            source: fontData.files.regular
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2 as Layouts

import org.kde.kirigami 2.13 as Kirigami

Kirigami.AbstractCard {
    id: card
    showClickFeedback: true
    
    onClicked: {
        fontInfoPage.cardIndex = index;
        pageStack.push(fontInfoPage);
    }

    property var self: card

    property var index
    property var fontData
    property bool installed: false
    property bool installing: false
    property var fontLoaded: false

    function installRemoveFont() {
        if (!installed) {
            installing = true;
            taskQueue.install_font_family(index, fontData.family, Object.keys(fontData.files).join(";"), Object.values(fontData.files).join(";"));
        } else {
            taskQueue.remove_font_family(index, fontData.family);
        }
    }

    header: Layouts.RowLayout {
        Kirigami.Heading {
            text: " " + fontData.family
            level: 1
            elide: Text.ElideRight
            Layouts.Layout.preferredWidth: parent.width - installButton.width - Kirigami.Units.smallSpacing

            Controls.ToolTip.text: fontData.family
            Controls.ToolTip.visible: ma.containsMouse
            Controls.ToolTip.delay: 250
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        Controls.Button {
            id: installButton
            Layouts.Layout.alignment: Qt.AlignRight
            text: !installed ? "Install" : "Remove"
            icon.name: !installed ? "install" : "delete"
            enabled: !installing

            onClicked: installRemoveFont()
        }
    }

    // Content
    contentItem: Item {
        clip: true

        // Font preview
        Controls.Label {
            wrapMode: Text.WordWrap
            width: parent.width
            height: parent.height
            text: webFont.status === FontLoader.Ready ? previewText : ""
            font.family: webFont.name
            font.pointSize: previewFontSize
        }

        // Loading icon
        Controls.BusyIndicator {
            anchors.centerIn: parent
            visible: webFont.status !== FontLoader.Ready
            running: true
        }
    }

    // Footer
    footer: Layouts.RowLayout {
        // Variant count
        Controls.Label {
            text: if (fontData.variants.length === 1) {
                `${fontData.variants.length} variant`
            } else {
                `${fontData.variants.length} variants`
            }
        }

        // Installed indicator
        Layouts.RowLayout {
            Layouts.Layout.alignment: Qt.AlignRight

            Kirigami.Icon {
                implicitWidth: 20
                implicitHeight: 20
                source: "checkmark"
                color: Kirigami.Theme.positiveTextColor
                visible: installed
            }

            Controls.Label {
                text: "Installed"
                horizontalAlignment: Text.AlignRight
                color: Kirigami.Theme.positiveTextColor
                visible: installed
            }
        }
    }

    FontLoader {
        id: webFont
        source: fontData.files.regular
        onStatusChanged: fontLoaded = webFont.status === FontLoader.Ready;
    }

    Component.onCompleted: {
        installed = systemFontsList.includes(fontData.family);
    }
}

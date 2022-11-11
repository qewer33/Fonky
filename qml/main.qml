import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2 as Layouts

import org.kde.kirigami 2.15 as Kirigami

import SystemFontsProvider 1.0
import WebFontsProvider 1.0
import TaskQueue 1.0

import "lib"
import "pages"

Kirigami.ApplicationWindow {
    id: root
    title: i18nc("@title:window", "Fonky")

    property var webFontsList
    property var systemFontsList
    property string previewText: "The quick brown fox jumps over the lazy dog."
    property int previewFontSize: 24

    function getProviderData() {
        webFontsList = JSON.parse(WebFontsProvider.get_json()).items;
        systemFontsList = SystemFontsProvider.get_families();
    }

    TaskQueue {
        id: taskQueue

        onTasksChanged: {
            fontsPage.onTaskQueueChanged();
        }
    }

    // Pages
    FontInfoPage { id: fontInfoPage }
    FontsPage { id: fontsPage }
    
    pageStack.initialPage: fontsPage
    pageStack.defaultColumnWidth: root.width
    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.ToolBar
    pageStack.globalToolBar.showNavigationButtons: pageStack.currentIndex > 0 ? Kirigami.ApplicationHeaderStyle.ShowBackButton : 0

    // Get font lists from providers
    Component.onCompleted: getProviderData();
}

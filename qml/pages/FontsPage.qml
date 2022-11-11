import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2 as Layouts

import org.kde.kirigami 2.15 as Kirigami

import "../lib"

Kirigami.ScrollablePage {
    id: page
    title: "Browse Fonts"
    horizontalScrollBarPolicy: ScrollBar.AlwaysOff

    property string installedFilter: "all"
    property var activeCategories: ["serif", "sans-serif", "display", "handwriting", "monospace"]

    function filterFontsList(installFilter, filterCategories, searchString) {
        console.log(installFilter);

        let newList = [];

        webFontsList.forEach((fontData) => {
            let filter = filterFont(fontData, installFilter, filterCategories, searchString);
            if (filter) newList.push(fontData);
        });

        return newList;
    }

    function filterFont(fontData, installFilter, filterCategories, searchString) {
        let installed = systemFontsList.includes(fontData.family);
        switch (installFilter) {
            case "installed":
                if (!installed) return false;
                break;
            case "not_installed":
                if (installed) return false;
                break;
        }

        if (!filterCategories.includes(fontData.category)) return false;

        if (!fontData.family.toUpperCase().includes(searchString.toUpperCase())) return false;
        
        return true;
    }

    function onTaskQueueChanged() {
        let task = taskQueue.tasks[taskQueue.tasks.length-1];
        let card = view.itemAtIndex(task.card_index).children[0];

        let s = task.task === "install" ? "installed" : task.task + "d";
        if (task.status === "done") {
            if (task.task !== "save") card.installed = !card.installed;
            showPassiveNotification(`${task.name} ${s}`);
        } else if (task.status === "failed") {
            showPassiveNotification(`${task.name} couldn't be ${s}`);
        }

        if (task.status !== "pending") card.installing = false;
        fontInfoPage.updateData();
    }

    function updateInstalledFilter(filter) {
        root.getProviderData();
        installedFilter = filter;
        refreshView();
    }

    function updateCategories(category) {
        if (activeCategories.includes(category)) activeCategories.splice(activeCategories.indexOf(category), 1);
        else activeCategories.push(category);
        refreshView();
    }

    function refreshView() {
        view.model = filterFontsList(installedFilter, activeCategories, searchField.text);
    }

    function getCardAtIndex(index) {
        return view.itemAtIndex(index).children[0];
    }

    // Search field toolbar
    header: Controls.ToolBar {
        id: searchFieldToolbar
        visible: false

        Layouts.RowLayout {
            anchors.fill: parent

            Kirigami.SearchField {
                id: searchField
                Layouts.Layout.alignment: Qt.AlignHCenter
                Layouts.Layout.fillWidth: true
                Layouts.Layout.maximumWidth: Kirigami.Units.gridUnit*30

                onTextChanged: refreshView()
            }
        }
    }

    actions {
        contextualActions: [
            Kirigami.Action {
                text:"Tasks"
                iconName: "install"

                onTriggered: tasksSheet.open()
        },
            Kirigami.Action {
                text:"Preview Text"
                iconName: "font"

                onTriggered: previewTextSheet.open()
            },
            Kirigami.Action {
                text:"Filter"
                iconName: "view-filter"

                Controls.ActionGroup { id: filterGroup }

                Kirigami.Action {
                    text: "All"
                    checkable: true
                    checked: true
                    Controls.ActionGroup.group: filterGroup

                    onTriggered: updateInstalledFilter("all");
                }
                Kirigami.Action {
                    text: "Installed"
                    checkable: true
                    Controls.ActionGroup.group: filterGroup

                    onTriggered: updateInstalledFilter("installed");
                }
                Kirigami.Action {
                    text: "Not Installed"
                    checkable: true
                    Controls.ActionGroup.group: filterGroup

                    onTriggered: updateInstalledFilter("not_installed");
                }

                Kirigami.Action { separator: true }

                Kirigami.Action {
                    text: "Serif"
                    checkable: true
                    checked: true

                    onCheckedChanged: updateCategories("serif");
                }
                Kirigami.Action {
                    text: "Sans Serif"
                    checkable: true
                    checked: true

                    onCheckedChanged: updateCategories("sans-serif");
                }
                Kirigami.Action {
                    text: "Display"
                    checkable: true
                    checked: true

                    onCheckedChanged: updateCategories("display");
                }
                Kirigami.Action {
                    text: "Handwriting"
                    checkable: true
                    checked: true

                    onCheckedChanged: updateCategories("handwriting");
                }
                Kirigami.Action {
                    text: "Monospace"
                    checkable: true
                    checked: true

                    onCheckedChanged: updateCategories("monospace");
                }
            },
            Kirigami.Action {
                text:"Search"
                checkable: true
                iconName: "search"

                onCheckedChanged: {
                    searchFieldToolbar.visible = checked
                    searchField.forceActiveFocus()
                }
            },
            Kirigami.Action {
                text:"About Fonky"
                iconName: "documentinfo"
                displayHint: Kirigami.Action.DisplayHint.AlwaysHide

                onTriggered: pageStack.push("qrc:/pages/AboutPage.qml")
            }
        ]
    }

    // Task list overlay sheet
    Kirigami.OverlaySheet {
        id: tasksSheet
        title: "Task Queue"
        parent: applicationWindow().overlay

        Controls.ScrollView {
            Layouts.Layout.preferredWidth: 640

            ListView {
                id: tasksListView
                model: taskQueue.tasks
                verticalLayoutDirection: ListView.BottomToTop

                // Task delegate
                delegate: Kirigami.BasicListItem {
                    label: `${modelData.task.charAt(0).toUpperCase() + modelData.task.slice(1)}: ${modelData.name}`
                    subtitle: modelData.status.charAt(0).toUpperCase() + modelData.status.slice(1); // Capitalize first letter
                    subtitleItem.color: modelData.status === "done" ? Kirigami.Theme.positiveTextColor :  modelData.status === "pending" ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.negativeTextColor
                    icon: {
                        switch (modelData.task) {
                            case "install":
                                return "install";
                            case "remove":
                                return "delete";
                            case "save":
                                return "document-save";
                        }
                    }
                    highlighted: false
                    activeBackgroundColor: Kirigami.Theme.backgroundColor
                    hoverEnabled: false
                    separatorVisible: false
                }
            }
        }
    }

    // Preview options overlay sheet
    Kirigami.OverlaySheet {
        id: previewTextSheet
        title: "Preview Options"
        parent: applicationWindow().overlay

        Kirigami.FormLayout {
            Controls.TextField {
                id: previewTextArea
                implicitWidth: 500
                text: previewText
                Kirigami.FormData.label: "Text"
            }

            Controls.SpinBox {
                id: previewSizeSpinBox
                from: 5
                to: 60
                stepSize: 1
                value: previewFontSize
                Kirigami.FormData.label: "Font Size"
            }

            Controls.Button {
                id: previewTextApplyButton
                Layouts.Layout.alignment: Qt.AlignRight
                text: "Apply"
                icon.name: "checkmark"

                onClicked: {
                    previewTextSheet.close();
                    previewText = previewTextArea.text;
                    previewFontSize = previewSizeSpinBox.value;
                }
            }
        }
    }

    // Somewhat hacky custom responsive grid view sizing
    // because Kirigami.CardsGridView is incredibly buggy
    function calculateCellSize() {
        let div = Math.round(page.width/350);
        return page.width/div - 32/div
    }

    GridView {
        id: view
        anchors.fill: parent
        anchors.topMargin: 15
        cellWidth: calculateCellSize()
        cellHeight: page.width > 525 ? calculateCellSize() : calculateCellSize()/1.5

        model: filterFontsList(installedFilter, activeCategories, searchField.text)

        // Margin hack
        delegate: Item {
            width: view.cellWidth
            height: view.cellHeight

            FontCard {
                id: card
                index: model.index
                anchors.fill: parent
                anchors {
                    leftMargin: 10
                    topMargin: 10
                    bottomMargin: 0
                    rightMargin: 0
                }
                fontData: modelData
            }
        }
    }
}

/*
 * Copyright (c) 2014-2026 Meltytech, LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Shotcut.Controls as Shotcut
import org.shotcut.qml as Shotcut

Rectangle {
    id: root

    property int selectedIndex: Shotcut.Filter.NoCurrentFilter
    readonly property bool simpleTextMode: textWorkspace && filterConfig.item ? filterConfig.item.cutItSimpleEditor === true : false
    onSimpleTextModeChanged: _setLayout()
    readonly property bool textWorkspace: cutItWorkspaceMode === 3
    readonly property bool textHome: textWorkspace && !(metadata && (metadata.objectName === "dynamicText" || metadata.objectName === "richText"))
    onTextWorkspaceChanged: filterMenu.close()
    readonly property bool colorWorkspace: cutItWorkspaceMode === 1
    property bool showColorHome: true
    readonly property bool colorHome: colorWorkspace && showColorHome
    onColorWorkspaceChanged: { showColorHome = true; filterMenu.close(); }


    signal currentFilterRequested(int attachedIndex)
    signal copyFilterRequested
    signal addonFilterMetadataHelpRequested(string service)

    function clearCurrentFilter() {
        if (filterConfig.item) {
            filterConfig.item.width = 1;
            filterConfig.item.height = 1;
        }
        filterConfig.source = "";
    }

    function setCurrentFilter(index) {
        clearCurrentFilter();
        attachedFilters.setCurrentFilter(index);
        selectedIndex = index;
        filterConfig.source = metadata ? metadata.qmlFilePath : "";
    }

    function openFilterMenu() {
        if (attachedfiltersmodel.isProducerSelected)
            filterMenu.open();
    }

    function _setLayout() {
        if (simpleTextMode)
            root.state = "simpleText";
        else if (height > width - attachedFilters.minimumWidth)
            root.state = "portrait";
        else
            root.state = "landscape";
    }

    color: activePalette.window
    width: 400
    onWidthChanged: _setLayout()
    onHeightChanged: _setLayout()
    states: [
        State {
            name: "simpleText"
            AnchorChanges {
                target: filterConfigScrollView
                anchors { top: root.top; bottom: root.bottom; left: root.left; right: root.right }
            }
        },
        State {
            name: "landscape"

            AnchorChanges {
                target: filterConfigScrollView

                anchors {
                    top: titleBackground.bottom
                    bottom: root.bottom
                    left: attachedContainer.right
                    right: root.right
                }
            }

            PropertyChanges {
                target: attachedContainer
                width: attachedFilters.minimumWidth
                height: root.height - titleBackground.height - titleBackground.anchors.topMargin - titleBackground.anchors.bottomMargin - attachedContainer.anchors.topMargin - attachedContainer.anchors.bottomMargin
            }
        },
        State {
            name: "portrait"

            AnchorChanges {
                target: filterConfigScrollView

                anchors {
                    top: attachedContainer.bottom
                    bottom: root.bottom
                    left: root.left
                    right: root.right
                }
            }

            PropertyChanges {
                target: attachedContainer
                width: titleBackground.width
                height: moreControls.checked ? 210 : 125
            }
        }
    ]

    SystemPalette {
        id: activePalette
    }

    Rectangle {
        id: titleBackground

        color: activePalette.highlight
        visible: !root.colorHome && !root.textHome && !root.simpleTextMode && attachedfiltersmodel.producerTitle != ""
        radius: 12

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: titleLabel.bottom
            topMargin: 10
            leftMargin: 10
            rightMargin: 10
        }
    }

    Label {
        id: titleLabel
        visible: !root.colorHome && !root.textHome && !root.simpleTextMode

        text: attachedfiltersmodel.producerTitle
        elide: Text.ElideLeft
        color: activePalette.highlightedText
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        topPadding: 4
        bottomPadding: 3

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 10
            leftMargin: 10
            rightMargin: 10
        }
    }

    GridLayout {
        id: attachedContainer
        visible: !root.colorHome && !root.textHome && !root.simpleTextMode

        columns: 3

        anchors {
            top: titleBackground.bottom
            left: parent.left
            leftMargin: 10
            rightMargin: 10
            topMargin: 6
            bottomMargin: 4
        }

        AttachedFilters {
            id: attachedFilters

            property int minimumWidth: 250

            Layout.columnSpan: parent.columns
            Layout.fillWidth: true
            Layout.fillHeight: true
            onFilterClicked: index => {
                root.currentFilterRequested(index);
            }

            Label {
                anchors.centerIn: parent
                text: qsTr("Select a clip")
                color: activePalette.text
                visible: !attachedfiltersmodel.isProducerSelected
            }
        }

        Shotcut.Button {
            id: addButton

            text: root.colorWorkspace ? qsTr("Adjustments") : qsTr("Add effect")
            icon.name: 'list-add'
            icon.source: 'qrc:///icons/oxygen/32x32/actions/list-add.png'
            enabled: attachedfiltersmodel.isProducerSelected
            opacity: enabled ? 1 : 0.5
            onClicked: {
                if (root.colorWorkspace) root.showColorHome = true;
                else if (application.confirmOutputFilter()) filterMenu.open();
            }

            Shotcut.HoverTip {
                text: qsTr('Add an effect to the selected clip') + application.actionFirstShortcut('filtersAddFilterAction')
            }
        }

        Shotcut.Button {
            id: removeButton

            text: qsTr("Remove")
            icon.name: 'list-remove'
            icon.source: 'qrc:///icons/oxygen/32x32/actions/list-remove.png'
            enabled: selectedIndex > Shotcut.Filter.NoCurrentFilter
            opacity: enabled ? 1 : 0.5
            onClicked: {
                attachedfiltersmodel.remove(selectedIndex);
            }

            Shotcut.HoverTip {
                text: qsTr('Remove selected filter') + application.actionFirstShortcut('filtersRemoveFilterAction')
            }
        }

        Button {
            id: moreControls
            text: checked ? qsTr("Less") : qsTr("More")
            checkable: true
        }

        // Advanced controls remain available when requested.
        Shotcut.Button {
            visible: moreControls.checked
            enabled: false
            implicitWidth: 1
            implicitHeight: 20
        }

        Shotcut.Button {
            id: copyButton
            visible: moreControls.checked

            implicitWidth: height
            icon.name: 'edit-copy'
            icon.source: 'qrc:///icons/oxygen/32x32/actions/edit-copy.png'
            enabled: selectedIndex > Shotcut.Filter.NoCurrentFilter
            opacity: enabled ? 1 : 0.5
            onClicked: root.copyFilterRequested()

            Shotcut.HoverTip {
                text: qsTr('Copy filters') + application.actionFirstShortcut('filtersCopyFiltersAction')
            }
        }

        Shotcut.Button {
            id: pasteButton
            visible: moreControls.checked

            implicitWidth: height
            enabled: attachedfiltersmodel.isProducerSelected
            opacity: enabled ? 1 : 0.5
            icon.name: 'edit-paste'
            icon.source: 'qrc:///icons/oxygen/32x32/actions/edit-paste.png'
            onClicked: attachedfiltersmodel.pasteFilters()

            Shotcut.HoverTip {
                text: qsTr('Paste filters') + application.actionFirstShortcut('filtersPasteFiltersAction')
            }
        }

        Shotcut.Button {
            id: filterSetButton
            visible: moreControls.checked

            implicitWidth: height
            icon.name: 'server-database'
            icon.source: 'qrc:///icons/oxygen/32x32/places/server-database.png'
            enabled: selectedIndex > Shotcut.Filter.NoCurrentFilter
            opacity: enabled ? 1 : 0.5
            onClicked: copyFiltersDialog.show()

            Shotcut.HoverTip {
                text: qsTr('Save a filter set')
            }
        }

        // Advanced controls remain available when requested.
        Shotcut.Button {
            visible: moreControls.checked
            enabled: false
            implicitWidth: 1
            implicitHeight: 20
        }

        Shotcut.Button {
            id: moveUpButton
            visible: moreControls.checked

            implicitWidth: height
            enabled: attachedFilters.selectedCanMoveUp
                     && !attachedfiltersmodel.isTrackVolumeFilter(selectedIndex)
            opacity: enabled ? 1 : 0.5
            icon.name: 'lift'
            icon.source: 'qrc:///icons/oxygen/32x32/actions/lift.png'
            onClicked: {
                const newIndex = selectedIndex - 1;
                attachedfiltersmodel.move(selectedIndex, newIndex);
                selectedIndex = newIndex;
                root.currentFilterRequested(newIndex);
            }

            Shotcut.HoverTip {
                text: qsTr('Move filter up')
            }
        }

        Shotcut.Button {
            id: moveDownButton
            visible: moreControls.checked

            implicitWidth: height
            enabled: attachedFilters.selectedCanMoveDown
                     && !attachedfiltersmodel.isTrackVolumeFilter(selectedIndex)
            opacity: enabled ? 1 : 0.5
            icon.name: 'overwrite'
            icon.source: 'qrc:///icons/oxygen/32x32/actions/overwrite.png'
            onClicked: {
                const newIndex = selectedIndex + 1;
                attachedfiltersmodel.move(selectedIndex, newIndex);
                selectedIndex = newIndex;
                root.currentFilterRequested(newIndex);
            }

            Shotcut.HoverTip {
                text: qsTr('Move filter down')
            }
        }

        // Advanced controls remain available when requested.
        Shotcut.Button {
            visible: moreControls.checked
            enabled: false
            implicitWidth: 1
            implicitHeight: 20
        }

        Shotcut.Button {
            id: deselectButton
            visible: moreControls.checked

            implicitWidth: height
            icon.name: 'window-close'
            icon.source: 'qrc:///icons/oxygen/32x32/actions/window-close.png'
            enabled: selectedIndex > Shotcut.Filter.NoCurrentFilter
            opacity: enabled ? 1 : 0.5
            onClicked: {
                clearCurrentFilter();
                attachedFilters.setCurrentFilter(Shotcut.Filter.DeselectCurrentFilter);
                selectedIndex = Shotcut.Filter.NoCurrentFilter;
                filter.deselect();
            }

            Shotcut.HoverTip {
                text: qsTr('Deselect the filter')
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    Flickable {
        // scroll bar
        id: filterConfigScrollView
        visible: !root.textHome && !root.colorHome

        function expandWidth() {
            if (filterConfig.item)
                filterConfig.item.width = Math.max(filterConfig.minimumWidth, filterConfigScrollView.width - 20);
        }

        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        anchors.bottomMargin: 16
        anchors.rightMargin: 16
        contentWidth: filterConfig.item ? filterConfig.item.width + 16 : 0
        contentHeight: filterConfig.item ? filterConfig.item.height + 16 : 0
        onWidthChanged: expandWidth()

        Loader {
            id: filterConfig

            property int minimumWidth: 0

            enabled: !filterMenu.visible
            onLoaded: {
                minimumWidth = item.width;
                filterConfigScrollView.expandWidth();
            }
        }

        ScrollBar.horizontal: Shotcut.HorizontalScrollBar {
            policy: ScrollBar.AlwaysOn
            visible: filterConfigScrollView.contentWidth > filterConfigScrollView.width
            parent: filterConfigScrollView.parent
            anchors.top: filterConfigScrollView.bottom
            anchors.left: filterConfigScrollView.left
            anchors.right: filterConfigScrollView.right
        }

        ScrollBar.vertical: Shotcut.VerticalScrollBar {
            policy: ScrollBar.AlwaysOn
            visible: filterConfigScrollView.contentHeight > filterConfigScrollView.height
            parent: filterConfigScrollView.parent
            anchors.top: filterConfigScrollView.top
            anchors.left: filterConfigScrollView.right
            anchors.bottom: filterConfigScrollView.bottom
        }
    }

    FilterMenu {
        id: filterMenu

        z: 1
        onFilterSelected: index => {
            attachedfiltersmodel.add(metadatamodel.get(index));
        }

        anchors {
            top: titleBackground.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: attachedContainer.anchors.topMargin
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.textHome
        color: activePalette.window
        ColumnLayout {
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
            spacing: 16
            Label { text: qsTr("Text"); font.pixelSize: 22; font.bold: true }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Add a text layer, then type your words and choose a style. Select a text clip in the timeline to edit it again.")
            }
            Button {
                text: qsTr("+ Add text layer")
                Layout.fillWidth: true
                onClicked: application.triggerAction("cutItAddText")
            }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Text stays on its own layer so you can move it, trim it, or delete it like a clip.")
                opacity: 0.65
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.colorHome
        color: activePalette.window
        ScrollView {
            anchors.fill: parent
            anchors.margins: 16
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: 12
                Label { text: qsTr("Color"); font.pixelSize: 22; font.bold: true }
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: attachedfiltersmodel.isProducerSelected
                          ? qsTr("Choose an adjustment. Changes apply to the selected clip.")
                          : qsTr("Select a timeline clip to adjust its color.")
                }
                Repeater {
                    model: [
                        {title: qsTr("Brightness"), detail: qsTr("Make the picture lighter or darker"), folder: "brightness"},
                        {title: qsTr("Contrast"), detail: qsTr("Adjust the difference between light and dark"), folder: "contrast"},
                        {title: qsTr("Saturation"), detail: qsTr("Control how vivid the colors look"), folder: "saturation"},
                        {title: qsTr("White balance"), detail: qsTr("Correct warm or cool lighting"), folder: "white"}
                    ]
                    Button {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 54
                        enabled: attachedfiltersmodel.isProducerSelected
                        text: modelData.title + "\n" + modelData.detail
                        onClicked: {
                            if (cutItTools.openQuickFilter(modelData.folder)) root.showColorHome = false;
                        }
                    }
                }
                Button {
                    text: qsTr("Advanced color tools...")
                    Layout.fillWidth: true
                    enabled: attachedfiltersmodel.isProducerSelected
                    onClicked: { root.showColorHome = false; filterMenu.open(); }
                }
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.65
                    text: qsTr("Use Adjustments to return here. Existing adjustments reopen without adding duplicates.")
                }
            }
        }
    }

    CopyFiltersDialog {
        id: copyFiltersDialog
    }

    Connections {
        ignoreUnknownSignals: true

        function onMetadataHelpRequested(service) {
            root.addonFilterMetadataHelpRequested(service)
        }

        target: filterConfig.item
    }

    Connections {
        function onIsProducerSelectedChanged() {
            filterMenu.close();
        }

        target: attachedfiltersmodel
    }
}

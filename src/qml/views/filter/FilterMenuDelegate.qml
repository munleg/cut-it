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
import "FilterMenu.js" as Logic
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Shotcut.Controls as Shotcut
import org.shotcut.qml as Shotcut

Rectangle {
    id: wrapper

    width: GridView.view ? GridView.view.cellWidth - 8 : 140
    height: GridView.view ? GridView.view.cellHeight - 8 : 108
    radius: 6
    color: wrapper.GridView.isCurrentItem ? activePalette.alternateBase : activePalette.base
    border.width: wrapper.GridView.isCurrentItem ? 1 : 0
    border.color: activePalette.text
    property var entry: metadatamodel.get(index)
    Image {
        id: thumbnail
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 6 }
        height: 64
        source: entry && entry.icon.length ? entry.icon : 'qrc:///icons/oxygen/32x32/devices/video-television.png'
        asynchronous: true
        sourceSize.width: 180
        sourceSize.height: 100
        fillMode: Image.PreserveAspectFit
    }
    Label {
        anchors { top: thumbnail.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; margins: 6 }
        text: name
        color: activePalette.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: wrapper.GridView.view.currentIndex = index
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) wrapper.GridView.view.itemSelected(index);
            else if (pluginType === Shotcut.Metadata.FilterSet && service.length === 0) confirmDialog.show();
        }
    }
    ToolButton {
        anchors { top: parent.top; right: parent.right }
        width: 26
        height: 26
        text: favorite ? "\u2605" : "\u2606"
        Accessible.name: qsTr("Favorite")
        onClicked: favorite = !favorite
    }

    Window {
        id: confirmDialog

        flags: Qt.Dialog
        color: activePalette.window
        modality: Qt.ApplicationModal
        title: qsTr('Delete Filter Set')
        width: 400
        minimumWidth: 400
        height: 90
        minimumHeight: 90
        Component.onCompleted: confirmDialogOk.forceActiveFocus(Qt.TabFocusReason)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10

            Label {
                text: qsTr("Are you sure you want to delete this?\n%1")
                maximumLineCount: 1
            }
            Label {
                text: name
                elide: Text.ElideRight
                Layout.preferredWidth: confirmDialog.width - parent.anchors.margins * 2
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight

                Shotcut.Button {
                    id: confirmDialogOk

                    text: qsTr('OK')
                    focus: true
                    onClicked: {
                        metadatamodel.deleteFilterSet(name);
                        confirmDialog.close();
                    }
                    Keys.onEscapePressed: confirmDialog.close()
                }

                Shotcut.Button {
                    text: qsTr('Cancel')
                    onClicked: confirmDialog.close()
                    Keys.onEscapePressed: confirmDialog.close()
                }
            }
            Item {
                Layout.fillHeight: true
            }
        }
    }
}

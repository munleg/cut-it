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

Item {
    id: root
    width: 425
    height: advanced.checked ? 850 : editor.implicitHeight + 24
    property bool syncing: true
    property bool writing: false
    property bool cutItSimpleEditor: !advanced.checked
    function put(name, value) {
        writing = true;
        filter.set(name, value);
        writing = false;
    }
    function sync() {
        if (writing) return;
        syncing = true;
        if (words.text !== filter.get('argument')) words.text = filter.get('argument');
        fonts.currentIndex = fonts.find(filter.get('family'));
        size.value = Math.max(8, Math.round(filter.getDouble('size')));
        bold.checked = filter.getDouble('weight') >= 600;
        italic.checked = filter.get('style') === 'italic';
        ink.value = filter.get('fgcolour') || '#ffffffff';
        syncing = false;
    }
    function fontSize(px) {
        put('shotcut:usePointSize', 1);
        put('shotcut:pointSize', 0);
        put('size', px);
    }
    function style(index) {
        put('fgcolour', '#ffffffff');
        put('bgcolour', index === 2 ? '#bb000000' : '#00000000');
        put('olcolour', '#ff000000');
        put('outline', index === 1 ? 4 : 0);
        put('weight', index === 3 ? 700 : 400);
        fontSize(Math.round(profile.height * (index === 3 ? 0.10 : 0.06)));
        sync();
    }
    Component.onCompleted: {
        if (filter.isNew) {
            put('argument', qsTr('Your text'));
            put('family', 'Noto Sans');
            put('geometry', '5%/5%:90%x90%');
            put('halign', 'center');
            put('valign', 'middle');
            put('opacity', 1.0);
            style(0);
        }
        sync();
    }
    Connections {
        target: filter
        function onChanged() { root.sync(); }
    }
    Connections {
        target: cutItFonts
        function onFamiliesChanged() { Qt.callLater(root.sync); }
    }
    ColumnLayout {
        id: editor
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 10
        visible: !advanced.checked
        Label { text: qsTr('Text'); font.pixelSize: 18; font.bold: true; color: '#ffffff' }
        Label {
            text: qsTr('Edits affect the selected text clip.')
            color: '#888888'
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            clip: true
            TextArea {
                id: words
                placeholderText: qsTr('Type your text…')
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                color: '#ffffff'
                background: Rectangle {
                    color: '#1a1a1a'
                    border.color: '#333333'
                    radius: 4
                }
                onTextChanged: if (!root.syncing) root.put('argument', text)
            }
        }
        Label { text: qsTr('Font'); color: '#cccccc'; font.pixelSize: 12 }
        ComboBox {
            id: fonts
            Layout.fillWidth: true
            editable: true
            model: cutItFonts.families
            onActivated: root.put('family', currentText)
            onAccepted: if (find(editText) >= 0) root.put('family', editText)
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            RowLayout {
                spacing: 6
                Label { text: qsTr('Size:'); color: '#cccccc' }
                SpinBox {
                    id: size
                    from: 8; to: 1000; editable: true
                    implicitWidth: 100
                    onValueModified: root.fontSize(value)
                }
            }
            RowLayout {
                spacing: 4
                Button {
                    id: bold
                    text: qsTr('B'); font.bold: true; checkable: true
                    implicitWidth: 34
                    onClicked: root.put('weight', checked ? 700 : 400)
                }
                Button {
                    id: italic
                    text: qsTr('I'); font.italic: true; checkable: true
                    implicitWidth: 34
                    onClicked: root.put('style', checked ? 'italic' : 'normal')
                }
            }
            RowLayout {
                spacing: 6
                Layout.alignment: Qt.AlignRight
                Label { text: qsTr('Color:'); color: '#cccccc' }
                Shotcut.ColorPicker {
                    id: ink
                    eyedropper: false
                    onValueChanged: if (!root.syncing) root.put('fgcolour', value.toString())
                }
            }
        }
        Label { text: qsTr('Quick Styles'); color: '#cccccc'; font.pixelSize: 12 }
        GridLayout {
            columns: 2
            rowSpacing: 6
            columnSpacing: 6
            Layout.fillWidth: true
            Repeater {
                model: [
                    { name: qsTr('Plain'), sample: 'Aa', bg: '#2b2b2b', fg: '#ffffff', bold: false, outline: false },
                    { name: qsTr('Outline'), sample: 'Aa', bg: '#2b2b2b', fg: '#ffffff', bold: false, outline: true },
                    { name: qsTr('Caption'), sample: 'Aa', bg: '#111111', fg: '#ffffff', bold: false, outline: false },
                    { name: qsTr('Title'), sample: 'AA', bg: '#2b2b2b', fg: '#ffffff', bold: true, outline: false }
                ]
                Button {
                    id: styleBtn
                    Accessible.name: modelData.name
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 38
                    onClicked: root.style(index)
                    contentItem: RowLayout {
                        spacing: 8
                        Rectangle {
                            width: 28
                            height: 24
                            radius: 3
                            color: styleBtn.modelData.bg
                            border.color: styleBtn.modelData.outline ? '#ffffff' : '#444444'
                            border.width: styleBtn.modelData.outline ? 1.5 : 1
                            Layout.alignment: Qt.AlignVCenter
                            Text {
                                anchors.centerIn: parent
                                text: styleBtn.modelData.sample
                                color: styleBtn.modelData.fg
                                style: styleBtn.modelData.outline ? Text.Outline : Text.Normal
                                styleColor: "#000000"
                                font.bold: styleBtn.modelData.bold
                                font.pixelSize: styleBtn.modelData.bold ? 13 : 11
                            }
                        }
                        Text {
                            text: styleBtn.modelData.name
                            color: '#e0e0e0'
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    background: Rectangle {
                        color: styleBtn.down ? '#383838' : (styleBtn.hovered ? '#303030' : '#242424')
                        border.color: '#3d3d3d'
                        radius: 4
                    }
                }
            }
        }
        RowLayout {
            Label { text: qsTr('Position'); color: '#cccccc' }
            ComboBox {
                Layout.fillWidth: true
                model: [qsTr('Choose…'), qsTr('Top'), qsTr('Center'), qsTr('Bottom')]
                onActivated: {
                    if (!currentIndex) return;
                    root.put('geometry', '5%/5%:90%x90%');
                    root.put('valign', ['top', 'middle', 'bottom'][currentIndex - 1]);
                    root.put('halign', 'center');
                }
            }
        }
        Label { text: qsTr('Hold Shift and drag the text in the preview to position it.'); color: '#888888'; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        Button { id: moreFonts; text: checked ? qsTr('Hide online fonts') : qsTr('More fonts'); checkable: true }
        RowLayout {
            visible: moreFonts.checked
            ComboBox { id: onlineFont; Layout.fillWidth: true; model: cutItFonts.googleFamilies }
            Button { text: cutItFonts.busy ? qsTr('Downloading…') : qsTr('Get font'); enabled: !cutItFonts.busy; onClicked: cutItFonts.download(onlineFont.currentText) }
        }
        Label { visible: moreFonts.checked; text: cutItFonts.status || qsTr('Lato, Noto Sans and Bebas Neue are ready offline.'); color: '#888888'; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        Button { text: qsTr('Advanced text and animation'); onClicked: advanced.checked = true }
    }
    Button {
        id: advanced
        visible: checked
        checkable: true
        text: qsTr('Back to simple text')
        anchors.top: parent.top
        onClicked: { checked = false; root.sync(); }
    }
    Loader {
        anchors.top: advanced.bottom
        anchors.topMargin: 8
        width: parent.width
        active: advanced.checked
        source: active ? 'AdvancedText.qml' : ''
    }
}

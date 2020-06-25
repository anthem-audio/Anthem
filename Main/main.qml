/*
    Copyright (C) 2019, 2020 Joshua Wade

    This file is part of Anthem.

    Anthem is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, either version 3 of
    the License, or (at your option) any later version.

    Anthem is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with Anthem. If not, see
                        <https://www.gnu.org/licenses/>.
*/

import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Shapes 1.14
import QtGraphicalEffects 1.14
import QtQuick.Dialogs 1.2
import "BasicComponents"
import "BasicComponents/GenericTooltip"
import "Dialogs"
import "Menus"
import "Global"
import "Commands"

Window {
    id: mainWindow
    flags: Qt.Window | Qt.FramelessWindowHint
    visible: true
    width: 1300
    height: 768
    property bool isMaximized: false
    property bool isClosing: false
    property int tabsRemaining: -1
    readonly property int margin: 5

    /*
        This stores data used all over the UI. It can be accessed from almost
        anywhere by calling globalStore.(something) Because Qml (tm) (:
    */
    GlobalStore {
        id: globalStore
    }

    Commands {
        id: commands
    }

    // All commands must have exec() and undo(). This is not enforced at runtime.
    function exec(command) {
        // If the history pointer isn't at the end, remove the tail
        if (commands.historyPointer + 1 !== commands.history.length) {
            commands.history.splice(commands.historyPointer + 1);
        }

        commands.history.push(command);
        commands.historyPointer++;
        command.exec(command.execData);
    }

    function undo() {
        const command = commands.history[commands.historyPointer];
        if (!command) return;
        commands.historyPointer--;
        command.undo(command.undoData);

        // This might do bad things for translation
        globalStore.statusMessage = `${qsTr('Undo')} ${command.description}`;
    }

    function redo() {
        const command = commands.history[commands.historyPointer + 1];
        if (!command) return;
        commands.historyPointer++;
        command.exec(command.execData);

        globalStore.statusMessage = `${qsTr('Redo')} ${command.description}`;
    }

    color: "#454545"

    SaveLoadHandler {
        id: saveLoadHandler
    }

    InformationDialog {
        id: infoDialog
    }

    ResizeHandles {
        anchors.fill: parent
        window: mainWindow
    }

    Shortcut {
        sequence: "Ctrl+Z"
        onActivated: undo()
    }

    Shortcut {
        sequence: "Ctrl+Shift+Z"
        onActivated: redo()
    }

    Shortcut {
        sequence: "Ctrl+N"
        onActivated: Anthem.newProject()
    }

    // Ctrl+W lives in TabGroup

    Shortcut {
        sequence: "Ctrl+O"
        onActivated: loadFileDialog.open()
    }

    Shortcut {
        sequence: "Ctrl+S"
        onActivated: saveLoadHandler.save()
    }

    Connections {
        target: mainWindow
        onClosing: {
            close.accepted = false;
            saveLoadHandler.closeWithSavePrompt()
        }
    }

//    Image {
//        id: asdf
//        source: "file:///C:\\Users\\qbgee\\Pictures\\6p6qwzkpyh921.jpg"
//        anchors.fill: parent
//    }
//    FastBlur {
//        id: blurredbg
//        visible: true
//        anchors.fill: asdf
//        source: asdf
//        radius: 128
//    }

    Item {
        id: header
        width: parent.width
        height: 30

        anchors.top: parent.top

        Item {
            id: headerControlsContainer
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: margin
            anchors.leftMargin: margin
            anchors.rightMargin: margin
            height: 20

            MoveHandle {
                window: mainWindow
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                    right: windowControlButtons.left
                }
            }

            TabGroup {
                id: tabGroup
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                // Width is managed internally by TabGroup

                onLastTabClosed: Qt.quit()
            }

            WindowControls {
                id: windowControlButtons
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                onMinimizePressed: {
                    mainWindow.showMinimized();
                }

                onMaximizePressed: {
                    if (mainWindow.isMaximized)
                        mainWindow.showNormal();
                    else
                        mainWindow.showMaximized();

                    mainWindow.isMaximized = !mainWindow.isMaximized;
                }

                onClosePressed: {
                    saveLoadHandler.closeWithSavePrompt();
                }
            }
        }
    }

    Item {
        id: mainContentContainer

        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footerContainer.top

        anchors.leftMargin: 5
        anchors.rightMargin: 5
        anchors.bottomMargin: 10

        ControlsPanel {
            id: controlsPanel
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: parent.right
        }

        MainStack {
            id: mainStack
            anchors.top: controlsPanel.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 4
            showControllerRack: btnShowControllerRack.pressed
            showExplorer: explorerTabs.selectedIndex > -1
            showEditors: editorPanelTabs.selectedIndex > -1
        }
    }

    Item {
        id: footerContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        height: 15
        width: 65

        ButtonGroup {
            id: explorerTabs
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            showBackground: false
            defaultButtonWidth: 25
            defaultImageWidth: 15
            defaultButtonHeight: 15
            defaultLeftMargin: 20
            managementType: ButtonGroup.ManagementType.Selector
            selectedIndex: 0
            allowDeselection: true
            fixedWidth: false

            ListModel {
                id: explorerTabsModel

                ListElement {
                    leftMargin: 15
                    imageSource: "Images/File.svg"
                    hoverMessage: "File explorer"
                }

                ListElement {
                    imageSource: "Images/Document.svg"
                    imageWidth: 11
                    buttonWidth: 16
                    leftMargin: 15
                    hoverMessage: "Project explorer"
                }
            }

            buttons: explorerTabsModel
        }

        Rectangle {
            id: spacer1
            width: 2
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: explorerTabs.right
            anchors.leftMargin: 20
            color: Qt.rgba(1, 1, 1, 0.11)
        }

        ButtonGroup {
            id: layoutTabs
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: spacer1.right
            anchors.leftMargin: 5
            showBackground: false
            defaultButtonHeight: 15
            defaultLeftMargin: 15
            buttonAutoWidth: true
            defaultInnerMargin: 0
            managementType: ButtonGroup.ManagementType.Selector
            selectedIndex: 0
            fixedWidth: false

            ListModel {
                id: layoutTabsModel
                ListElement {
                    textContent: "ARRANGE"
                    hoverMessage: "Arrangement layout"
                }
                ListElement {
                    textContent: "MIX"
                    hoverMessage: "Mixing layout"
                }
                ListElement {
                    textContent: "EDIT"
                    hoverMessage: "Editor layout"
                }
            }

            buttons: layoutTabsModel
        }

        Rectangle {
            id: spacer2
            width: 2
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: layoutTabs.right
            anchors.leftMargin: 20
            color: Qt.rgba(1, 1, 1, 0.11)
        }

        ButtonGroup {
            id: editorPanelTabs
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: spacer2.right
            showBackground: false
            defaultButtonWidth: 25
            defaultImageWidth: 15
            defaultButtonHeight: 15
            defaultLeftMargin: 10
            defaultTopMargin: 0
            managementType: ButtonGroup.ManagementType.Selector
            selectedIndex: 3
            allowDeselection: true
            fixedWidth: false

            ListModel {
                id: editorPanelTabsModel
                ListElement {
                    imageSource: "Images/Piano Roll.svg"
                    hoverMessage: "Piano roll"
                    leftMargin: 20
                }
                ListElement {
                    imageSource: "Images/Automation.svg"
                    hoverMessage: "Automation editor"
                }
                ListElement {
                    imageSource: "Images/Plugin.svg"
                    hoverMessage: "Plugin rack"
                }
                ListElement {
                    imageSource: "Images/Mixer.svg"
                    hoverMessage: "Mixer"
                }
            }

            buttons: editorPanelTabsModel
        }

        Rectangle {
            id: spacer3
            width: 2
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: editorPanelTabs.right
            anchors.leftMargin: 20
            color: Qt.rgba(1, 1, 1, 0.11)
        }

        Text {
            id: statusText
            anchors.left: spacer3.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 20
            text: globalStore.statusMessage
            font.family: Fonts.notoSansRegular.name
            font.pixelSize: 11
            color: Qt.rgba(1, 1, 1, 0.6)
        }

        Button {
            id: btnShowControllerRack
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: 15
            width: 15
            imageSource: "Images/Controllers.svg"
            imageWidth: 15
            imageHeight: 15
            showBorder: false
            showBackground: false
            isToggleButton: true
            pressed: true
            hoverMessage: pressed ? "Hide controller rack" : "Show controller rack"
        }
    }

    TooltipManager {
        anchors.fill: parent
        id: tooltipManager
    }

    Menus {
        id: menuHelper
        anchors.fill: parent
    }
}

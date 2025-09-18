import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope

    OverviewSearch {
        id: searchPanel
    }

    Variants {
        id: overviewVariants
        model: Quickshell.screens
        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
            screen: modelData
            visible: GlobalStates.overviewWindowsOpen

            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            // WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            color: "transparent"

            mask: Region {
                item: GlobalStates.overviewWindowsOpen ? columnLayout : null
            }
            // HyprlandWindow.visibleMask: Region { // Buggy with scaled monitors
            //     item: GlobalStates.overviewWindowsOpen ? columnLayout : null
            // }

            anchors {
                top: true
                bottom: true
                left: !(Config?.options.overview.enable ?? true) 
                right: !(Config?.options.overview.enable ?? true) 
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                property bool canBeActive: root.monitorIsFocused
                onCleared: () => {
                    if (!active) GlobalStates.overviewWindowsOpen = false
                }
            }

            Connections {
                target: GlobalStates
                function onOverviewWindowsOpenChanged() {
                    if (GlobalStates.overviewWindowsOpen)  {
                        delayedGrabTimer.start()
                    }
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: Config.options.hacks.arbitraryRaceConditionDelay
                repeat: false
                onTriggered: {
                    if (!grab.canBeActive)
                        return;
                    grab.active = GlobalStates.overviewWindowsOpen;
                }
            }

            implicitWidth: columnLayout.implicitWidth
            implicitHeight: columnLayout.implicitHeight

            function setSearchingText(text) {
                searchWidget.setSearchingText(text);
                searchWidget.focusFirstItem();
            }

            ColumnLayout {
                id: columnLayout
                visible: GlobalStates.overviewWindowsOpen
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.overviewWindowsOpen = false;
                    } else if (event.key === Qt.Key_Left) {
                        if (!root.searchingText)
                            Hyprland.dispatch("workspace r-1");
                    } else if (event.key === Qt.Key_Right) {
                        if (!root.searchingText)
                            Hyprland.dispatch("workspace r+1");
                    }
                }

                SearchWidget {
                    id: searchWidget
                    Layout.alignment: Qt.AlignHCenter
                    onSearchingTextChanged: text => {
                        root.searchingText = searchingText;
                    }
                }

                Loader {
                    id: overviewLoader
                    active: GlobalStates.overviewWindowsOpen && (Config?.options.overview.enable ?? true)
                    sourceComponent: OverviewWidget {
                        panelWindow: root
                        visible: true
                    }
                }
            }
        }
    }

    function toggleClipboard() {
    //     if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
    //         GlobalStates.overviewOpen = false;
    //         return;
    //     }
    //     for (let i = 0; i < overviewVariants.instances.length; i++) {
    //         let panelWindow = overviewVariants.instances[i];
    //         if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
    //             overviewScope.dontAutoCancelSearch = true;
    //             panelWindow.setSearchingText(Config.options.search.prefix.clipboard);
    //             GlobalStates.overviewOpen = true;
    //             return;
    //         }
    //     }
    }

    function toggleEmojis() {
        // if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
        //     GlobalStates.overviewOpen = false;
        //     return;
        // }
        // for (let i = 0; i < overviewVariants.instances.length; i++) {
        //     let panelWindow = overviewVariants.instances[i];
        //     if (panelWindow.modelData.name == Hyprland.focusedMonitor.name) {
        //         overviewScope.dontAutoCancelSearch = true;
        //         panelWindow.setSearchingText(Config.options.search.prefix.emojis);
        //         GlobalStates.overviewOpen = true;
        //         return;
        //     }
        // }
    }

    IpcHandler {
        target: "overview"

        // function toggle() {
        //     GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        // }
        // function close() {
        //     GlobalStates.overviewOpen = false;
        // }
        // function open() {
        //     GlobalStates.overviewOpen = true;
        // }
        // function toggleReleaseInterrupt() {
        //     GlobalStates.superReleaseMightTrigger = false;
        // }
        function clipboardToggle() {
            overviewScope.toggleClipboard();
        }
    }
    GlobalShortcut {
        name: "overviewSearchToggle"
        description: qsTr("Toggles overview on press")

        onPressed: {
            GlobalStates.overviewSearchOpen = !GlobalStates.overviewSearchOpen
        }
    }
    GlobalShortcut {
        name: "overviewToggle"
        description: "Toggles overview on press"

        onPressed: {
            GlobalStates.overviewWindowsOpen = !GlobalStates.overviewWindowsOpen;
        }
    }
    GlobalShortcut {
        name: "overviewClose"
        description: "Closes overview"

        onPressed: {
            GlobalStates.overviewSearchOpen = false;
            GlobalStates.overviewWindowOpen = false;
        }
    }
    GlobalShortcut {
        name: "overviewToggleRelease"
        description: "Toggles overview on release"

        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }

        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            GlobalStates.overviewWindowsOpen = !GlobalStates.overviewWindowsOpen;
        }
    }
    GlobalShortcut {
        name: "overviewToggleReleaseInterrupt"
        description: "Interrupts possibility of overview being toggled on release. " + "This is necessary because GlobalShortcut.onReleased in quickshell triggers whether or not you press something else while holding the key. " + "To make sure this works consistently, use binditn = MODKEYS, catchall in an automatically triggered submap that includes everything."

        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }
    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on overview widget"

        onPressed: {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on overview widget"

        onPressed: {
            overviewScope.toggleEmojis();
        }
    }
}

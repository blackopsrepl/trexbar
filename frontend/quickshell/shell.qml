import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property string configPath: Quickshell.env("TREXBAR_CONFIG") || ((Quickshell.env("HOME") || "") + "/.config/trexbar/config.json")
    property string stateDir: Quickshell.env("TREXBAR_STATE_DIR") || ((Quickshell.env("HOME") || "") + "/.local/state/trexbar")
    property string trexbarBin: Quickshell.env("TREXBAR_BIN") || "trexbar"
    property string snapshotPath: stateDir + "/snapshot.json"
    property string uiPath: stateDir + "/ui.json"
    property string eventPath: stateDir + "/state-event.json"
    property string textFont: "Fira Code"
    property string iconFont: "Symbols Nerd Font Mono"
    property var viewData: snapshotAdapter.view && snapshotAdapter.view.summary ? snapshotAdapter.view : ({ summary: {}, sessions: [], agents: [], errors: [], headlineSession: null })
    property var summary: viewData.summary || ({})
    property var sessions: viewData.sessions || []
    property var agents: viewData.agents || []
    property var errors: viewData.errors || []
    property var headlineSession: viewData.headlineSession || null

    // Omarchy theme wiring: live-follows the active Omarchy theme palette
    // (the same colors.toml the Omarchy shell reads). Falls back to the
    // built-in palette where a key is absent or Omarchy is not running.
    property string themeColorsPath: Quickshell.env("OMARCHY_THEME_COLORS") || ((Quickshell.env("HOME") || "") + "/.local/state/omarchy/current/theme/colors.toml")
    property var themePalette: ({})

    function applyThemeColors(raw) {
        var parsed = {}
        var lines = String(raw || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
            var match = lines[i].match(/^\s*([A-Za-z0-9_-]+)\s*=\s*["']?(#[0-9A-Fa-f]{6})/)
            if (match)
                parsed[match[1]] = match[2]
        }
        root.themePalette = parsed
    }

    function themeColor(key, fallback) {
        var value = root.themePalette[key]
        return (typeof value === "string" && value.length > 0) ? value : fallback
    }

    readonly property QtObject theme: QtObject {
        readonly property color bg: root.themeColor("background", "#0B0C16")
        readonly property color bgDeep: root.themeColor("dark_background", "#050711")
        readonly property color surface: root.themeColor("lighter_background", "#151927")
        readonly property color surfaceAlt: root.themeColor("selection", "#10131F")
        readonly property color border: root.themeColor("muted", "#2E344A")
        readonly property color borderSoft: root.themeColor("muted", "#26304A")
        readonly property color borderFaint: root.themeColor("selection", "#252B3F")
        readonly property color text: root.themeColor("bright_foreground", "#DDF7FF")
        readonly property color textMuted: root.themeColor("dark_foreground", "#6A6E95")
        readonly property color good: root.themeColor("green", "#82FB9C")
        readonly property color goodSoft: root.themeColor("bright_green", "#9CF7C2")
        readonly property color info: root.themeColor("bright_cyan", "#85E1FB")
        readonly property color warn: root.themeColor("yellow", "#F2C572")
        readonly property color bad: root.themeColor("red", "#E06C75")
    }

    FileView {
        id: themeFile
        path: root.themeColorsPath
        watchChanges: true
        printErrors: false
        onLoaded: root.applyThemeColors(text())
        onFileChanged: reload()
        onLoadFailed: root.applyThemeColors("")
    }

    function runTrexbar(args) {
        if (actionRunner.running) {
            actionRunner.signal(9)
            actionRunner.running = false
        }

        actionRunner.command = [root.trexbarBin].concat(args).concat(["--config", root.configPath])
        actionRunner.running = true
    }

    function closeModal() {
        root.runTrexbar(["ui", "close"])
    }

    function statusColor(level) {
        if (level === "critical" || level === "error") {
            return root.theme.bad
        }
        if (level === "warning") {
            return root.theme.warn
        }
        if (level === "stale" || level === "loading") {
            return root.theme.textMuted
        }
        return root.theme.good
    }

    function sessionStatusColor(session) {
        return root.statusColor(session && session.health ? session.health.level : "unknown")
    }

    function agentStatusColor(state) {
        if (state === "running") {
            return root.theme.good
        }
        if (state === "waiting") {
            return root.theme.warn
        }
        return root.theme.textMuted
    }

    function gitText(session) {
        if (!session || !session.git || !session.git.isRepo) {
            return "no git"
        }

        var parts = [session.git.badge || session.git.branch || "git"]
        if ((session.git.dirtyCount || 0) > 0) {
            parts.push("dirty " + session.git.dirtyCount)
        }
        if ((session.git.ahead || 0) > 0) {
            parts.push("ahead " + session.git.ahead)
        }
        if ((session.git.behind || 0) > 0) {
            parts.push("behind " + session.git.behind)
        }
        return parts.join("  ")
    }

    function sessionMeta(session) {
        if (!session) {
            return ""
        }

        return (session.activityLevel || "unknown") + "  " +
            (session.activityAgo || "unknown") + "  " +
            "CPU " + Math.round(session.stats ? (session.stats.cpuPercent || 0) : 0) + "%  " +
            "RAM " + (session.stats ? (session.stats.memMb || 0) : 0) + " MB"
    }

    Process {
        id: actionRunner
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length) {
                    console.log(text.trim())
                }
            }
        }
    }

    FileView {
        id: snapshotFile
        path: root.snapshotPath
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: snapshotAdapter
            property int snapshotVersion: 0
            property string generatedAt: ""
            property string status: "loading"
            property var summary: ({})
            property var sessions: []
            property var agents: []
            property var errors: []
            property var view: ({})
        }
    }

    FileView {
        id: uiFile
        path: root.uiPath
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: uiAdapter
            property bool open: false
            property string requestedAt: ""
        }
    }

    FileView {
        id: eventFile
        path: root.eventPath
        watchChanges: true
        onFileChanged: root.reloadState()
    }

    function reloadState() {
        snapshotFile.reload()
        uiFile.reload()
        eventFile.reload()
    }

    Component.onCompleted: root.reloadState()

    component MetricTile: Rectangle {
        property string label: ""
        property string value: ""
        property color accent: root.theme.good

        Layout.fillWidth: true
        Layout.preferredHeight: 74
        color: root.theme.surfaceAlt
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.5)
        border.width: 1
        radius: 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: label
                color: root.theme.textMuted
                font.family: root.textFont
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: value
                color: accent
                font.family: root.textFont
                font.pixelSize: 24
                font.bold: true
                elide: Text.ElideRight
            }
        }
    }

    component IconButton: Rectangle {
        signal clicked()
        property string icon: ""
        property string label: ""
        property color accent: root.theme.good

        Layout.preferredWidth: 112
        Layout.preferredHeight: 38
        color: buttonArea.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.14) : root.theme.surface
        border.color: buttonArea.containsMouse ? accent : root.theme.border
        border.width: 1
        radius: 0

        Behavior on color {
            ColorAnimation { duration: 110 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 110 }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: icon
                color: accent
                font.family: root.iconFont
                font.pixelSize: 15
            }

            Text {
                text: label
                color: root.theme.text
                font.family: root.textFont
                font.pixelSize: 12
            }
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component AgentPill: Rectangle {
        property var agent: null

        implicitHeight: 28
        implicitWidth: pillContent.implicitWidth + 24
        color: pillArea.containsMouse ? Qt.rgba(root.theme.good.r, root.theme.good.g, root.theme.good.b, 0.05) : root.theme.surface
        border.color: pillArea.containsMouse ? root.theme.good : root.theme.border
        border.width: 1
        radius: 0

        Behavior on color {
            ColorAnimation { duration: 110 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 110 }
        }

        RowLayout {
            id: pillContent
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: 0
                color: root.agentStatusColor(agent ? agent.activityState : "unknown")
            }

            Text {
                text: agent ? (agent.processName + " / " + agent.projectName) : "unknown"
                color: root.theme.text
                font.family: root.textFont
                font.pixelSize: 11
                font.bold: true
            }

            Text {
                visible: agent && agent.childAiNames && agent.childAiNames.length > 0
                text: agent ? ("(" + agent.childAiNames.length + ")") : ""
                color: root.theme.textMuted
                font.family: root.textFont
                font.pixelSize: 10
            }
        }

        MouseArea {
            id: pillArea
            anchors.fill: parent
            hoverEnabled: true
        }
    }

    PanelWindow {
        id: modal
        visible: uiAdapter.open
        screen: Quickshell.screens.length ? Quickshell.screens[0] : null
        property int verticalMargin: 18
        implicitWidth: screen ? screen.width : 960
        implicitHeight: screen ? screen.height : 760
        color: "transparent"
        focusable: true
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        margins {
            top: 0
            bottom: 0
            left: 0
            right: 0
        }

        onVisibleChanged: {
            if (visible) {
                modalFade.restart()
            }
        }

        NumberAnimation {
            id: modalFade
            target: card
            property: "opacity"
            from: 0
            to: 1
            duration: 150
            easing.type: Easing.OutCubic
        }

        Shortcut {
            sequence: "Esc"
            context: Qt.WindowShortcut
            onActivated: root.closeModal()
        }

        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: root.theme.bgDeep
                opacity: 0.66
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeModal()
            }

            Rectangle {
                anchors.centerIn: parent
                width: card.width + 10
                height: card.height + 10
                radius: 0
                color: Qt.rgba(0, 0, 0, 0.22)
            }

            Rectangle {
                anchors.centerIn: parent
                width: card.width + 4
                height: card.height + 4
                radius: 0
                color: Qt.rgba(0, 0, 0, 0.34)
            }

            Rectangle {
                id: card
                width: Math.min(960, Math.max(320, modal.width - 36))
                height: Math.min(modal.height - 16, Math.max(420, modal.height - (modal.verticalMargin * 2)))
                anchors.centerIn: parent
                color: root.theme.bg
                border.color: root.theme.good
                border.width: 1
                radius: 0

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 0
                    color: "transparent"
                    border.color: root.theme.borderSoft
                    border.width: 1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            color: root.theme.surfaceAlt
                            border.color: root.theme.good
                            border.width: 1
                            radius: 0

                            Canvas {
                                anchors.fill: parent
                                anchors.margins: 5

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    function x(value) { return value * width / 38 }
                                    function y(value) { return value * height / 38 }

                                    ctx.lineCap = "round"
                                    ctx.lineJoin = "round"

                                    ctx.strokeStyle = "rgba(130, 251, 156, 0.28)"
                                    ctx.lineWidth = Math.max(1, x(1.1))
                                    ctx.beginPath()
                                    ctx.moveTo(x(28), y(5))
                                    ctx.lineTo(x(36), y(2))
                                    ctx.moveTo(x(31), y(10))
                                    ctx.lineTo(x(37), y(9))
                                    ctx.stroke()

                                    ctx.fillStyle = root.theme.bgDeep
                                    ctx.strokeStyle = root.theme.good
                                    ctx.lineWidth = Math.max(1, x(1.7))
                                    ctx.beginPath()
                                    ctx.moveTo(x(33), y(12))
                                    ctx.bezierCurveTo(x(28), y(6), x(17), y(5), x(9), y(10))
                                    ctx.bezierCurveTo(x(2), y(14), x(2), y(19), x(9), y(22))
                                    ctx.lineTo(x(22), y(22))
                                    ctx.quadraticCurveTo(x(19), y(26), x(15), y(27))
                                    ctx.bezierCurveTo(x(24), y(28), x(30), y(31), x(33), y(36))
                                    ctx.lineTo(x(37), y(36))
                                    ctx.quadraticCurveTo(x(34), y(28), x(35), y(22))
                                    ctx.quadraticCurveTo(x(39), y(17), x(33), y(12))
                                    ctx.closePath()
                                    ctx.fill()
                                    ctx.stroke()

                                    ctx.strokeStyle = root.theme.borderSoft
                                    ctx.lineWidth = Math.max(1, x(1))
                                    ctx.beginPath()
                                    ctx.moveTo(x(9), y(22))
                                    ctx.quadraticCurveTo(x(15), y(24), x(22), y(22))
                                    ctx.stroke()

                                    ctx.fillStyle = root.theme.text
                                    var teeth = [9, 13, 17]
                                    for (var i = 0; i < teeth.length; i++) {
                                        ctx.beginPath()
                                        ctx.moveTo(x(teeth[i]), y(22))
                                        ctx.lineTo(x(teeth[i] + 1.8), y(22))
                                        ctx.lineTo(x(teeth[i] + 0.8), y(25))
                                        ctx.closePath()
                                        ctx.fill()
                                    }

                                    ctx.fillStyle = root.theme.good
                                    ctx.strokeStyle = root.theme.text
                                    ctx.lineWidth = Math.max(1, x(0.8))
                                    ctx.beginPath()
                                    ctx.moveTo(x(20), y(13))
                                    ctx.lineTo(x(26), y(11))
                                    ctx.lineTo(x(30), y(14))
                                    ctx.lineTo(x(25), y(17))
                                    ctx.lineTo(x(20), y(15))
                                    ctx.closePath()
                                    ctx.fill()
                                    ctx.stroke()

                                    ctx.strokeStyle = root.theme.bgDeep
                                    ctx.lineWidth = Math.max(1, x(1.5))
                                    ctx.beginPath()
                                    ctx.moveTo(x(25.5), y(12.4))
                                    ctx.lineTo(x(24.3), y(16.4))
                                    ctx.stroke()

                                    ctx.strokeStyle = root.theme.good
                                    ctx.lineWidth = Math.max(1, x(1.5))
                                    ctx.beginPath()
                                    ctx.moveTo(x(18), y(10))
                                    ctx.lineTo(x(27), y(8))
                                    ctx.stroke()

                                    ctx.fillStyle = root.theme.textMuted
                                    ctx.beginPath()
                                    ctx.arc(x(7.5), y(15.4), Math.max(1, x(1.1)), 0, Math.PI * 2)
                                    ctx.fill()

                                    ctx.strokeStyle = root.theme.goodSoft
                                    ctx.lineWidth = Math.max(1, x(1.1))
                                    ctx.beginPath()
                                    ctx.moveTo(x(31), y(24))
                                    ctx.lineTo(x(35), y(27))
                                    ctx.moveTo(x(29), y(29))
                                    ctx.lineTo(x(33), y(34))
                                    ctx.stroke()
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: "trexbar"
                                color: root.theme.text
                                font.family: root.textFont
                                font.pixelSize: 26
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (headlineSession ? (headlineSession.name + "  " + root.sessionMeta(headlineSession)) : "tmux session overview") +
                                    "  " + (snapshotAdapter.generatedAt || "waiting for data")
                                color: root.theme.goodSoft
                                font.family: root.textFont
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 118
                            Layout.preferredHeight: 34
                            color: Qt.rgba(root.statusColor(snapshotAdapter.status).r, root.statusColor(snapshotAdapter.status).g, root.statusColor(snapshotAdapter.status).b, 0.13)
                            border.color: root.statusColor(snapshotAdapter.status)
                            border.width: 1
                            radius: 0

                            Text {
                                anchors.centerIn: parent
                                text: snapshotAdapter.status || "loading"
                                color: root.statusColor(snapshotAdapter.status)
                                font.family: root.textFont
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        IconButton {
                            icon: ""
                            label: "Refresh"
                            onClicked: root.runTrexbar(["refresh"])
                        }

                        IconButton {
                            icon: ""
                            label: "Close"
                            accent: root.theme.info
                            onClicked: root.closeModal()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        MetricTile {
                            label: "sessions"
                            value: summary.sessionCount || 0
                        }

                        MetricTile {
                            label: "attached"
                            value: summary.attachedCount || 0
                            accent: root.theme.info
                        }

                        MetricTile {
                            label: "agents"
                            value: summary.agentCount || 0
                            accent: root.theme.warn
                        }

                        MetricTile {
                            label: "dirty repos"
                            value: summary.dirtyRepoCount || 0
                            accent: (summary.dirtyRepoCount || 0) > 0 ? root.theme.warn : root.theme.good
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 240
                        color: root.theme.bgDeep
                        border.color: root.theme.borderFaint
                        border.width: 1
                        radius: 0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "sessions"
                                    color: root.theme.text
                                    font.family: root.textFont
                                    font.pixelSize: 14
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: (summary.activeCount || 0) + " active  " +
                                        (summary.idleCount || 0) + " idle  " +
                                        (summary.dormantCount || 0) + " dormant"
                                    color: root.theme.textMuted
                                    font.family: root.textFont
                                    font.pixelSize: 11
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                model: root.sessions
                                clip: true
                                spacing: 8

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 72
                                    color: modelData.attached ? Qt.rgba(root.theme.good.r, root.theme.good.g, root.theme.good.b, 0.10) : (index % 2 === 0 ? root.theme.surface : root.theme.surfaceAlt)
                                    border.color: modelData.attached ? root.theme.good : root.theme.borderFaint
                                    border.width: 1
                                    radius: 0

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 10

                                        Rectangle {
                                            Layout.preferredWidth: 10
                                            Layout.fillHeight: true
                                            color: root.sessionStatusColor(modelData)
                                            radius: 0
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 5

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.name || "unnamed"
                                                    color: root.theme.text
                                                    font.family: root.textFont
                                                    font.pixelSize: 15
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    text: modelData.attached ? "attached" : "detached"
                                                    color: modelData.attached ? root.theme.good : root.theme.textMuted
                                                    font.family: root.textFont
                                                    font.pixelSize: 11
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: root.gitText(modelData)
                                                color: root.theme.info
                                                font.family: root.textFont
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: root.sessionMeta(modelData)
                                                color: root.theme.goodSoft
                                                font.family: root.textFont
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Text {
                                            Layout.preferredWidth: 66
                                            text: modelData.health ? (modelData.health.score || 0) : "-"
                                            color: root.sessionStatusColor(modelData)
                                            font.family: root.textFont
                                            font.pixelSize: 24
                                            font.bold: true
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        visible: root.agents.length > 0 || root.errors.length > 0
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            visible: root.agents.length > 0
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "ACTIVE AGENTS"
                                color: root.theme.textMuted
                                font.family: root.textFont
                                font.pixelSize: 9
                                font.bold: true
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: root.agents
                                    AgentPill {
                                        agent: modelData
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            visible: root.errors.length > 0
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "BACKEND ERRORS"
                                color: root.theme.textMuted
                                font.family: root.textFont
                                font.pixelSize: 9
                                font.bold: true
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: root.errors
                                    Rectangle {
                                        implicitHeight: 26
                                        implicitWidth: Math.min(errText.implicitWidth + 24, parent && parent.width > 0 ? parent.width : errText.implicitWidth + 24)
                                        color: Qt.rgba(224/255, 108/255, 117/255, 0.1)
                                        border.color: root.theme.bad
                                        border.width: 1
                                        radius: 0

                                        Text {
                                            id: errText
                                            anchors.centerIn: parent
                                            width: Math.max(0, parent.width - 24)
                                            text: modelData.message
                                            color: root.theme.bad
                                            elide: Text.ElideRight
                                            font.family: root.textFont
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

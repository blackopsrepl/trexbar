import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property string configPath: Quickshell.env("TREXBAR_SWAY_CONFIG") || ((Quickshell.env("HOME") || "") + "/.config/trexbar-sway/config.json")
    property string stateDir: Quickshell.env("TREXBAR_SWAY_STATE_DIR") || ((Quickshell.env("HOME") || "") + "/.local/state/trexbar-sway")
    property string trexbarBin: Quickshell.env("TREXBAR_SWAY_BIN") || "trexbar-sway"
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
            return "#E06C75"
        }
        if (level === "warning") {
            return "#F2C572"
        }
        if (level === "stale" || level === "loading") {
            return "#6A6E95"
        }
        return "#82FB9C"
    }

    function sessionStatusColor(session) {
        return root.statusColor(session && session.health ? session.health.level : "unknown")
    }

    function agentStatusColor(state) {
        if (state === "running") {
            return "#82FB9C"
        }
        if (state === "waiting") {
            return "#F2C572"
        }
        return "#6A6E95"
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
        property color accent: "#82FB9C"

        Layout.fillWidth: true
        Layout.preferredHeight: 74
        color: "#10131F"
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
                color: "#6A6E95"
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
        property color accent: "#82FB9C"

        Layout.preferredWidth: 112
        Layout.preferredHeight: 38
        color: buttonArea.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.14) : "#151927"
        border.color: buttonArea.containsMouse ? accent : "#2E344A"
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
                color: "#DDF7FF"
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
        color: pillArea.containsMouse ? Qt.rgba(130/255, 251/255, 156/255, 0.05) : "#151927"
        border.color: pillArea.containsMouse ? "#82FB9C" : "#2E344A"
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
                color: "#DDF7FF"
                font.family: root.textFont
                font.pixelSize: 11
                font.bold: true
            }

            Text {
                visible: agent && agent.childAiNames && agent.childAiNames.length > 0
                text: agent ? ("(" + agent.childAiNames.length + ")") : ""
                color: "#6A6E95"
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
                color: "#050711"
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
                color: "#0B0C16"
                border.color: "#82FB9C"
                border.width: 1
                radius: 0

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 0
                    color: "transparent"
                    border.color: "#26304A"
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
                            color: "#111827"
                            border.color: "#82FB9C"
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

                                    ctx.fillStyle = "#05080F"
                                    ctx.strokeStyle = "#82FB9C"
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

                                    ctx.strokeStyle = "#26304A"
                                    ctx.lineWidth = Math.max(1, x(1))
                                    ctx.beginPath()
                                    ctx.moveTo(x(9), y(22))
                                    ctx.quadraticCurveTo(x(15), y(24), x(22), y(22))
                                    ctx.stroke()

                                    ctx.fillStyle = "#DDF7FF"
                                    var teeth = [9, 13, 17]
                                    for (var i = 0; i < teeth.length; i++) {
                                        ctx.beginPath()
                                        ctx.moveTo(x(teeth[i]), y(22))
                                        ctx.lineTo(x(teeth[i] + 1.8), y(22))
                                        ctx.lineTo(x(teeth[i] + 0.8), y(25))
                                        ctx.closePath()
                                        ctx.fill()
                                    }

                                    ctx.fillStyle = "#82FB9C"
                                    ctx.strokeStyle = "#DDF7FF"
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

                                    ctx.strokeStyle = "#05080F"
                                    ctx.lineWidth = Math.max(1, x(1.5))
                                    ctx.beginPath()
                                    ctx.moveTo(x(25.5), y(12.4))
                                    ctx.lineTo(x(24.3), y(16.4))
                                    ctx.stroke()

                                    ctx.strokeStyle = "#82FB9C"
                                    ctx.lineWidth = Math.max(1, x(1.5))
                                    ctx.beginPath()
                                    ctx.moveTo(x(18), y(10))
                                    ctx.lineTo(x(27), y(8))
                                    ctx.stroke()

                                    ctx.fillStyle = "#6A6E95"
                                    ctx.beginPath()
                                    ctx.arc(x(7.5), y(15.4), Math.max(1, x(1.1)), 0, Math.PI * 2)
                                    ctx.fill()

                                    ctx.strokeStyle = "#9CF7C2"
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
                                color: "#DDF7FF"
                                font.family: root.textFont
                                font.pixelSize: 26
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (headlineSession ? (headlineSession.name + "  " + root.sessionMeta(headlineSession)) : "tmux session overview") +
                                    "  " + (snapshotAdapter.generatedAt || "waiting for data")
                                color: "#9CF7C2"
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
                            accent: "#85E1FB"
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
                            accent: "#85E1FB"
                        }

                        MetricTile {
                            label: "agents"
                            value: summary.agentCount || 0
                            accent: "#F2C572"
                        }

                        MetricTile {
                            label: "dirty repos"
                            value: summary.dirtyRepoCount || 0
                            accent: (summary.dirtyRepoCount || 0) > 0 ? "#E5C07B" : "#82FB9C"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 240
                        color: "#0F1320"
                        border.color: "#242B40"
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
                                    color: "#DDF7FF"
                                    font.family: root.textFont
                                    font.pixelSize: 14
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: (summary.activeCount || 0) + " active  " +
                                        (summary.idleCount || 0) + " idle  " +
                                        (summary.dormantCount || 0) + " dormant"
                                    color: "#6A6E95"
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
                                    color: modelData.attached ? "#13221C" : (index % 2 === 0 ? "#151927" : "#10131F")
                                    border.color: modelData.attached ? "#82FB9C" : "#252B3F"
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
                                                    color: "#DDF7FF"
                                                    font.family: root.textFont
                                                    font.pixelSize: 15
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    text: modelData.attached ? "attached" : "detached"
                                                    color: modelData.attached ? "#82FB9C" : "#6A6E95"
                                                    font.family: root.textFont
                                                    font.pixelSize: 11
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: root.gitText(modelData)
                                                color: "#85E1FB"
                                                font.family: root.textFont
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: root.sessionMeta(modelData)
                                                color: "#9CF7C2"
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
                                color: "#6A6E95"
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
                                color: "#6A6E95"
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
                                        border.color: "#E06C75"
                                        border.width: 1
                                        radius: 0

                                        Text {
                                            id: errText
                                            anchors.centerIn: parent
                                            width: Math.max(0, parent.width - 24)
                                            text: modelData.message
                                            color: "#E06C75"
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

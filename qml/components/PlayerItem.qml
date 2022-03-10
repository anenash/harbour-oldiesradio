import QtQuick 2.6
import Sailfish.Silica 1.0
import QtQuick.XmlListModel 2.0

import "../pages/Utils.js" as Utils

Item {
    id: playerControl

    property string streamInfo: ""
    property variant streamsURL: []
    property string radioTitle: ""
    property string radioLogo: ""

    onStreamInfoChanged: {
        artistTitle.text = ""
        songTitle.text = ""

        console.log(streamInfo)

        if (streamInfo !== "") {
            updateTrackInfo.start()
        }
    }

    onRadioLogoChanged: {
        currentRadioLogo.source = radioLogo
    }

    onStreamsURLChanged: {
        if (typeof streamsURL === "object") {
            radioPlayer.source = streamsURL[0].url
            sreamBitrateLabel.value = streamsURL[0].type + " " + streamsURL[0].bitrate
            streams.clear()
            for (var i in streamsURL) {
                streams.append({
                                   "url": streamsURL[i].url,
                                   "type": streamsURL[i].type,
                                   "bitrate": streamsURL[i].bitrate
                               })
            }
        } else {
            radioPlayer.source = streamsURL
            sreamBitrateLabel.value = ""
            streams.clear()
        }
    }

    Timer {
        id: updateTrackInfo
        repeat: true
        interval: 5000
        onTriggered: {
            console.log("updateTrackInfo triggered")
            xmlModel.reload()
        }
    }

    ListModel {
        id: streams
    }

    XmlListModel {
        id: xmlModel
        source: streamInfo
        query: "/Response/Item"

        XmlRole { name: "artist"; query: "artist/string()" }
        XmlRole { name: "song"; query: "song/string()" }
        XmlRole { name: "image"; query: "imageItems/image_400/string()" }

        onStatusChanged: {
            if (status === XmlListModel.Ready) {
                console.log(status, get(0))
                currentRadioLogo.source = get(0).image?get(0).image:radioLogo
                app.radioLogo = get(0).image?get(0).image:radioLogo
                artistTitle.text = Utils.replaceEntity(get(0).artist)
                songTitle.text = Utils.replaceEntity(get(0).song)

                radioStation = radioTitle + "\n" + artistTitle.text
            }
        }
    }

    Image {
        id: currentRadioLogo
        height: 200 * Theme.pixelRatio
        width: 200 * Theme.pixelRatio
        fillMode: Image.PreserveAspectFit
        source: radioLogo
        onStatusChanged: {
            if(status === Image.Error) {
                console.log("Can not load image")
                source = radioLogo
            }
        }
        onSourceChanged: {
            console.log("load image", source)
            update()
        }
    }
    Label {
        id: currentStationName
        anchors.left: currentRadioLogo.right
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin
        anchors.top: currentRadioLogo.top
        font.pixelSize: Theme.fontSizeExtraSmall
        font.bold: true
        text:  radioTitle
    }
    Text {
        id: artistTitle
        anchors.left: currentStationName.left
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin
        anchors.top: currentStationName.bottom
        anchors.topMargin: Theme.paddingSmall
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
    }
    Text {
        id: songTitle
        anchors.left: currentStationName.left
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin
        anchors.top: artistTitle.bottom
        anchors.topMargin: Theme.paddingSmall
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
    }

    IconButton {
        id: playButton
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: Theme.paddingLarge
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30 * Theme.pixelRatio
        z: 3
        icon.source: radioPlayer.playbackState != 1?"image://theme/icon-l-play":"image://theme/icon-l-pause"
        width: 50 * Theme.pixelRatio
        height: 50 * Theme.pixelRatio
        enabled: !panel.expanded
        onClicked: {
            console.log("State", radioPlayer.playbackState)
            if (radioPlayer.playbackState === 1) {
                radioPlayer.stop()
            } else {
                radioPlayer.play()
            }
        }
    }

    ValueButton {
        id: sreamBitrateLabel

        anchors.right: parent.right
        anchors.rightMargin: 10 * Theme.pixelRatio
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10 * Theme.pixelRatio
        width: parent.width * 0.3

        onClicked: {
//            var dialog = pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))

//            dialog.accepted.connect(function() {
//                console.log("New bitrate", dialog.rate)
//                value = dialog.rate
//                bitrateQuality(value)
//            })
            panel.open = !panel.open
        }
    }
    DockedPanel {
        id: panel

        width: parent.width
        height: Theme.itemSizeExtraLarge + Theme.paddingLarge
        modal: true

        dock: Dock.Bottom

        GridView {
            anchors.fill: parent
            interactive: false
            cellWidth: width / streams.count
            cellHeight: parent.height
            model: streams
            delegate: ListItem {
//                width: parent.width / streams.count
                contentWidth: parent.width / streams.count
                contentHeight: parent.height
                Label {
                    anchors.centerIn: parent
                    width: parent.width
                    text: type + "\n" + bitrate
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    radioPlayer.source = url
                    sreamBitrateLabel.value = type + " " + bitrate
                    panel.open = false
                }
            }
        }
    }
}

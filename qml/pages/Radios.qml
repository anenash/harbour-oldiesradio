import QtQuick 2.6
import Sailfish.Silica 1.0

import "Utils.js" as Utils
import "../components"

Page {
    id: page

    property string baseURL: "http://www.abradio.cz"
    property string stationsURL: baseURL + "/data/s/stations.json"

    ListModel {
        id: stations
    }

    ListModel {
        id: category
    }

    Database {
        id: database
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: true
        size: BusyIndicatorSize.Large
    }

    function fillData(data) {
        if(data !== "error") {
            var dict = []
            var raw = JSON.parse(data).categories
            for (var i in raw) {
                if (raw[i].radios !== undefined)  {
                    var radios = raw[i].radios
                    for (var j in radios) {
                        if (radios[j].streams !== undefined) {
                            var streams = radios[j].streams
//                            stations.append({
//                                                "categoryTitle": raw[i].title,
//                                                "radioTitle": Utils.replaceEntity(radios[j].name),
//                                                "radioLogoImage": radios[j].logo,
//                                                "radioDescription": Utils.replaceEntity(radios[j].description),
//                                                "streamInfo": radios[j].artwork,
//                                                "radioStream": streams
//                                            })
                            dict.push({
                                          "categoryTitle": raw[i].title,
                                          "radioTitle": Utils.replaceEntity(radios[j].name),
                                          "radioLogoImage": radios[j].logo,
                                          "radioDescription": Utils.replaceEntity(radios[j].description),
                                          "streamInfo": radios[j].artwork,
                                          "radioStream": streams
                                      })
                        }
                    }
                }
//                console.log(JSON.stringify(dict))
                category.append({"categoryTitle": raw[i].title, "dict": JSON.stringify(dict)})
                dict = []
            }
            busyIndicator.running = false
        }
    }

    Component.onCompleted: {
        database.initDatabase()
        var f = database.getFavorites()
        console.log("Fav", JSON.stringify(f))
        var dict = []
        dict.push({
                      "categoryTitle": "My favorites",
                      "radioTitle": "Rádia Anténa Rock",
                      "radioLogoImage": "http://antenarock.sk/templates/img/antena-live.jpg",
                      "radioDescription": "Live vysielanie Rádia Anténa Rock",
                      "streamInfo": "",
                      "radioStream": "http://stream.antenarock.sk/antena-hi.mp3"
                  })
        for (var i in f) {
            dict.push({
                          "categoryTitle": "My favorites",
                          "radioTitle": f[i].title,
                          "radioLogoImage": "../harbour-oldiesradio.png",
                          "radioDescription": f[i].description,
                          "streamInfo": "",
                          "radioStream": f[i].stream
                      })
        }

        category.append({"categoryTitle": "My favorites", "dict": JSON.stringify(dict)})
        Utils.sendHttpRequest("GET", stationsURL, fillData)
    }

    Drawer {
        id: drawer

        anchors.fill: parent
        dock: Dock.Bottom
        open: radioPlayer.source != ""?true:false

        background: PlayerItem {
            id: playerItem
            anchors.fill: parent
        }
        backgroundSize: 220 * Theme.pixelRatio
        SilicaListView {
            id: radioView
            anchors.fill: parent

            PullDownMenu {
                MenuItem {
                    text: "About"
                    onClicked: {
                        console.log("Clicked option 1")
                        pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                    }
                }
                MenuItem {
                    text: "Manage favorires"
                    onClicked: {
                        console.log("Clicked option 2")
                        pageStack.push(Qt.resolvedUrl("ManageFavorites.qml"))
                    }
                }
            }


            header: PageHeader { title: qsTr("Radio categories") }
            model: category
            delegate:  ExpandingSection {
                        title: categoryTitle
                        property variant dataArr: JSON.parse(category.get(index).dict)

                        content.sourceComponent: SilicaListView {
                            id: repeater

                            height: Theme.itemSizeMedium * dataArr.length
                            spacing: Theme.paddingSmall
                            clip: true
                            model: dataArr.length
                            delegate: StationDelegate {
                                radioLogo: dataArr[index].radioLogoImage
                                radioTitle: dataArr[index].radioTitle
                                radioDescription: dataArr[index].radioDescription

                                onClicked: {
                                    console.log(JSON.stringify(dataArr[index]))
                                    playerItem.streamsURL = dataArr[index].radioStream
                                    playerItem.radioTitle = dataArr[index].radioTitle
                                    playerItem.radioLogo = dataArr[index].radioLogoImage
                                    playerItem.streamInfo = typeof dataArr[index].streamInfo === "object"?"":dataArr[index].streamInfo
                                }
                            }
                        }
            }
            spacing: Theme.paddingSmall
            clip: true
            currentIndex: 0
        }
    }
}


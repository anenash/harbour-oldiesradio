import QtQuick 2.6
import Sailfish.Silica 1.0

import "../components"
Page {

    Database {
        id: database
    }

    ListModel {
        id: favorites
    }

    Component.onCompleted: {
        database.initDatabase()
        getFavorites()
    }

    function getFavorites() {
        favorites.clear()
        var f = database.getFavorites()
        console.log("Fav", JSON.stringify(f))
        var dict = []
        for (var i in f) {
            favorites.append({
                                 "id": f[i].keyname,
                                 "title": f[i].title,
                                 "radioLogoImage": f[i].radioLogo, //"../harbour-oldiesradio.png",
                                 "description": f[i].description,
                                 "radioStream": f[i].stream
                             })
        }
    }

    PageHeader {
        id: pageHeader

        title: "Manage favorites"
    }

    Component {
        id: addDialog
        Dialog {

            property variant favorite: ({})
            property alias stationTitle: stationTitle.text
            property alias stationDescription: stationDescription.text
            property alias stationStream: streamURL.text

            Column {
                width: parent.width

                DialogHeader { }

                TextField {
                    id: stationTitle
                    width: parent.width
                    placeholderText: "Station title"
                    label: "Title"
                }
                TextField {
                    id: stationDescription
                    width: parent.width
                    placeholderText: "Station description"
                    label: "Description"
                }
                TextField {
                    id: streamURL
                    width: parent.width
                    placeholderText: "Stream source link (mp3 or aac)"
                    label: "Link to mp3 or aac file"
                }
            }

            onDone: {
                if (result === DialogResult.Accepted) {
                    favorite.id = Qt.md5(streamURL.text)
                    favorite.title = stationTitle.text
                    favorite.description = stationDescription.text
                    favorite.stream = streamURL.text
                }
            }
        }
    }

    Button {
        id: addFavButton

        anchors.top: pageHeader.bottom
        anchors.topMargin: Theme.paddingLarge
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Add station"
        onClicked: {
            var dialog = pageStack.push(addDialog)
            dialog.accepted.connect(function() {
                if (dialog.favorite.stream !== "") {
                    var fav = dialog.favorite
                    console.log(fav.id, fav.title, fav.description, fav.stream)
                    database.addFavorite(fav.id, fav.title, fav.description, fav.stream)
                    getFavorites()
                }
            })
        }
    }

    SectionHeader {
        id: favoritesListHeader

        anchors.top: addFavButton.bottom
        anchors.topMargin: Theme.paddingLarge
        text: "Favorites list"
    }

    SilicaListView {
        anchors.top: favoritesListHeader.bottom
        anchors.topMargin: Theme.paddingLarge
        anchors.bottom: parent.bottom
        width: parent.width

        clip: true
        spacing: Theme.paddingSmall
        model: favorites
        delegate: StationDelegate {
            id:stationDelegate

            radioLogo: radioLogoImage
            radioTitle: title
            radioDescription: description

            menu: ContextMenu {
                MenuItem {
                    text: "Edit"
                    onClicked: {
                        var idx = index
                        var prevId = favorites.get(idx).id
                        var dialog = pageStack.push(addDialog, {
                                                        "stationTitle": favorites.get(idx).title,
                                                        "stationDescription": favorites.get(idx).description,
                                                        "stationStream": favorites.get(idx).radioStream
                                                    })
                        dialog.accepted.connect(function() {
                            if (dialog.favorite.stream !== "") {
                                var fav = dialog.favorite
                                if (prevId !== fav.id) {
                                    database.deleteFavorite(prevId)
                                }
                                console.log(fav.id, fav.title, fav.description, fav.stream)
                                database.addFavorite(fav.id, fav.title, fav.description, fav.stream)
                                getFavorites()
                            }
                        })
                    }
                }
                MenuItem {
                    text: "Delete"
                    onClicked: {
                        var idx = index
                        Remorse.itemAction(stationDelegate, "Deleting", function() {
                            database.deleteFavorite(favorites.get(idx).id)
                            getFavorites()
                        })
                    }
                }
            }
        }
    }
}

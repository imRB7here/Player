import QtQuick 2.12
import QtQuick.Window 2.2
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import Qt.labs.settings 1.1
import QtMultimedia 5.12

ApplicationWindow {
    visible: true
    id: application
    width: Screen.width*(2.5/5)
    height: Screen.height*(2/3)
    maximumHeight: height
    maximumWidth: width
    minimumHeight: height
    minimumWidth: width
    //flags: Qt.FramelessWindowHint
    title: qsTr("Music Player")
    Material.theme: lightThemeOn ? Material.Light : Material.Dark
    Material.primary: themeColor
    Material.background: lightThemeOn ? lightBackground : darkBackground
    Material.accent: themeColor
    Material.foreground: lightThemeOn ? darkForeground : lightForeground

    property bool lightThemeOn: true
    property var barsColor: Material.color(Material.Grey,Material.Shade200)
    property color themeColor: "#5900b3"
    property color lightBackground: "white"
    property color darkBackground: "black"
    property color lightForeground: "#f2f2f2"
    property color darkForeground: "#0d0d0d"


    function changeTheme() {
        //console.log("in changeTheme()");
        lightThemeOn=!lightThemeOn;
    }

    Rectangle {
        id: appRect
        anchors.fill: parent

        color: parent.Material.background

        focus: true
        Keys.onPressed: {
            if ((event.key === Qt.Key_T) && (event.modifiers & Qt.ControlModifier))
                application.changeTheme()
            else if ((event.key === Qt.Key_Q) && (event.modifiers & Qt.ControlModifier))
                application.close()
            else if ((event.key === Qt.Key_Space)) {
                if(audioPlayer.playbackState==MediaPlayer.PlayingState)
                    audioPlayer.pause()
                else if(audioPlayer.playbackState==MediaPlayer.PausedState)
                    audioPlayer.play()
            }

        }

        OptionBar {
            id: optionBar
            width: parent.width/12
            height: parent.height*(7.7/10)
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: contentArea.left
        }

        ContentArea {
            id: contentArea
            visible: true
            width: parent.width*(11/12)
            //height: parent.height
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

        }

        MiniPlayer {
            id: miniPlayer
            visible: true
            anchors.bottom: parent.bottom

            controllingPlaylist: audioPlaylist
            musicPlayer: audioPlayer
        }

    }

    ColorDialog {
        id: colorPicker
        title: "Select Theme Color"
        showAlphaChannel: false
        onAccepted: {
            application.themeColor=color
            close()
        }
        onRejected: {
            close()
        }
    }

    FileDialog {
        id: filesLoader
        title: "Chose Songs"
        folder: shortcuts.music
        selectMultiple: true
        selectExisting: true
        nameFilters: ["Mp3 Files (*.mp3)"]

        onAccepted: {
            audioPlaylist.addItems(fileUrls)

            if(audioPlaylist.save("file:///C:/MyMusicPlayer/Playlists/global_playlist.m3u","m3u")) {
                console.log("Playlist Saved")
            }
            else {
                console.log("Playlist Save  Failed"+audioPlaylist.errorString)
            }
            if(audioPlayer.status==MediaPlayer.NoMedia) {
                audioPlaylist.currentIndex=0
            }

        }

        function basename(url) {
            return (String(url).slice(String(url).lastIndexOf("/")+1,-4))
        }
    }

   MediaPlayer {
        id: audioPlayer
        objectName: "mediaPlayer"
        audioRole: Audio.MusicRole
        autoPlay: true
        property int durationProgress: position
        property double volumeValue: volume
        property Playlist songsQueue: audioPlaylist
        source: ""
        property var coverArtURL: metaData.coverArtUrlSmall ? metaData.coverArtUrlSmall : "qrc:/player/no_album_cover"

        onStopped: {
            if(duration==position)
                songsQueue.next()
            source= songsQueue.currentItemSource
            console.log(metaData.coverArtUrlSmall)
        }

   }

   Playlist {
       id: audioPlaylist
       property int lastSongPlayed: currentIndex

       Component.onCompleted: {
           audioPlaylist.load("file:///C:/MyMusicPlayer/Playlists/global_playlist.m3u","m3u")
           var pos= audioPlayer.durationProgress
           audioPlaylist.currentIndex= lastSongPlayed<=audioPlaylist.itemCount ? lastSongPlayed : 0
           audioPlayer.source= audioPlaylist.currentItemSource
           audioPlayer.seek(pos)
           audioPlayer.pause()
           audioPlayer.volume= audioPlayer.volumeValue

           }
       Component.onDestruction: {
           audioPlaylist.save("file:///C:/MyMusicPlayer/Playlists/global_playlist.m3u","m3u")
           }
   }


    Settings {
        id: appSettings
        category: "Application Settings"
        property alias appThemeMode: application.lightThemeOn
        property alias colorTheme: application.themeColor

    }

    Settings {
        id: playerSettings
        category: "Audio Player Settings"
        property alias lastSongIndex: audioPlaylist.lastSongPlayed
        property alias durToContinue: audioPlayer.durationProgress
        property alias playerVolume: audioPlayer.volumeValue

    }

    Component.onCompleted: {
        console.log("Application is loaded")
    }

}

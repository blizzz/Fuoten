/* Fuoten - ownCloud/Nextcloud News App Client
 * Copyright (C) 2016 Buschtrommel/Matthias Fehring
 * https://www.buschmann23.de/entwicklung/anwendungen/fuoten/
 * https://github.com/Buschtrommel/Fuoten
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

import QtQuick 2.2
import QtQuick.Layouts 1.1
import Sailfish.Silica 1.0
import harbour.fuoten 1.0
import harbour.fuoten.models 1.0
import harbour.fuoten.items 1.0
import "../../common/parts"

SilicaListView {
    id: articlesListView
    anchors.fill: parent
    currentIndex: -1

    property string searchString
    property bool searchVisible: false
    property Page page: null
    property Feed feed: null
    property Folder folder: null
    property alias contextType: articlesContextConfig.contextType

    property string _contextName: ""

    ContextConfig {
        id: articlesContextConfig
        contextId: feed ? feed.id
                          : folder
                            ? folder.id
                            : -1
    }

    function setContextName() {
        _contextName = feed
                       ? feed.title
                       : folder
                         ? folder.name
                         : contextType === FuotenApp.AllItems
                           ? qsTr("fuoten-all-articles")
                           : contextType === FuotenApp.StarredItems
                             ? qsTrId("fuoten-starred-articles")
                             : ""
    }

    Component.onCompleted: {
        if (!page.forwardNavigation && page.status === PageStatus.Active) {
            if (_contextName.length === 0) {
                setContextName()
            }
            pageStack.pushAttached(Qt.resolvedUrl("../../common/pages/ContextConfigPage.qml"), {cc: articlesContextConfig, name: _contextName})
        }
    }

    Connections {
        target: page
        onStatusChanged: {
            if (page.status === PageStatus.Active && !page.forwardNavigation) {
                if (_contextName.length === 0) {
                    setContextName()
                }
                pageStack.pushAttached(Qt.resolvedUrl("../../common/pages/ContextConfigPage.qml"), {cc: articlesContextConfig, name: _contextName})
            }
        }
    }

    PullDownMenu {
        busy: synchronizer.inOperation || (feed && feed.inOperation) || (folder && folder.inOperation)

        MenuItem {
            visible: folder
            //% "Mark folder read"
            text: qsTrId("fuoten-mark-folder-read")
            enabled: folder && !folder.inOperation && folder.unreadCount > 0
            onClicked: //% "Marking %1 read"
                       remorsePop.execute(qsTrId("fuoten-marking-read").arg(folder.name), function() {folder.markAsRead(config, localstorage)})
        }

        MenuItem {
            visible: feed
            //% "Mark feed read"
            text: qsTrId("fuoten-mark-feed-read")
            enabled: feed && !feed.inOperation && feed.unreadCount > 0
            onClicked: feed.markAsRead(config, localstorage)
        }

        MenuItem {
            text: articlesListView.searchVisible
                    //% "Hide search"
                  ? qsTrId("fuoten-hide-search")
                    //% "Show search"
                  : qsTrId("fuoten-show-search")
            onClicked: articlesListView.searchVisible = !articlesListView.searchVisible
        }

        MenuItem {
            //% "Synchronize"
            text: qsTrId("fuoten-synchronize")
            onClicked: synchronizer.sync()
            enabled: !synchronizer.inOperation
        }
    }

    VerticalScrollDecorator { flickable: articlesListView; page: articlesListView.page }

    header: ListPageHeader {
        id: articlesListHeader
        page: articlesListView.page
        searchVisible: articlesListView.searchVisible
        folders: false
        folder: articlesListView.folder
        feed: articlesListView.feed
        onSearchTextChanged: articlesListView.searchString
        Component.onCompleted: {
            switch (contextType) {
            case FuotenApp.AllItems:
                startPage = false
                title = qsTrId("fuoten-all-articles")
                break;
            case FuotenApp.StarredItems:
                startPage = false
                title = qsTrId("fuoten-starred-articles")
                break;
            case FuotenApp.FolderItems:
                description = qsTrId("fuoten-unread-articles-with-count", folder.unreadCount)
            }
        }
    }

    model: ArticleListModel {
        storage: localstorage
        Component.onCompleted: {
            if (feed) {
                parentId = feed.id
                parentIdType = Fuoten.Feed
            } else if (folder) {
                parentId = folder.id
                parentIdType = Fuoten.Folder
            } else if (contextType === FuotenApp.StarredItems) {
                parentIdType = Fuoten.Starred
            }
            load()
        }
    }

    delegate: ListItem {
        id: articleListItem

        contentHeight: Math.max(textCol.height, iconCol.height) + Theme.paddingSmall
        contentWidth: parent.width

        ListView.onAdd: AddAnimation { target: articleListItem }
        ListView.onRemove: RemoveAnimation { target: articleListItem }

        Item {
            width: gi.width
            height: gi.height
            x: -(width/2)
            y: -(height/4)

            GlassItem {
                id: gi
                width: Theme.itemSizeExtraSmall
                height: Theme.itemSizeExtraSmall
                color: Theme.highlightColor
                opacity: display.unread ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
            }
        }

        RowLayout {
            anchors { left: parent.left; right: parent.right; leftMargin: Theme.horizontalPageMargin; rightMargin: Theme.horizontalPageMargin }
            spacing: Theme.paddingSmall

            ColumnLayout {
                id: textCol
                Layout.fillWidth: true

                Text {
                    id: titleText
                    text: Theme.highlightText(display.title, articlesListView.searchString, Theme.highlightColor)
                    Layout.fillWidth: true
                    color: articleListItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    maximumLineCount: 3
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight
                    textFormat: Text.StyledText
                    font.pixelSize: Theme.fontSizeSmall
                }

                Text {
                    id: feedText
                    text: display.feedTitle
                    textFormat: Text.PlainText
                    color: articleListItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeTiny
                }

                Text {
                    id: dateText
                    text: display.pubDate
                    textFormat: Text.PlainText
                    color: articleListItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeTiny
                }
            }

            ColumnLayout {
                id: iconCol
                Layout.preferredWidth: Theme.iconSizeSmall
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

                Image {
                    id: starImage
                    opacity: display.starred ? 1 : 0
                    Layout.preferredWidth: Theme.iconSizeSmall
                    Layout.preferredHeight: Theme.iconSizeSmall
                    source: "image://theme/icon-s-favorite?" + (articleListItem.highlighted ? Theme.highlightColor : Theme.primaryColor)
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                }
            }
        }
    }

    RemorsePopup {
        id: remorsePop
    }
}
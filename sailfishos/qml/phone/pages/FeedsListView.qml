/* Fuoten - ownCloud/Nextcloud News App Client
 * Copyright (C) 2016 Buschtrommel/Matthias Fehring
 * https://www.buschmann23.de/entwicklung/anwendungen/fuoten/
 * https://github.com/Buschtrommel/Fuoten
 *
 * sailfishos/qml/phone/pages/MainPage.qml
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
import harbour.fuoten.models 1.0
import "../../common/parts"


SilicaListView {
    id: feedListFlick
    anchors.fill: parent
    currentIndex: -1

    property string searchString
    property Item page
    property bool searchVisible: false
    property bool startPage: true

    PullDownMenu {
        busy: synchronizer.inOperation

        MenuItem {
            //% "About"
            text: qsTrId("id-about")
            onClicked: pageStack.push(Qt.resolvedUrl("../../common/pages/About.qml"))
            visible: startPage
        }

        MenuItem {
            //% "Settings"
            text: qsTrId("id-settings")
            onClicked: pageStack.push(Qt.resolvedUrl("../../common/pages/Settings.qml"))
            visible: startPage
        }

        MenuItem {
            text: feedListFlick.searchVisible
                    //% "Hide search"
                  ? qsTrId("fuoten-hide-search")
                    //% "Show search"
                  : qsTrId("fuoten-show-search")
            onClicked: feedListFlick.searchVisible = !feedListFlick.searchVisible
        }

        MenuItem {
            //% "Synchronize"
            text: qsTrId("fuoten-synchronize")
            onClicked: synchronizer.sync()
            enabled: !synchronizer.inOperation
        }
    }

    VerticalScrollDecorator { flickable: feedListFlick; page: feedListFlick.page }

    header: ListPageHeader {
        id: feedsListHeader
        page: feedListFlick.page
        searchVisible: feedListFlick.searchVisible
        startPage: feedListFlick.startPage
        folders: false
        onSearchTextChanged: feedListFlick.searchString = searchText
    }
}

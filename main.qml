import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.14
import QtQuick.Shapes 1.14
import QtQuick.Dialogs 1.0
import Qt.labs.settings 1.0
import "./Fonts"
import my.CServiceBackend 1.0

ApplicationWindow {
    id:window
    property color backGroundColor: "#20b2aa"
    property var tikuNum: {"单选题":0,"多选题":0,"判断题":0,"填空题":0,"简答题":0}
    property var appDir: ""
    //试卷生成过程中是否存在错误或警告信息
    property bool hasError: false //是否存在影响打印的错误信息
    property bool hasWarning: false //是否存在需要提醒用户注意的信息
    //添加设置页面的属性
    property var pageSettingMap:{
        "上边距":38,"下边距":35,"左边距":27,"右边距":27,
        "主标题字体":"方正小标宋简体","主标题字号":22,
        "一级标题字体":"黑体","一级标题字号":16,
        "正文字体":"仿宋_GB2312","正文字号":16,
        "考生信息字体":"仿宋_GB2312","考生信息字号":14,
        "行间距":8,"分辨率":300,"横向页面":false
    }
    property var totalScore: 0 //总分值
    //表格属性
    property int defaultRowHeight : 50
    property int defaultColumnWidth : 50

    //各种颜色
    property color hoverColor :"#e0f7fa"
    property color hoverLineColor :"blueviolet"
    property color selectedColor :"#b3e5fc"
    //导入题库成功标志
    property bool importSucessed: false

    visible: true
    width: 600
    height: 600
    minimumWidth: 300
    Material.background: backGroundColor
    title: qsTr("试卷自动生成系统")
    //自定义组件
    CServiceBackend{
        id:serviceBackend
        onError: {
            var errorMsg = getError();
            messageBox.close();
            messageBox.text = errorMsg;
            messageBox.style = "danger";
            timer.stop();
            messageBox.open();
        }
        onReadReady: {
            messageBox.close();
            messageBox.text = "导入题库成功！";
            messageBox.style = "sucess";
            if(!timer.running){
                timer.start();

            }
            else{
                timer.stop();
                timer.start();
            }

            messageBox.open();
        }

    }

    //函数区
    function getColumnWidth(c) { return columnWidths[c] }
    function getRowHeight(r) { return defaultRowHeight; }
    function readFileAndCheck(url){//读取文件路径，判断是否为有效题库，如果有效则导入各项设置
        //获取文件路径
        let temp_filePath = url;
        filePath.text = temp_filePath.slice(8);//去除了"file:///"头
        //保存文件路径
        let folderPath = getFolderPath(temp_filePath);//需要包含"file:///"头
        settingsMain.setValue("importFoldPath",folderPath);
        //设置后台的m_excelFileName变量
        serviceBackend.setExcelFileName(filePath.text);
        var ret = serviceBackend.readItemBankMsg(sw_needSore.position);
        if(!ret){
            //读取失败，则将题库信息清零
            bt_printTestPaper.enabled = false;
            bt_testPaperSetClear.enabled =false;
            importSucessed = false;
            //清空试卷默认标题
            paperTitle.text = "";
            filePath.text = "";
        }else{
            bt_printTestPaper.enabled = true;
            bt_testPaperSetClear.enabled =true;
            importSucessed = true;
            //生成试卷默认标题
            paperTitle.text = getFileName(filePath.text)+"理论试卷";
            tableView.Layout.preferredHeight = TableModel.rowCount()*defaultRowHeight;
            updateZuJuanXinxi();
        }
    }

    function openFileAccept(){
        readFileAndCheck(myLoader.item.fileUrl.toString());
        //取消信号连接，释放资源
        myLoader.item.onAccepted.disconnect(openFileAccept);
        myLoader.setSource("");

    }
    //通过文件路径，读取文件名
    function getFileName(filePath){
        let temp_array = filePath.split('/');
        let temp_string = temp_array[temp_array.length-1];
        let lastDotIndex = temp_string.lastIndexOf('.');//查找最后一个.的位置
        let fileName = temp_string.substring(0,lastDotIndex);
//        let fileName = temp_string.split('.')[0];
        return fileName;
    }
    //获取文件夹路径
    function getFolderPath(filePath){
        let temp_array = filePath.split('/');
        //获取带后缀的文件名
        let tempName = temp_array[temp_array.length-1];
        return filePath.slice(0,filePath.length - tempName.length -1);
    }

    //更新组卷信息、
    function updateZuJuanXinxi(){
        var temp = serviceBackend.getFenzhi();
        txt_zuJuanXinXi.text = "本试卷共"+temp[0]+"题，总分值"+temp[1]+"分";
    }
    //检查组卷信息正确性
    function checkZuJuan(){
        //通过txt_errorMsg.text,txt_warningMsg.text,设置错误、警告信息
        //通过hasError,hasWarning，确定组题设置中的错误
        let i = 0;//提示信息序号
        let errorMsg ="";//临时保存错误信息
        let warningMsg = "";//临时保存警告信息
        hasError = false;
        hasWarning = false;
        var msg =serviceBackend.checkZuJuan(paperTitle.text);
        if(msg[0] !== ""){
            hasError = true;
            txt_errorMsg.text = msg[0];
        }
        if(msg[1] !== ""){
            hasWarning = true;
            txt_warningMsg.text = msg[1];
        }
    }
    //打印试卷
    function printTestPaper(){
        //获取试卷标题
        serviceBackend.getTestPaperTittle(paperTitle.text);
        //获取页面设置
        var tempSettingsMap = pageSettingMap;
        tempSettingsMap["双面"] = rb_doubleSide.checked;
        tempSettingsMap["侧面封装"] = rb_side.checked;
        tempSettingsMap["纸张"] = cb_pageSize.currentText;
        serviceBackend.readPageSetting(tempSettingsMap);
        //启动打印程序
        var ret = serviceBackend.printTestPaper(rb_docx.checked);
        if(ret){
            messageBox.close();
            messageBox.text = "试卷生成成功！";
            messageBox.style = "sucess";
            if(!timer.running){
                timer.start();
            }
            else{
                timer.stop();
                timer.start();
            }
            messageBox.open();
        }else{
            messageBox.close();
            messageBox.text = serviceBackend.getError();
            messageBox.style = "danger";
            messageBox.open();
        }

    }

    //读取保存的页面设置信息,更新到pageSettingMap中
    function readPageSetting(){
        //将设置字符串信息转化为设置对象
        var tempSetString = settingsPage.value("pageSet");

        var tempObj;
        if(tempSetString === undefined){
            //程序在初始情况下是没有pageSet值的，所以会出现undefined的错误
            tempObj = pageSettingMap;
        }
        else{
            if(tempSetString.length ===0 ){
                //有内容，但为空
                tempObj = pageSettingMap;
            }else {
                //读取到设置字符串，转化为对象
                tempObj = JSON.parse(tempSetString);//把字符串转为对象
                if(tempObj["上边距"] === undefined){//内部数据无效,使用默认设置
                    tempObj = pageSettingMap;
                }
            }

        }
        return tempObj;
    }



    //设置一个标题
    header: Label{
        font.family: "方正小标宋简体"
        font.pointSize: 25
        font.bold: true
        text:qsTr("试卷自动生成系统")
        color:"White"
        horizontalAlignment: Qt.AlignHCenter
        topPadding: 20
        bottomPadding: 20
        background: Rectangle{
            color: backGroundColor
        }
    }
    //主界面布局
    Flickable{
        id:flickable
        anchors.fill: parent
        topMargin: 10
        contentHeight: columnLayout.height
        ColumnLayout{
            id:columnLayout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 10
            //导入题库
            //做一个白色背景
            Rectangle{
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: ly1.height+10
                color: "white"
                radius: 5
                GridLayout{
                    id:ly1
                    width: parent.width
                    columns: 2
                    Label{
                        Layout.topMargin: 10
                        Layout.leftMargin: 10
                        Layout.alignment: Qt.AlignLeft
                        Layout.columnSpan :2
                        font.pointSize: 16
                        text:qsTr("导入题库")
                    }
                    TextField{
                        id:filePath
                        Layout.leftMargin: 10
                        Layout.fillWidth: true
                        font.pointSize: 12
                        placeholderText: "请导入题库"
                    }
                    Button{
                        Layout.rightMargin: 10
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("导入题库")
                        Material.background: Material.Green
                        Material.foreground: "white"
                        onClicked: {
                            myLoader.sourceComponent = openFileDialog;
                            var importFoldPath = settingsMain.value("importFoldPath");
                            if(importFoldPath === undefined || importFoldPath==="")
                                myLoader.item.folder = "file:///c:/"
                            else
                                myLoader.item.folder = settingsMain.value("importFoldPath");
                            myLoader.item.open();
                            myLoader.item.onAccepted.connect(openFileAccept);
                        }
                    }
                }
                DropArea{
                    anchors.fill: parent
                    onDropped: {
                        var url = drop.urls[0];
                        readFileAndCheck(url);
                    }
                }
            }
            //出题设置的界面
            //试卷标题
            Rectangle{
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: ly3.height+10
                color: "white"
                radius: 5

                ColumnLayout{
                    id:ly3
                    width: parent.width
                    Label{
                        Layout.topMargin: 10
                        Layout.leftMargin: 10
                        Layout.alignment: Qt.AlignLeft
                        font.pointSize: 16
                        text:qsTr("试卷标题")
                    }
                    TextField{
                        id:paperTitle
                        Layout.leftMargin: 10
                        Layout.fillWidth: true
                        Layout.rightMargin: 10
                        font.pointSize: 12
                        selectByMouse: true
                        placeholderText:qsTr( "试卷标题")
                    }
                }
            }
            //组题设置
            Rectangle{
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: ly_z.height+10
                color: "white"
                radius: 5
                clip: true
                ColumnLayout{
                    id:ly_z
                    width: parent.width
                    spacing: 0
                    RowLayout{
                        width: parent.width
                        Switch{
                            id:sw_needSore
                            text: qsTr("使用上次出题设置")
                            checked: true
                            Layout.alignment: Qt.AlignLeft
                            font.pointSize: 14
                            font.bold: true
                        }
                        Item {
                            Layout.preferredWidth: 100
                        }
                        Button{
                            id:bt_testPaperSetClear
                            Layout.alignment: Qt.AlignRight
                            Layout.preferredHeight: 50
                            Material.background: Material.Green
                            Material.foreground: "white"
                            enabled: false
                            font.pointSize: 10
                            text: qsTr("清空设置")
                            onClicked: {
                                serviceBackend.testPaperSetClear();
                                updateZuJuanXinxi();
                            }
                        }
                    }


                    //行表头
                    ListView{
                        id: headerRow
                        z:3
                        orientation: ListView.Horizontal
                        Layout.fillWidth: true
                        height: defaultRowHeight
                        spacing: 0
                        model: TableModel.columnCount()
                        contentX: tableView.contentX
                        interactive: false
                        delegate: Rectangle{
                            id:headerItem
                            width: tableView.columnWidthProvider(model.index)
                            height: parent.height
//                            border.color: Qt.darker("lightgray",1.1)
                            border.color :"lightgray"
                            border.width: 1
                            Label {
                                text: TableModel.headerData(index, Qt.Horizontal)
                                font.pointSize: 12
                                font.family: "黑体"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                anchors.fill: parent
                            }
                            //表格调整线
                            Rectangle {
                                id: resizeHandle
                                color: "transparent"
                                height: parent.height
                                anchors.right: parent.right
                                width: 5
                                //表格尺寸可调整
                                MouseArea{
                                    id:headerWidthArea
                                    anchors.fill: parent
                                    drag.target: parent
                                    drag.axis: Drag.XAxis//允许水平拖动
                                    hoverEnabled: true
                                    cursorShape: Qt.SplitHCursor
                                    onMouseXChanged: {
                                        if (drag.active) {
                                            let newWidth = headerItem.width + mouseX;
                                            if (newWidth >= 50) {
                                                headerItem.width = newWidth;
                                            }
                                            else {
                                                headerItem.width = 50;
                                            }
                                            settingsMain.columnWidths[index] = headerItem.width;
                                            settingsMain.columnWidths = settingsMain.columnWidths;
                                            //刷新布局，这样宽度才会改变
                                            tableView.forceLayout();
                                        }
                                    }
                                }
                            }
                        }

                    }
                    TableView {
                        id: tableView
                        enabled: importSucessed
                        Layout.fillWidth: true
                        Layout.preferredHeight: TableModel.rowCount()*defaultRowHeight
                        interactive: false
                        model: TableModel
                        property int dragStartRow: -1
                        property int currentHoverRow: -1
                        // 列宽与表头对齐
                        columnWidthProvider: function (column) {
                            return settingsMain.columnWidths[column];
                        }
                        rowHeightProvider: function(){return defaultRowHeight}

                        // 单元格代理
                        delegate: Rectangle {
                            id: delegate
                            color: {
                                if (tableView.currentHoverRow === row)
                                    return hoverColor;
                                else
                                   return "white";
                            }
                            border.color: "#b0bec5"


                            // 选中状态
                            property int selectedRow: -1

                            Loader{
                                anchors.fill: parent
                                sourceComponent:{
                                    switch (column){
                                    case 2 :
                                        return editIntDelegate;
                                    case 3 :
                                        return editFloatDelegate;
                                    default:
                                        return readOnlyDelegate;
                                    }
                                }
                                onLoaded: {
                                    //更行行列号
                                    item.row = row;
                                    item.column = column;
                                    //绑定属性
                                    item.text = Qt.binding(function() {
//                                        if(column == 3)
//                                            return  display.toFixed(1)
                                        return display;
                                    })
                                    item.backgroundcolor = Qt.binding(function() {
                                        if(tableView.currentHoverRow === row)
                                            return hoverColor;
                                        else
                                            return "white"
                                    })
                                    //出题数量超过总题数，则标红色提示
                                    if(column == 2){
                                        item.color = Qt.binding(function() {
                                            if(parseInt(item.text) > parseInt(TableModel.data(TableModel.index(row, 1), Qt.DisplayRole)))
                                                return "red";
                                            else
                                                return "black"
                                        })
                                    }
                                }
                            }

                            //插入位置线
                            Rectangle{
                                id:rg_line
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: {
                                    if(tableView.currentHoverRow === row&& tableView.currentHoverRow < tableView.dragStartRow)
                                        return parent.top;
                                    else
                                        return undefined;
                                }
                                anchors.bottom: {if(tableView.currentHoverRow === row&& tableView.currentHoverRow > tableView.dragStartRow)
                                        return parent.bottom;
                                    else
                                        return undefined;
                                }

                                height: 3
                                color: {
                                    if(tableView.currentHoverRow === row&& tableView.currentHoverRow !== tableView.dragStartRow)
                                        return hoverLineColor;
                                    else
                                        return "transparent";
                                }

                            }
                            // 鼠标区域处理拖拽
                            MouseArea {
                                anchors.fill: parent
                                drag.target: dragItem
                                drag.axis:Drag.YAxis
                                enabled: column == 0 ? true :false
                                onPressed: {
                                    tableView.dragStartRow = row
                                    dragItem.x = delegate.x
                                    dragItem.y = delegate.y
                                    dragItem.rowData = [
                                                TableModel.data(TableModel.index(row, 0), Qt.DisplayRole),
                                                TableModel.data(TableModel.index(row, 1), Qt.DisplayRole),
                                                TableModel.data(TableModel.index(row, 2), Qt.DisplayRole),
                                                TableModel.data(TableModel.index(row, 3), Qt.DisplayRole)
                                            ]
                                    dragItem.visible = true
                                    selectedRow = row
                                }
                                onPositionChanged: {
                                    if (drag.active) {
                                        let pos = mapToItem(tableView.contentItem, mouse.x, mouse.y)
                                        // 调试输出坐标值和类型
                                        let idx = Math.floor((pos.y - tableView.contentY) / defaultRowHeight);
                                        if (idx !== -1) {
                                            tableView.currentHoverRow = idx
                                        }
                                    }
                                }
                                onReleased: {
                                    dragItem.visible = false
                                    selectedRow = -1
                                    if (tableView.currentHoverRow !== -1 && tableView.dragStartRow !== tableView.currentHoverRow) {
                                        // 调用C++模型移动行
                                        TableModel.moveRow(tableView.dragStartRow, tableView.currentHoverRow)
                                    }
                                    tableView.dragStartRow = -1
                                    tableView.currentHoverRow = -1
                                }
                            }

                        }

                        // 拖拽代理项
                        Rectangle {
                            id: dragItem
                            z:10
                            visible: false
                            width: tableView.contentItem.width
                            height: defaultRowHeight
                            color: "#b3e5fc"
                            border.color: "#4fc3f7"
                            radius: 2
                            opacity: 0.8
                            parent: tableView.contentItem

                            property var rowData: ["题型","0","0","0"]

                            RowLayout {
                                anchors.fill: parent
                                spacing:0
                                Text { text: dragItem.rowData[0]; Layout.preferredWidth: settingsMain.columnWidths[0] ;font.pointSize: 12;verticalAlignment: Text.AlignVCenter;horizontalAlignment: Text.AlignHCenter}
                                Text { text: dragItem.rowData[1]; Layout.preferredWidth: settingsMain.columnWidths[1] ;font.pointSize: 12;verticalAlignment: Text.AlignVCenter;horizontalAlignment: Text.AlignHCenter}
                                Text { text: dragItem.rowData[2]; Layout.preferredWidth: settingsMain.columnWidths[2] ;font.pointSize: 12;verticalAlignment: Text.AlignVCenter;horizontalAlignment: Text.AlignHCenter}
                                Text { text: dragItem.rowData[3]; Layout.preferredWidth: settingsMain.columnWidths[3] ;font.pointSize: 12;verticalAlignment: Text.AlignVCenter;horizontalAlignment: Text.AlignHCenter}
                            }

                            Drag.active: true
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2
                        }
                    }
                    //可编辑整数模型
                    Component{
                        id:editIntDelegate
                        TextField{
                            id:editDelegateText
                            property alias fontcolor: editDelegateText.color
                            property alias backgroundcolor: editDelegateBackground.color
                            property int row: 0
                            property int column: 0
                            bottomPadding: 0
                            leftPadding: 0
                            rightPadding: 0
                            topPadding: 0
                            font.pointSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment:Text.AlignVCenter
                            selectByMouse: true
                            //要求输入0-100之间的浮点数，小数点后保留一位
                            //如果是<10的浮点，0.0-9.9之间的数字;如果是>=10,<100的数字，10.0-99.9;允许输入100或100.0
//                                    validator: column === 2 ? IntValidator{bottom: 0;} :RegExpValidator{regExp: /\d(\.\d)?|[1-9][0-9](\.\d)?|100(\.0)?/}
                            validator:IntValidator{bottom: 0;}
                            placeholderText: qsTr("数量")
                            onTextEdited:{
                                console.log("开始更新组卷信息")
                                TableModel.setData(row,column,parseInt(text));
                                updateZuJuanXinxi();
                            }
                            background: Rectangle{
                                id:editDelegateBackground
                                border.color:"#cccccc"
                            }
                        }
                    }
                    //可编辑浮点数模型
                    Component{
                        id:editFloatDelegate
                        TextField{
                            id:editDelegateText
                            property alias fontcolor: editDelegateText.color
                            property alias backgroundcolor: editDelegateBackground.color
                            property int row: 0
                            property int column: 0
                            bottomPadding: 0
                            leftPadding: 0
                            rightPadding: 0
                            topPadding: 0
                            font.pointSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment:Text.AlignVCenter
                            selectByMouse: true
                            //要求输入0-100之间的浮点数，小数点后保留一位
                            //如果是<10的浮点，0.0-9.9之间的数字;如果是>=10,<100的数字，10.0-99.9;允许输入100或100.0
//                                    validator: column === 2 ? IntValidator{bottom: 0;} :RegExpValidator{regExp: /\d(\.\d)?|[1-9][0-9](\.\d)?|100(\.0)?/}
                            validator:RegExpValidator{regExp: /\d(\.\d)?|[1-9][0-9](\.\d)?|100(\.0)?/}
                            placeholderText: qsTr("分值")
                            onTextEdited:{
                                TableModel.setData(row,column,parseFloat(text));
                                updateZuJuanXinxi();
                            }
                            background: Rectangle{
                                id:editDelegateBackground
                                border.color:"#cccccc"
                            }
                        }
                    }
                    //只读模型
                    Component{
                        id:readOnlyDelegate
                        Text {
                            id:readOnlyText
                            property alias  fontcolor: readOnlyText.color
                            property color backgroundcolor //没用，只是为了接口统一
                            property int row: 0
                            property int column: 0
                            font.pointSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            //组卷情况
            Rectangle{
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: ly5.height+10
                color: "white"
                radius: 5
                ColumnLayout{
                    id:ly5
                    width: parent.width
                    Label{
                        Layout.topMargin: 10
                        Layout.leftMargin: 10
                        Layout.alignment: Qt.AlignLeft
                        font.pointSize: 16
                        text:qsTr("组卷情况")
                    }
                    TextField{
                        id:txt_zuJuanXinXi
                        Layout.leftMargin: 10
                        Layout.fillWidth: true
                        Layout.rightMargin: 10
                        font.pointSize: 12
                        placeholderText: qsTr("本试卷共XX题，总分值XX分")
                    }
                }
            }

            //试卷页面设置
            Rectangle{
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: ly6.height+10
                color: "white"
                radius: 5
                GridLayout{
                    id:ly6
                    width: parent.width
                    columns: 4
                    Label{
                        Layout.topMargin: 10
                        Layout.leftMargin: 10
                        Layout.columnSpan: 1
                        font.pointSize: 16
                        text:qsTr("页面设置")
                    }
                    Button{
                        Layout.alignment: Qt.AlignLeft
                        Layout.topMargin: 10
                        Layout.rightMargin: 10
                        Layout.columnSpan: 3
                        text:qsTr( "高级设置")
                        Material.background: Material.Green
                        Material.foreground: "white"
                        onClicked: {
                            function getPageSettings(){
                                //保存设置信息到文件
                                pageSettingMap = myLoader.item.pageSettingMap;
                                var jsonString = JSON.stringify(pageSettingMap);//把对象转为字符串
                                //                                console.log("获取值",jsonString);
                                settingsPage.setValue("pageSet",jsonString);
                                myLoader.item.onAccepted.disconnect(getPageSettings);
                                myLoader.item.onError.disconnect(setError);
                                myLoader.item.onSucess.disconnect(setSucess);
                                myLoader.source = "";
                            }
                            //显示错误消息
                            function setError(erorMsg){
                                messageBox.close();//如果已经打开就先关闭
                                messageBox.text = erorMsg;
                                messageBox.style = "danger";
                                messageBox.open();
                            }
                            //显示成功消息
                            function setSucess(){
                                messageBox.close();//如果已经打开就先关闭
                                messageBox.text = "页面设置成功！";
                                messageBox.style = "sucess";
                                if(!timer.running){
                                    timer.start();
                                }
                                else{
                                    timer.stop();
                                    timer.start();
                                }
                                messageBox.open();
                            }

                            //显示设置对话框
                            myLoader.sourceComponent = dg_pageSetting;
                            pageSettingMap = readPageSetting();
                            myLoader.item.pageSettingMap = pageSettingMap;
                            myLoader.item.paperSize = cb_pageSize.currentText;
                            myLoader.item.isZhangDing = rb_side.checked;
                            myLoader.item.ppiEnabled = !rb_docx.checked;
                            myLoader.item.open();
                            myLoader.item.onAccepted.connect(getPageSettings);
                            myLoader.item.onError.connect(setError);
                            myLoader.item.onSucess.connect(setSucess);
                        }
                    }

                    DashLineHShape{
                        id:root
                        Layout.preferredHeight: 5
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.columnSpan :4
                        Layout.fillWidth: true
                    }

                    RadioButton{
                        id:rb_doubleSide
                        Layout.leftMargin: 10
                        Layout.columnSpan :1
                        font.pointSize: 12
                        checked: false
                        enabled: !rb_docx.checked
                        autoExclusive:false
                        text: qsTr("双面打印")
                    }
                    RadioButton{
                        id:rb_side
                        Layout.leftMargin: 10
                        Layout.columnSpan :1
                        font.pointSize: 12
                        checked: false
                        autoExclusive:false
                        enabled: !rb_docx.checked
                        text: qsTr("考生信息在侧面")
                    }
                    Label{
                        Layout.alignment: Qt.AlignRight
                        Layout.columnSpan: 1
                        font.pointSize: 12
                        text:qsTr("纸张大小")
                    }
                    ComboBox{
                        id:cb_pageSize
                        Layout.rightMargin: 10
                        model: ["A4","A3"]
                        currentIndex: 0
                    }
                    
                }
            }

            //输出设置
            Rectangle{
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                implicitHeight: ly7.height+10
                color: "white"
                radius: 5
                GridLayout{
                    id:ly7
                    width: parent.width
                    columns: 4
                    Label{
                        Layout.topMargin: 10
                        Layout.leftMargin: 10
                        Layout.columnSpan: 1
                        font.pointSize: 16
                        text:qsTr("输出格式")
                    }
                    DashLineHShape{
                        Layout.preferredHeight: 5
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.columnSpan :4
                        Layout.fillWidth: true
                    }
                    RadioButton{
                        id:rb_pdf
                        Layout.leftMargin: 10
                        Layout.columnSpan :1
                        font.pointSize: 12
                        checked: false
                        autoExclusive: true
                        text: qsTr("PDF")
                    }
                    RadioButton{
                        id:rb_docx
                        Layout.leftMargin: 10
                        Layout.columnSpan :1
                        font.pointSize: 12
                        checked: true
                        autoExclusive: true
                        text: qsTr("DOCX")
                    }
                }
            }


            //生成试卷按钮
            Button{
                id:bt_printTestPaper
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Layout.bottomMargin: 20
                Layout.preferredHeight: 60
                font.pointSize: 16
                text: qsTr("生成试卷")
                Material.background: Material.Green
                Material.foreground: "white"
                enabled: false
                onClicked: {
                    //检查组卷信息的正确性
                    checkZuJuan();
                    if(hasError || hasWarning){
                        dg_confirm.open();
                    }else
                        printTestPaper();
                }
            }

        }
        ScrollBar.vertical: ScrollBar { }
    }
    Loader{id:myLoader;anchors.fill: parent}
    Component{
        id:openFileDialog
        FileDialog {
            title: qsTr("选择题库文件")
            folder: "file:///F:/temp/"
            nameFilters: [ "Excel 文件 (*.xls *.xlsx)", "All files (*)" ]
        }
    }

    //保存设置信息
    Settings{
        id:settingsMain
        //页面设置
        property alias pageSize: cb_pageSize.currentIndex //纸张
        property alias doubleSide: rb_doubleSide.checked //是否双面
        property alias side: rb_side.checked //考生信息是否在侧面
        //导入文件的目录
        property var importFoldPath
        //保存列宽
        property var columnWidths: [145, 145, 145,145] // 默认列宽
        //载入上次设置
        property alias needSore: sw_needSore.checked

        fileName : appDir + "\/testPageSet.ini"

    }
    //保存高级页面设置信息
    Settings{
        id:settingsPage
        category: "pageSetting"
        fileName: appDir+"\/testPageSet.ini"
        Component.onCompleted:{
            pageSettingMap = readPageSetting();
        }
    }
    //消息框
    MessageBox{
        id:messageBox
        anchors.top: parent.top
        implicitWidth: parent.width-10
        anchors.horizontalCenter: parent.horizontalCenter
        visible: false
        Timer {//用于定时关闭成功信息
            id:timer
            interval: 3000
            running: false
            repeat: false
            onTriggered:
                messageBox.close();
        }
    }
    //关于
    Dialog{
        id:dg_about
        //设置位置
        anchors.centerIn: parent
        //        width : parent.width*1/2
        Material.background: "white"
        modal: true
        closePolicy: Popup.NoAutoClose //只能手动关闭
        header: Label {
            leftPadding: 10
            topPadding: 10
            bottomPadding: 10
            font.family: Fonts.solidIcons
            font.pointSize: 18
            color: "#a94442"
            text:"\uf071"
            background: Rectangle{
                color: "#f8f8ff"
            }
        }
        contentItem:ColumnLayout{
            spacing: 10
            Label{
                text: qsTr("版权所用")
                font.bold: true
                font.pointSize: 14
            }
            Text {
                Layout.fillWidth: true
                font.pointSize: 12
                wrapMode: Text.Wrap
                text: qsTr("涉及部分商用库，请勿用于商业")
            }
            DashLineH{
                Layout.fillWidth: true
            }
            Label{
                text: qsTr("使用说明：")
                font.pointSize: 14
                font.bold: true
            }
            Text {
                Layout.fillWidth: true
                font.pointSize: 12
                wrapMode: Text.Wrap
                text: qsTr("1.必须使用Excel作为题库\n\r2.题库所在工作表名称必须为“题库”\n\r3.设置成横向页面后，如果输出为PDF文件，则自动分2栏显示；如果选择Docx文件则不分栏\n\r4.由于Docx库的原因，如果选择输出为docx文件暂时不支持将考生信息输出至侧面、双面等功能，用户可以使用Office软件自行更改\n\r5.拖动表格题型名称可以调整题型输出的顺序")
            }

        }
        footer: RowLayout{
            Item{
                Layout.fillWidth: true
            }
            DialogButtonBox {
                Button {
                    Material.background: Material.Green
                    Material.foreground: "white"
                    text: qsTr("确定")
                    DialogButtonBox.buttonRole: DialogButtonBox.YesRole
                    visible: true
                    onClicked: {
                        dg_about.close();
                    }
                }
            }
        }
        visible: false
    }
    Shortcut{
        autoRepeat: false
        context: Qt.ApplicationShortcut
        sequence:"F1"
        onActivated: {
            dg_about.open();
        }

    }

    //确认对话框
    Dialog{
        id:dg_confirm
        //设置位置
        anchors.centerIn: parent
        width : parent.width*2/3
        Material.background: "white"
        modal: true
        closePolicy: Popup.NoAutoClose //只能手动关闭
        header: Label {
            leftPadding: 10
            topPadding: 10
            bottomPadding: 10
            font.family: Fonts.solidIcons
            font.pointSize: 18
            color: "#a94442"
            text:"\uf071"
            background: Rectangle{
                color: "#f8f8ff"
            }
        }
        contentItem:ColumnLayout{
            spacing: 5
            Label{
                text: "警告:"
                font.bold: true
                font.pointSize: 14
                visible: hasWarning
            }
            Text {
                id: txt_warningMsg
                Layout.fillWidth: true
                visible: hasWarning
                font.pointSize: 12
                wrapMode: Text.Wrap
                text: qsTr("警告信息")
            }
            DashLineH{
                Layout.fillWidth: true //必须设置，否则不显示
                visible: hasWarning && hasError
            }
            Label{
                text: qsTr("组题设置存在致命错误:")
                font.pointSize: 14
                font.bold: true
                visible: hasError
            }
            Text {
                id: txt_errorMsg
                Layout.fillWidth: true
                font.pointSize: 12
                wrapMode: Text.Wrap
                visible: hasError
                text: qsTr("错误信息")
            }


        }
        footer: RowLayout{
            Item{
                Layout.fillWidth: true
            }
            DialogButtonBox {
                Button {
                    Material.background: Material.Green
                    Material.foreground: "white"
                    text: qsTr("仍然打印")
                    DialogButtonBox.buttonRole: DialogButtonBox.YesRole
                    visible: !hasError //如果存在严重错误就不能打印
                    onClicked: {
                        printTestPaper();
                        dg_confirm.close();
                    }
                }
            }
            DialogButtonBox {
                Button {
                    Material.background: Material.Green
                    Material.foreground: "white"
                    text: qsTr("取消")
                    DialogButtonBox.buttonRole:  DialogButtonBox.NoRole
                    onClicked: {
                        dg_confirm.close();
                    }
                }
            }
        }

        visible: false
    }

    //页面设置对话框
    Component{
        id: dg_pageSetting
        PageSetting{
            anchors.centerIn: parent
            implicitWidth: 500
        }
    }

}

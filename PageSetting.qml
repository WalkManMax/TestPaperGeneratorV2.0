import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.14

Dialog{
    //设置位置
    id:root
    property alias ppiEnabled: in_ppi.enabled
    property var fontSize: 11 //字号
     //页面设置信息
    property var pageSettingMap:{"上边距":38,"下边距":35,"左边距":27,"右边距":27,
        "主标题字体":"方正小标宋简体","主标题字号":22,
        "一级标题字体":"黑体","一级标题字号":16,
        "正文字体":"仿宋_GB2312","正文字号":16,
        "考生信息字体":"仿宋_GB2312","考生信息字号":14,
        "行间距":18,"分辨率":300,"横向页面":false
    }
    //获取纸张大小，用于判断页边距设置是否存在错误
    property var paperSize: "A4"
    //获取考生信息位置，左边距设置是否正确
    property bool isZhangDing: false
    //获取系统字体库
    property var fontFamilies: Qt.fontFamilies().sort(function(a,b){
        let aCode = a.charCodeAt(0);
        let bCode = b.charCodeAt(0);
        if((aCode>= 0x4e00 && aCode <=0x9fff)&&!(bCode>= 0x4e00 && bCode <=0x9fff)){
            return -1;//a是中文B不是
        }else if (!(aCode>= 0x4e00 && aCode <=0x9fff)&&(bCode>= 0x4e00 && bCode <=0x9fff)){
            //b是中文a不是
            return  1;
        }else{
            //相同类型
            return a.localeCompare(b);
        }
    })
    //信号区
    signal error(var erorMsg);
    signal sucess();
    //函数区

    onPageSettingMapChanged: {
//        console.log("字体变化",pageSettingMap["一级标题字体"]);
        let tempIndex = fontFamilies.indexOf(pageSettingMap["主标题字体"]);
        if(tempIndex !== -1)
            cb_mainFont.currentIndex = tempIndex;
        else
            cb_mainFont.currentIndex = 0;

        tempIndex = fontFamilies.indexOf(pageSettingMap["一级标题字体"]);
        if(tempIndex !== -1)
            cb_oneFont.currentIndex = tempIndex;
        else
            cb_oneFont.currentIndex = 0;

        tempIndex = fontFamilies.indexOf(pageSettingMap["正文字体"]);
        if(tempIndex !== -1)
            cb_contextFont.currentIndex = tempIndex;
        else
            cb_contextFont.currentIndex = 0;

        tempIndex = fontFamilies.indexOf(pageSettingMap["考生信息字体"]);
        if(tempIndex !== -1)
            cb_ksFont.currentIndex = tempIndex;
        else
            cb_ksFont.currentIndex = 0;
    }

    Material.background: "white"
    modal: true
    closePolicy: Popup.NoAutoClose //只能手动关闭
    clip: true
    header: Label {
        leftPadding: 10
        topPadding: 10
        bottomPadding: 10
        font.pointSize: 16
        text:qsTr("页面设置")
        background: Rectangle{
            color: "#f8f8ff"
        }
    }
    contentItem:ColumnLayout{
        RowLayout{
            Text{
                font.pointSize: root.fontSize
                font.bold: true
                text: qsTr("页边距")
            }
            DashLineH{
                Layout.fillWidth: true
            }
        }
        RowLayout{//设置上下
            Layout.alignment: Qt.AlignHCenter
            Text{
                font.pointSize: root.fontSize
                text: qsTr("上：")
            }
            TextField{
                id:in_top
                Layout.preferredWidth: 50
                selectByMouse: true
                font.pointSize: root.fontSize
                horizontalAlignment: Qt.AlignHCenter
                bottomPadding: 8
                 //将输入数据限制为0-999.9的浮点数
                validator: DoubleValidator{bottom:0;top:999.0;decimals:1;notation:DoubleValidator.StandardNotation}
                text: pageSettingMap["上边距"] === undefined ? "38" : pageSettingMap["上边距"]
            }
            Text{
                font.pointSize: root.fontSize
                text: qsTr("毫米")
            }
            Item{
               Layout.preferredWidth: 50
            }
            Text{
                font.pointSize: root.fontSize
                text: qsTr("下：")
            }
            TextField{
                id:in_bottom
                Layout.preferredWidth: 50
                font.pointSize: root.fontSize
                selectByMouse: true
                horizontalAlignment: Qt.AlignHCenter
                bottomPadding: 8
                //将输入数据限制为0-999.9的浮点数
                validator: DoubleValidator{bottom:0;top:999.0;decimals:1;notation:DoubleValidator.StandardNotation}
                text: pageSettingMap["下边距"] === undefined ? "27" : pageSettingMap["下边距"]
            }
            Text{
                font.pointSize: root.fontSize
                text: qsTr("毫米")
            }
        }
        RowLayout{//设置左右
            Layout.alignment: Qt.AlignHCenter
            Text{
                font.pointSize: root.fontSize
                text: qsTr("左：")
            }
            TextField{
                id:in_left
                Layout.preferredWidth: 50
                font.pointSize: root.fontSize
                selectByMouse: true
                horizontalAlignment: Qt.AlignHCenter
                bottomPadding: 8
                //将输入数据限制为0-999.9的浮点数
                validator: DoubleValidator{bottom:0;top:999.0;decimals:1;notation:DoubleValidator.StandardNotation}
                text: pageSettingMap["左边距"] === undefined ? "27" : pageSettingMap["左边距"]
            }
            Text{
                font.pointSize: root.fontSize
                text: qsTr("毫米")
            }
            Item{
               Layout.preferredWidth: 50
            }
            Text{
                font.pointSize: root.fontSize
                text: qsTr("右：")
            }
            TextField{
                id:in_right
                Layout.preferredWidth: 50
                font.pointSize: root.fontSize
                selectByMouse: true
                horizontalAlignment: Qt.AlignHCenter
                bottomPadding: 8
                //将输入数据限制为0-999.9的浮点数
                validator: DoubleValidator{bottom:0;top:999.0;decimals:1;notation:DoubleValidator.StandardNotation}
                text: pageSettingMap["右边距"] === undefined ? "27" : pageSettingMap["右边距"]
            }
            Text{
                font.pointSize: root.fontSize
                text: qsTr("毫米")
            }
        }
        RowLayout{
            Text{
                font.pointSize: root.fontSize
                font.bold: true
                text: qsTr("字体设置")
            }
            DashLineH{
                Layout.fillWidth: true
            }
        }
        //字体设置
        GridLayout{
            Layout.alignment: Qt.AlignHCenter
            columns: 6
            rows: 4
            Text{
                font.pointSize: root.fontSize
                text: qsTr("主标题字体：")
                Layout.columnSpan: 1
            }
            EditableComboBox{
                id:cb_mainFont
                Layout.preferredWidth: 150
                Layout.columnSpan: 1
                font.pointSize: root.fontSize
                model: fontFamilies
                currentIndex: {//如果有方正小标宋简体就用，没有就用第一个字体
                    let tempIndex = fontFamilies.indexOf(pageSettingMap["主标题字体"]);
                    if(tempIndex !== -1)
                        return tempIndex;
                    else
                        return 0;
                }
            }
            Item{
                Layout.columnSpan: 1
                Layout.preferredWidth: 30
            }

            Text{
                font.pointSize: root.fontSize
                Layout.columnSpan: 1
                text: qsTr("字号：")
            }
            TextField{
                id:in_mainFont
                Layout.preferredWidth: 50
                Layout.columnSpan: 1
                font.pointSize: root.fontSize
                selectByMouse: true
                bottomPadding: 8
                text: pageSettingMap["主标题字号"] === undefined ? "22" : pageSettingMap["主标题字号"]
                horizontalAlignment: Qt.AlignHCenter
                //将输入数据限制为0-99.9的浮点数
               validator: DoubleValidator{bottom:0;top:99.0;decimals:1;notation:DoubleValidator.StandardNotation}
            }
            Text{
                font.pointSize: root.fontSize
                Layout.columnSpan: 1
                text: qsTr("磅")
            }
            //一级标题
            Text{
                font.pointSize: root.fontSize
                Layout.columnSpan: 1
                text: qsTr("一级标题字体：")
            }
            EditableComboBox{
                id:cb_oneFont
                Layout.preferredWidth: 150
                Layout.columnSpan: 1
                font.pointSize: root.fontSize
                model: fontFamilies
                currentIndex: {//如果有黑体就用，没有就用第一个字体
                    let tempIndex = fontFamilies.indexOf(pageSettingMap["一级标题字体"]);
                    if(tempIndex !== -1)
                        return tempIndex;
                    else
                        return 0;
                }
            }
            Item{
                Layout.columnSpan: 1
                Layout.preferredWidth: 30
            }
            Text{
                font.pointSize: root.fontSize
                Layout.columnSpan: 1
                text: qsTr("字号：")
            }
            TextField{
                id:in_oneFont
                Layout.preferredWidth: 50
                Layout.columnSpan: 1
                font.pointSize: root.fontSize
                selectByMouse: true
                bottomPadding: 8
                text: pageSettingMap["一级标题字号"] === undefined ? "16" : pageSettingMap["一级标题字号"]
                horizontalAlignment: Qt.AlignHCenter
                //将输入数据限制为0-99.9的浮点数
               validator: DoubleValidator{bottom:0;top:99.0;decimals:1;notation:DoubleValidator.StandardNotation}
            }
            Text{
                font.pointSize: root.fontSize
                Layout.columnSpan: 1
                text: qsTr("磅")
            }
            //正文字体
            Text{
                font.pointSize: root.fontSize
                Layout.columnSpan: 1
                text: qsTr("正文字体：")
            }
            EditableComboBox{
                id:cb_contextFont
                Layout.preferredWidth: 150
                Layout.columnSpan: 1
                font.pointSize: root.fontSize
                model: fontFamilies
                currentIndex: {
                    //如果有黑体就用，没有就用第一个字体
                    let tempIndex = model.indexOf(pageSettingMap["正文字体"]);
                    if(tempIndex !== -1)
                        return tempIndex;
                    else
                        return 0;
                }
            }
            Item{
                Layout.columnSpan: 1
                Layout.preferredWidth: 30
            }
            Text{
                font.pointSize: root.fontSize
                Layout.columnSpan: 1
                text: qsTr("字号：")
            }
            TextField{
                id:in_contextFont
                Layout.preferredWidth: 50
                Layout.columnSpan: 1
                font.pointSize: root.fontSize
                selectByMouse: true
                bottomPadding: 8
                text: pageSettingMap["正文字号"] === undefined ? "16" : pageSettingMap["正文字号"]
                horizontalAlignment: Qt.AlignHCenter
                //将输入数据限制为0-99.9的浮点数
               validator: DoubleValidator{bottom:0;top:99.0;decimals:1;notation:DoubleValidator.StandardNotation}
            }
            Text{
                font.pointSize: root.fontSize
                Layout.columnSpan: 1
                text: qsTr("磅")
            }
            //考生信息字体
            Text{
                font.pointSize: root.fontSize
                Layout.columnSpan: 1
                text: qsTr("考生信息字体：")
            }
            EditableComboBox{
                id:cb_ksFont
                Layout.preferredWidth: 150
                Layout.columnSpan: 1
                font.pointSize: root.fontSize
                model: fontFamilies
                currentIndex: {
                    //如果有黑体就用，没有就用第一个字体
                    let tempIndex = model.indexOf(pageSettingMap["考生信息字体"]);
                    if(tempIndex !== -1)
                        return tempIndex;
                    else
                        return 0;
                }
            }
            Item{
                Layout.columnSpan: 1
                Layout.preferredWidth: 30
            }
            Text{
                font.pointSize: root.fontSize
                Layout.columnSpan: 1
                text: qsTr("字号：")
            }
            TextField{
                id:in_ksFont
                Layout.preferredWidth: 50
                Layout.columnSpan: 1
                font.pointSize: root.fontSize
                selectByMouse: true
                bottomPadding: 8
                text: pageSettingMap["考生信息字号"] === undefined ? "14" : pageSettingMap["考生信息字号"]
                horizontalAlignment: Qt.AlignHCenter
                //将输入数据限制为0-99.9的浮点数
               validator: DoubleValidator{bottom:0;top:99.0;decimals:1;notation:DoubleValidator.StandardNotation}
            }
            Text{
                font.pointSize: root.fontSize
                Layout.columnSpan: 1
                text: qsTr("磅")
            }
        }
        //其他设置
        RowLayout{
            Text{
                font.pointSize: root.fontSize
                font.bold: true
                text: qsTr("其他设置")
            }
            DashLineH{
                Layout.fillWidth: true
            }
        }
        //行间距
        RowLayout{
            Layout.alignment: Qt.AlignHCenter
            Text{
                font.pointSize: root.fontSize
                text: qsTr("行间距：")
            }
            TextField{
                id:in_space
                Layout.preferredWidth: 50
                selectByMouse: true
                font.pointSize: root.fontSize
                horizontalAlignment: Qt.AlignHCenter
                bottomPadding: 8
                 //将输入数据限制为0-99.9的浮点数
                validator: DoubleValidator{bottom:0;top:99.0;decimals:1;notation:DoubleValidator.StandardNotation}
                text: pageSettingMap["行间距"] === undefined ? "18" : pageSettingMap["行间距"]
            }
            Text{
                font.pointSize: root.fontSize
                text: qsTr("磅")
            }
            Item{
               Layout.preferredWidth: 30
            }
            Text{
                font.pointSize: root.fontSize
                text: qsTr("分辨率：")
            }
            TextField{
                id:in_ppi
                Layout.preferredWidth: 50
                font.pointSize: root.fontSize
                selectByMouse: true
                horizontalAlignment: Qt.AlignHCenter
                bottomPadding: 8
                //将输入数据限制为0-1000的整数
                validator: IntValidator{top:1000;bottom: 0}
                text: pageSettingMap["分辨率"] === undefined ? "300" : pageSettingMap["分辨率"]
            }
            Text{
                font.pointSize: root.fontSize
                text: qsTr("PPI")
            }
            Item{
               Layout.preferredWidth: 30
            }
            RadioButton {
                id:rb_landScape
                autoExclusive:false
                checked: pageSettingMap["横向页面"]=== undefined ? false :pageSettingMap["横向页面"] //默认非横向页面
                text: qsTr("横向页面")
                onClicked: {
                    //不能在onCheckedChanged中实现，因为除了人工修改，RadioButton初始化时会调用一次
//                    console.log("调用onCheckedChanged",checked);
                    //调整横向纵向时，要同步改变上下边距，上边距与左边距互换，下边距与右边距互换
                    let temp = in_top.text;
                    in_top.text = in_left.text;
                    in_left.text = temp;
                    temp = in_bottom.text;
                    in_bottom.text = in_right.text;
                    in_right.text = temp;
                }
            }
        }

        //填写说明
        RowLayout{
            Text{
                font.pointSize: root.fontSize
                font.bold: true
                text: qsTr("说明")
            }
            DashLineH {
                Layout.fillWidth: true
            }
        }
        RowLayout{
            Text{
                font.pointSize: root.fontSize
                text: qsTr("二号字体对应22磅，三号字体对应16磅")
            }
        }

    }
    footer: RowLayout {
        DialogButtonBox {
            Button {
                Material.background: Material.Green
                Material.foreground: "white"
                text: qsTr("默认设置")
                DialogButtonBox.buttonRole:  DialogButtonBox.ResetRole
                onClicked: {
                    pageSettingMap = {"上边距":38,"下边距":35,"左边距":27,"右边距":27,
                        "主标题字体":"方正小标宋简体","主标题字号":22,
                        "一级标题字体":"黑体","一级标题字号":16,
                        "正文字体":"仿宋_GB2312","正文字号":16,
                        "考生信息字体":"仿宋_GB2312","考生信息字号":14,
                        "行间距":18,"分辨率":300,"横向页面":false
                    }
                    //手动写回去，原来的绑定可能已经失效
                    in_top.text = pageSettingMap["上边距"];
                    in_bottom.text = pageSettingMap["下边距"] ;
                    in_left.text=pageSettingMap["左边距"];
                    in_right.text = pageSettingMap["右边距"];
                    in_mainFont.text = pageSettingMap["主标题字号"];
                    in_oneFont.text = pageSettingMap["一级标题字号"];
                    in_contextFont.text = pageSettingMap["正文字号"];
                    in_ksFont.text = pageSettingMap["考生信息字号"];
                    in_space.text = pageSettingMap["行间距"];
                    in_ppi.text = pageSettingMap["分辨率"];
                    rb_landScape.checked =pageSettingMap["横向页面"];
                    cb_mainFont.currentIndex = fontFamilies.indexOf(pageSettingMap["主标题字体"]);
                    cb_oneFont.currentIndex = fontFamilies.indexOf(pageSettingMap["一级标题字体"]);
                    cb_contextFont.currentIndex = fontFamilies.indexOf(pageSettingMap["正文字体"]);
                    cb_ksFont.currentIndex = fontFamilies.indexOf(pageSettingMap["考生信息字体"]);
                }
            }
        }
        Item{
            Layout.fillWidth: true
        }

        DialogButtonBox {
            Button {
                Material.background: Material.Green
                Material.foreground: "white"
                text: qsTr("确定")
                DialogButtonBox.buttonRole: DialogButtonBox.YesRole
                onClicked: {
                    pageSettingMap["上边距"] = in_top.text;
                    pageSettingMap["下边距"] = in_bottom.text;
                    pageSettingMap["左边距"] = in_left.text;
                    pageSettingMap["右边距"] = in_right.text;
                    pageSettingMap["主标题字号"] = in_mainFont.text;
                    pageSettingMap["一级标题字号"] = in_oneFont.text;
                    pageSettingMap["正文字号"] = in_contextFont.text;
                    pageSettingMap["考生信息字号"] = in_ksFont.text;
                    pageSettingMap[""] = in_space.text;
                    pageSettingMap["分辨率"] = in_ppi.text;
                    pageSettingMap["横向页面"] = rb_landScape.checked;
                    //判断字体设置是否正确，确认是如果有错误就发出消息
                    var errorMsg="";
                    var i = 0;//序号
                    if(fontFamilies.indexOf(cb_mainFont.editedText) === -1){//判断用户输入的主标题字体是否存在
                        i +=1;
                        errorMsg = "    "+i +".您设置的主标题字体（"+cb_mainFont.editedText+"）不存在，将自动为你恢复为最近一次正确设置（"+cb_mainFont.currentText+"）;";
                    }
                    pageSettingMap["主标题字体"] = cb_mainFont.currentText;
                    cb_mainFont.editedText = cb_mainFont.currentText;

                    if(fontFamilies.indexOf(cb_oneFont.editedText) === -1){//判断用户输入的一级标题字体是否存在
                        i +=1;
                        if(i>1)//第二行开始要换行
                            errorMsg += "\n"
                        errorMsg +="    "+i + ".您设置的一级标题字体（"+cb_oneFont.editedText+"）不存在，将自动为你恢复为最近一次正确设置（"+cb_oneFont.currentText+"）;";
                    }
                    pageSettingMap["一级标题字体"] = cb_oneFont.currentText;
                    cb_oneFont.editedText = cb_oneFont.currentText;

                    if(fontFamilies.indexOf(cb_contextFont.editedText) === -1){//判断用户输入的正文字体是否存在
                        i +=1;
                        if(i>1)//第二行开始要换行
                            errorMsg += "\n"
                        errorMsg += "    "+i + ".您设置的正文字体（"+cb_contextFont.editedText+"）不存在，将自动为你恢复为最近一次正确设置（"+cb_contextFont.currentText+"）;";
                    }
                    //currentText中保存的是最近一次正确的配置的文本
                    pageSettingMap["正文字体"] = cb_contextFont.currentText;
                    cb_contextFont.editedText = cb_contextFont.currentText;

                    if(fontFamilies.indexOf(cb_ksFont.editedText) === -1){//判断用户输入的正文字体是否存在
                        i +=1;
                        if(i>1)//第二行开始要换行
                            errorMsg += "\n"
                        errorMsg += "    "+i + ".您设置的考生信息字体（"+cb_ksFont.editedText+"）不存在，将自动为你恢复为最近一次正确设置（"+cb_contextFont.currentText+"）;";
                    }
                    //currentText中保存的是最近一次正确的配置的文本
                    pageSettingMap["考生信息字体"] = cb_ksFont.currentText;
                    cb_ksFont.editedText = cb_ksFont.currentText;

                    //判断页边距是否存在错误，页边距不应该超出纸张大小
                    if(paperSize === "A4"){
                        if(pageSettingMap["横向页面"] === false){
                            //纵向页面
                            if(Number(pageSettingMap["上边距"])+Number(pageSettingMap["下边距"]) >= 297){
                                i +=1;
                                if(i>1)//第二行开始要换行
                                    errorMsg += "\n"
                                errorMsg += "    "+i + ".您设置的上下边距超出纸张("+paperSize +")范围，请确保上下页边距之和小于297mm,将为您设置为默认页边距";
                                pageSettingMap["上边距"] = 38;
                                pageSettingMap["下边距"] = 35;
                                in_top.text = 38;
                                in_bottom.text =35;
                            }
                            if(Number(pageSettingMap["左边距"])+Number(pageSettingMap["右边距"]) >= 210){
                                i +=1;
                                if(i>1)//第二行开始要换行
                                    errorMsg += "\n"
                                errorMsg += "    "+i + ".您设置的左右边距超出纸张("+paperSize +")范围，请确保左右页边距之和小于210mm,将为您设置为默认页边距";
                                pageSettingMap["左边距"] = 27;
                                pageSettingMap["右边距"] = 27;
                                in_left.text = 27;
                                in_right.text = 27;
                            }
                        }else{
                            //横向页面时
                            if((+pageSettingMap["上边距"])+(+pageSettingMap["下边距"]) >= 210){
                                i +=1;
                                if(i>1)//第二行开始要换行
                                    errorMsg += "\n"
                                errorMsg += "    "+i + ".您设置的上下边距超出纸张("+paperSize +")范围，请确保上下页边距之和小于210mm,将为您设置为默认页边距";
                                pageSettingMap["上边距"] = 27;
                                pageSettingMap["下边距"] = 27;
                                in_top.text = 27;
                                in_bottom.text = 27;
                            }
                            if(Number(pageSettingMap["左边距"])+Number(pageSettingMap["右边距"]) >= 297){
                                i +=1;
                                if(i>1)//第二行开始要换行
                                    errorMsg += "\n"
                                errorMsg += "    "+i + ".您设置的左右边距超出纸张("+paperSize +")范围，请确保左右页边距之和小于297mm,将为您设置为默认页边距";
                                pageSettingMap["左边距"] = 38;
                                pageSettingMap["右边距"] = 35;
                                in_left.text = 38;
                                in_right.text = 35;
                            }
                        }
                    }else if(paperSize === "A3"){
                        if(pageSettingMap["横向页面"] === false){
                            //纵向页面
                            if((+pageSettingMap["上边距"])+(+pageSettingMap["下边距"]) >= 420){
                                i +=1;
                                if(i>1)//第二行开始要换行
                                    errorMsg += "\n"
                                errorMsg += "    "+i + ".您设置的上下边距超出纸张("+paperSize +")范围，请确保上下页边距之和小于420mm,将为您设置为默认页边距";
                                pageSettingMap["上边距"] = 38;
                                pageSettingMap["下边距"] = 35;
                                in_top.text = 38;
                                in_bottom.text =35;
                            }
                            if(Number(pageSettingMap["左边距"])+Number(pageSettingMap["右边距"]) >= 297){
                                i +=1;
                                if(i>1)//第二行开始要换行
                                    errorMsg += "\n"
                                errorMsg += "    "+i + ".您设置的左右边距超出纸张("+paperSize +")范围，请确保左右页边距之和小于297mm,将为您设置为默认页边距";
                                pageSettingMap["左边距"] = 27;
                                pageSettingMap["右边距"] = 27;
                                in_left.text = 27;
                                in_right.text = 27;

                            }
                        }else{
                            //横向页面时
                            if((+pageSettingMap["上边距"])+(+pageSettingMap["下边距"]) >= 297){
                                i +=1;
                                if(i>1)//第二行开始要换行
                                    errorMsg += "\n"
                                errorMsg += "    "+i + ".您设置的上下边距超出纸张("+paperSize +")范围，请确保上下页边距之和小于297mm,将为您设置为默认页边距";
                                pageSettingMap["上边距"] = 27;
                                pageSettingMap["下边距"] = 27;
                                in_top.text = 27;
                                in_bottom.text = 27;
                            }
                            if(Number(pageSettingMap["左边距"])+Number(pageSettingMap["右边距"]) >= 420){
                                i +=1;
                                if(i>1)//第二行开始要换行
                                    errorMsg += "\n"
                                errorMsg += "    "+i + ".您设置的左右边距超出纸张("+paperSize +")范围，请确保左右页边距之和小于420mm,将为您设置为默认页边距";
                                pageSettingMap["左边距"] = 38;
                                pageSettingMap["右边距"] = 35;
                                in_left.text = 38;
                                in_right.text = 35;
                            }
                        }
                    }
                    //检查左边距是否够侧面填写考生信息使用
                    console.log("判断考生信息：",isZhangDing);
                    if(isZhangDing){//考生信息在侧面
                        //估算考生信息行高，字体高度为字体大小的1.2倍，获得高度磅值，转换为mm
                        var fontHeight = Number(pageSettingMap["考生信息字号"])/72*25.4*1.2;
                        var jianJu = 200/Number(pageSettingMap["分辨率"])*25.4;//上下预留间距
                        console.log("判断考生信息：",fontHeight,jianJu,Number(pageSettingMap["左边距"]));
                        if(fontHeight+jianJu >= Number(pageSettingMap["左边距"])){
                            i +=1;
                            if(i>1)//第二行开始要换行
                                errorMsg += "\n"
                            errorMsg += "    "+i + ".您设置的左边距过小，无法放下考生信息栏，请确保左边距大于"+Math.ceil(fontHeight+jianJu)+"mm,或缩小考生信息字体，将为您设置为默认左边距";
                            if(pageSettingMap["横向页面"] === false){
                                pageSettingMap["左边距"] = 27;
                                in_left.text = 27;
                            }else{
                                pageSettingMap["左边距"] = 38;
                                in_left.text = 38;
                            }

                        }

                    }

                    if(errorMsg !==""){
                        error(errorMsg);
                    }else
                        sucess();

                    accept();//发出accept消息
                }
            }
            Button {
                Material.background: Material.Green
                Material.foreground: "white"
                text: qsTr("取消")
                DialogButtonBox.buttonRole:  DialogButtonBox.NoRole
                onClicked: {
                    root.close();
                }
            }
        }


    }
}

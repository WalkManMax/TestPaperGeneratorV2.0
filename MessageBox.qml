/*
功能说明：
一、属性设置
1.text：设置消息框内显示的文本
2.font:消息文本的字体
3.iconFont:消息框后面X的字体设置，仅仅支持修改大小
4.style：消息框的风格，支持info、warning、success 和danger，其他未定义风格会自动转化为info
5.style_info、style_warning、style_success、style_danger：相应风格下消息框的背景和字体颜色，
  可使用{"backgroundColor":颜色,"textColor":颜色}直接赋值
二、函数
open()：显示消息框
close()：关闭消息框

*/
import QtQuick 2.14
import "./Fonts"

Rectangle {
    id:control
    property bool dismissed : true //用来存储X是否被按下
    property string style: "info" //用于设置风格，默认时info
    //保存各种风格的信息，存储背景颜色、字体颜色
    property var style_info: {"backgroundColor" : "#d9edf7","textColor" : "#31708f"}
    property var style_warning: {"backgroundColor" : "#fcf8e3","textColor" : "#8a6d3b"}
    property var style_danger: {"backgroundColor" : "#f2dede","textColor" : "#a94442"}
    property var style_sucess: {"backgroundColor" : "#dff0d8","textColor" : "#3c763d"}
    //用户设置属性接口
    property alias  text: messageText.text
    property alias font: messageText.font
    property alias iconFont: xMarkIcon.font


    //提供打开和关闭功能
    function open(){
        //打开消息框
        dismissed = false;
    }
    function close(){
        dismissed = true;
    }
    opacity: 0
    //背景色
    color:"#d9edf7"
    border.color: Qt.darker(color,1.15)
    radius: 5
    implicitHeight: messageText.height+20
    //添加状态数组
    states : [
        State {//当X被按下时，dismissed为true,则把组件透明度设为0
            when: dismissed
            PropertyChanges {
                target: control
                opacity: 0
            }
        },
        State {//当dismissed为false时，则把组件透明度设为1
            when: !dismissed
            PropertyChanges {
                target: control
                opacity: 1
            }
        }

    ]
    //为透明度变化设置一个动画，让透明度缓慢过度
    transitions: Transition {
        NumberAnimation {
            property: "opacity"
            duration: 300
        }
    }
    //通过透明度控制消息框是否显示
    onOpacityChanged: {
        if(opacity < 0.01 )
            visible = false;
        else if(opacity >0.01)
            visible =true;
    }

    //信息显示
    Text {
        id:messageText
        rightPadding: 30 //为右边的X预留空白
        leftPadding: 10
        topPadding: 5
        bottomPadding: 5
        anchors.verticalCenter: control.verticalCenter
        width: control.width
        color: "#31708f"
        //字体设置
        font.family: "仿宋_GB2312"
        font.pointSize: 12
        //设置换行方式
        wrapMode: Text.Wrap
        horizontalAlignment: Qt.AlignLeft
        verticalAlignment: Qt.AlignVCenter
    }
    //添加X图标
    Text{
        id:xMarkIcon
        anchors.top: control.top
        anchors.bottom: control.bottom
        anchors.right: control.right
        rightPadding: 10
        font.family: Fonts.solidIcons
        font.pointSize: 16
        text:"\u00d7"
        color: messageText.color
        verticalAlignment: Qt.AlignVCenter
        MouseArea{
            anchors.fill:parent
            hoverEnabled: true
            onClicked: {
                dismissed = true;
            }
            onEntered: {
                //鼠标进入图标显示区域就会触发这个函数
                xMarkIcon.color = Qt.lighter(messageText.color,1.5);

            }
            onExited: {
                //鼠标离开图标区域时，恢复原来的颜色
                xMarkIcon.color = messageText.color;
            }
        }
    }
    //监测style风格的变化，发生变化时改变背景和文字颜色
    onStyleChanged: {
        if(style === "sucess"){
            //修改组件背景
            control.color = Qt.binding(function(){return style_sucess["backgroundColor"];});
            //修改字体颜色
            messageText.color = Qt.binding(function(){return style_sucess["textColor"];});
        }else if(style === "danger"){
            //修改组件背景
            control.color = Qt.binding(function(){return style_danger["backgroundColor"];});
            //修改字体颜色
            messageText.color = Qt.binding(function(){return style_danger["textColor"];});
        }else if(style === "warning"){
            //修改组件背景
            control.color = Qt.binding(function(){return style_warning["backgroundColor"];});
            //修改字体颜色
            messageText.color = Qt.binding(function(){return style_warning["textColor"];});
        }else {//如果不是设置前三种风格，则默认为info
            //修改组件背景
            control.color = Qt.binding(function(){return style_info["backgroundColor"];});
            //修改字体颜色
            messageText.color = Qt.binding(function(){return style_info["textColor"];});
        }
    }
}

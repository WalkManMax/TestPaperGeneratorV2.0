import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.12

ComboBox{
    id:root
    property alias  editedText: textField.text
    onCurrentIndexChanged:{
        if(currentIndex !== model.indexOf(textField.text)){
//                        textField.text = currentText;
            //不能使用currentText,它存放的是上一次的文本
            textField.text = model[currentIndex];
        }
    }
    contentItem: TextField{//可编辑的组合框
        id:textField
        font.pointSize: root.font.pointSize
        selectByMouse: true
        bottomPadding: 8
        horizontalAlignment: Qt.AlignHCenter
        background: Rectangle{
            color: "transparent"
        }
        onTextChanged: {//如果字体不存在，则标红色
            color = "black"
            if(root.model.indexOf(text)===-1){
                color = "red";
            }
            else if(root.currentIndex !== root.model.indexOf(text)) {
                //如果文本存在，则更新到后台
                root.currentIndex = root.model.indexOf(text);
                color = "black";
            }
        }
    }

}

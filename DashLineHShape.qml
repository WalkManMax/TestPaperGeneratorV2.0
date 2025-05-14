import QtQuick 2.0
import QtQuick.Shapes 1.14
Shape{
    id:root
    ShapePath{
        strokeWidth: 1
        strokeColor: "grey"
        strokeStyle: ShapePath.DashLine
        dashPattern: [5,5]
        startX: 0
        startY: 0
        PathLine{
            x:root.width
            y:0
        }
    }
}

import QtQuick 2.14

Canvas{
    id:root
    implicitHeight: 1
    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.lineWidth = 2;
        ctx.strokeStyle = "grey";
        ctx.setLineDash([3,2]);
        ctx.moveTo(0,0);
        ctx.lineTo(root.width,0);
        ctx.stroke();
    }
}

//设为单例，只实例化1次
pragma Singleton
import QtQuick 2.14

QtObject {
    //regular图标字体
    readonly property FontLoader fontAwesomeRegular: FontLoader{
        source: "fa-regular-400-6.5.1.ttf"
    }
    //brands图标字体
    readonly property FontLoader fontAwesomeBrands: FontLoader{
        source: "fa-brands-400-6.5.1.ttf"
    }
    //solid 图标字体
    readonly property FontLoader fontAwesomeSolid: FontLoader{
        source: "fa-solid-900--6.5.1.ttf"
    }
    //regular图标字体名
    readonly property string regularIcons: fontAwesomeRegular.name
    //brands图标字体名
    readonly property string brandsIcons: fontAwesomeBrands.name
    //solid 图标字体
    readonly property string solidIcons: fontAwesomeSolid.name
}

QT += quick quickcontrols2

CONFIG += c++20
CONFIG += utf8_source
#QMAKE_CXXFLAGS += -finput-charset=UTF-8 -fexec-charset=UTF-8

RC_ICONS = main.ico
# libxl
INCLUDEPATH += F:/MyProject/libxl-3.8.3.0/include_cpp
LIBS += F:/MyProject/libxl-3.8.3.0/lib64/libxl.lib
#minidocx
# 添加minidocx头文件路径
INCLUDEPATH += $$PWD/./minidocx/include
# 添加minidocx库路径,-L 指定库文件目录， -l 指定库文件名（去掉lib前缀和.so/.a/.dll等后缀）
LIBS += -L$$PWD/./minidocx/lib -llibminidocx

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0


SOURCES += \
        cservicebackend.cpp \
        main.cpp \
        orderedmap.cpp \
        tablemodel.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

DISTFILES += \
    minidocx/lib/libminidocx.a

HEADERS += \
    common.h \
    cservicebackend.h \
    minidocx/include/minidocx.hpp \
    orderedmap.h \
    tablemodel.h

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "cservicebackend.h"
#include <QQmlContext>
#include "tablemodel.h"
#include <QTextCodec>

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName("DuoShou.org");
    //强制编码
    QTextCodec::setCodecForLocale(QTextCodec::codecForName("UTF-8"));
    QQmlApplicationEngine engine;
    //获取应用程序路径
    QString appPath;
    appPath= QCoreApplication::applicationDirPath();
    engine.rootContext()->setContextProperty("appDir",appPath);
    qmlRegisterType<CServiceBackend>("my.CServiceBackend", 1, 0, "CServiceBackend");
    qmlRegisterSingletonType<TableModel>("my.CServiceBackend", 1, 0,"TableModel",
                                         [](QQmlEngine *engine,QJSEngine *scriptEngine)->QObject* {
                                            Q_UNUSED(engine);
                                            Q_UNUSED(scriptEngine);
                                            return TableModel::instance(); });
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}


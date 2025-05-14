#ifndef TABLEMODEL_H
#define TABLEMODEL_H

#include <QObject>
#include <QAbstractTableModel>
#include <QVector>
#include <QVariant>
#include <QQmlEngine>
#include <QVariantMap>
#include "common.h"
#include "orderedmap.h"
#include <QSettings>
#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>
#include <QDebug>
#include <QVariant>
#include <cmath>

class TableModel : public QAbstractTableModel
{
    Q_OBJECT
public:
    static TableModel* instance();
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    Q_INVOKABLE bool setData(int row,int column,const QVariant &value,int role = Qt::EditRole);
    Qt::ItemFlags flags(const QModelIndex &index) const override;
    QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;
    // 添加行移动方法
    Q_INVOKABLE bool moveRow(int sourceRow, int destinationRow);
    //更新题型及数量，QVariantMap map以键值对的形式保存各题型及数量，QMap<QString, QVariant>
    void updateAllData(const OrderedMap &data);
    //返回全部数据，保存为OrderedMap
    OrderedMap retrunAllData();
    //将数据保存到QSettings文件中
    void saveTypeSettings();
    QuestionType rowData(QString key);//返回行数据
    //清空所用用户数设置参数
    void clearUserSet();
private:
    explicit TableModel(QObject *parent = nullptr);
    OrderedMap m_data;
    QStringList m_typeStoreList;//存储的题型列表
signals:

};

#endif // TABLEMODEL_H

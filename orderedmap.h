#ifndef ORDEREDMAP_H
#define ORDEREDMAP_H

#include "common.h"
#include <QList>
#include <QHash>
#include <QPair>
#include <QDataStream>
#include <QVariant>
#include <QDebug>

//带顺序的键值对类
class OrderedMap
{
public:
    OrderedMap();
    void append(const QString& key,const QuestionType& value);//插入数据
    QuestionType value(const QString &key) const;
    QuestionType at(int index) const; //通过索引获取
    QString key(int index) const;
    QStringList keys() const;
    void remove(const QString &key);
    bool move(int from, int to); //移动数据
    int size() const;//获取数量
    int isEmpty() const;
    void clear();//清空数据
    OrderedMap& operator = (const OrderedMap &data);
    void setQuestion(int index,int xuhao,const QVariant &value);//设置内部参数index索引号，序号是QuestionType内部索引号
    //添加qDebug()的支持
    friend QDebug operator << (QDebug debug,const OrderedMap &data);
private:
    QList<QPair<QString,QuestionType>> m_list;//保存信息
    QHash<QString,int>m_hash;//保存顺序
};

#endif // ORDEREDMAP_H

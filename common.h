#ifndef COMMON_H
#define COMMON_H



#include <QString>
#include <QMarginsF>
#include <QFont>
#include <QDebug>

struct QuestionType{
    //保存出题信息，包括题型名称、数量及分值
    bool isNull = true;//内容是否为空
    int totalCount;//总数量
    int count;//该题型的出题数量
    double score;//单题分值,用float会出现与qml交互精度错误
    QuestionType(int tc,int c,double s):
        isNull(false),totalCount(tc),count(c),score(s){}
    QuestionType() = default;
    bool isEmpty(){
        return isNull;
    }
    //支持qdebug()
    friend QDebug operator <<(QDebug debug,const QuestionType&s){
        debug<<"试题信息："<<s.isNull<<" "<<s.totalCount<<" "<<s.count<<" "<<s.score;
        return debug;
    }
};
struct PageSetting
{//保存页面设置信息
    QString pageSize ;//页面纸张规格大小
    QMarginsF pageMarMargins;//页边距
    bool isDoublePage;//是否双面打印
    bool islandScape;//是否为横向页面
    bool isZhuangDing;//考生信息是否装订在侧面
    QFont h1Font;//主标题字体
    QFont h2Font;//一级标题字体
    QFont hcFont;//正文字体
    QFont ksFont;//考生信息字体
    int hJianju;//行间距，单位Pt
    int ppi;//分辨率
};

#endif // COMMON_H

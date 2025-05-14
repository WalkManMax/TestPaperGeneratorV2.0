#ifndef CSERVICEBACKEND_H
#define CSERVICEBACKEND_H

#include <QObject>
#include "libxl.h"
#include <QVariantMap>
#include <QVector>
#include <QFont>
#include <QMarginsF>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QPdfWriter>
#include <QPainter>
#include <QtMath>
#include <QMutex>
#include "tablemodel.h"
#include <QSettings>
#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>
#include <common.h>
#include <QSet>
#include <QRegularExpression>
#include "orderedmap.h"
#include "minidocx/include/minidocx.hpp"
#include <QTextCodec>

using namespace md;
using namespace libxl;

class CServiceBackend : public QObject
{
    Q_OBJECT
public:
    explicit CServiceBackend(QObject *parent = nullptr);
    ~ CServiceBackend();
    //处理错误消息
    Q_INVOKABLE QString getError();//返回错误信息
    void setError(QString error);//设置错误消息
    //读取Excel文件
    Q_INVOKABLE void setExcelFileName(QString name);//获取文件名
    bool openExcelFile();//打开Excel文件
    Q_INVOKABLE bool readItemBankMsg(bool needStore);//读取题库信息
    void fusionBankMsg(bool needStore);//将保存的出题设置信息、Excel表中导入的题库信息和用户自己输入的信息整合，更新到model中
    //获取页面设置
    Q_INVOKABLE void readPageSetting(QVariantMap map);//获取页面设置信息,写入m_mainPageSetting
    //获取试卷标题
    Q_INVOKABLE bool getTestPaperTittle(QString tittle);//试卷标题
    //按照设置打印试卷
    Q_INVOKABLE bool printTestPaper(bool isdocx);
    //打印PDF试卷
    bool printPDFTestPaper();
    //打印docx试卷
    bool printDocxTestPaper();
    //试卷生成辅助函数：写入文本hJianju行间距，text需要写入的内容，isCenter文本是否居中,首行缩进的字符数indentNum,topMargin设置第一行的上间距，特殊下可能与内部行间距不同，比如标题上面不需要行间距
    void writeText(QString text,QFont font,qreal hJianju,qreal topMargin,bool isCenter,int indentNum);
    bool writeText(QString text,QString styleName,SectionPointer section,bool isquestion);//如果是问题，则简答题答案颜色设置为白色
    void xiPaiVector(QVector<int> *vector);//洗牌算法
    bool writeQuestionOrAnswer(bool isQuestion,qreal hJianju);//写入试题pdf
    bool writeTestPaperDocx(bool isQuestion,SectionPointer section);//写入试题docx
    QString numberToChinese(int num);//把数字序号转换为汉字序号
    //读取QSettings文件中的数据
    void readTypeSettings();
    //检查组卷信息是否存在问题,返回错误和警告信息
    Q_INVOKABLE QVariantList checkZuJuan(QString tittle);
    Q_INVOKABLE QVariantList getFenzhi();//返回试卷的题目总数和分值
    //清空用户题型设置
    Q_INVOKABLE void testPaperSetClear();

signals:
    void error();//出现错误以后发出信号
    void readReady();//通知用户，读取题库信息成功的信号
private:
    QString m_error;//保存错误信息
    Book *m_book;//Excel文件
    Sheet *m_sheet;//工作表
    QString m_excelFileName;//题库文件路径
    QStringList m_typeStoreList;//存储的题型列表
    OrderedMap m_typeStore;//存储的题型列表，包含顺序
    OrderedMap m_typeNew;//读取的题型列表，包含顺序
    //保存用户设置的组题信息
    OrderedMap m_testPaperSet;//保存试卷出题的题型及各题型的出题数量,即表格中显示的，最终用于生成试卷的
    //保存题库各题型信息
    QVariantMap m_itemBankMsg;//以键值对的形式保存各题型及数量，QMap<QString, QVariant>
    //存储所有题型所在的行号，方便后续抽题和读题
    QMap<QString,QVector<int>> m_tiMuNumList;//保存各题型的行号列表，没有顺序

    //保存页面设置信息
    PageSetting m_mainPageSetting;//全部页面设置信息
    //试卷标题
    QString m_testPaperTittle;
    //创建一个PDF设备对象
    QPdfWriter *m_pdfWriter;
    //创建绘图对象
    QPainter *m_pPainter;
    //绘制起点
    qreal m_xStart;
    qreal m_yStart;
    //是否奇数页
    bool m_isOddPage;
    QMutex mutex;
    //题型分值表格数据模型
    TableModel *m_tableModel;
    //总分和总题数
    int m_totalTimu;
    double m_totalFenzhi;
    //docx文档对象
    Document m_doc;
};

#endif // CSERVICEBACKEND_H

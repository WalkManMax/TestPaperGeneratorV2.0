#include "tablemodel.h"

TableModel::TableModel(QObject *parent) : QAbstractTableModel(parent)
{
    m_data.append("单选题",QuestionType(0,0,0));
    m_data.append("多选题",QuestionType(0,0,0));
    m_data.append("填空题",QuestionType(0,0,0));
    m_data.append("判断题",QuestionType(0,0,0));
    m_data.append("简答题",QuestionType(0,0,0));
}

TableModel *TableModel::instance()
{
    static TableModel model;
    QQmlEngine::setObjectOwnership(&model,QQmlEngine::CppOwnership);
    return &model;
}

int TableModel::rowCount(const QModelIndex &parent) const
{
    if(parent.isValid())
        return 0;
    return m_data.size();
}

int TableModel::columnCount(const QModelIndex &parent) const
{
    if(parent.isValid())
        return 0;
    return m_data.isEmpty() ? 0 : 4;
}

QVariant TableModel::data(const QModelIndex &index, int role) const
{

    if(!index.isValid() || role != Qt::DisplayRole || index.row() >= m_data.size())
        return QVariant();
    const auto &item = m_data.at(index.row());//获取一行数据
//    qDebug()<<"读取数据："<<m_data.key(index.row())<<item.score;
    if(role == Qt::DisplayRole || role == Qt::EditRole){
        switch (index.column()) {
        case 0 : return m_data.key(index.row());
        case 1 : return item.totalCount;
        case 2 : return item.count;
        case 3 : return item.score;
        }
    }
    return QVariant();
}

bool TableModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
//    qDebug()<<"修改前："<<m_data<<"数据"<<index.row()<<value;
    if(!index.isValid() || role != Qt::EditRole)
        return false;
    if(index.column() == 0)//第1列不可编辑
        return false;
    if(index.column() == 1)//第2列不可编辑
        return false;
    bool sucess = false;
    switch (index.column()) {
    case 2 :
        if(value.canConvert<int>()){
            m_data.setQuestion(index.row(),1,value.toInt());
            sucess =true;
        }
        break;
    case 3 :
        if(value.canConvert<double>()){
            m_data.setQuestion(index.row(),2,value.toDouble());
//            qDebug()<<"输入的浮点数"<<value<<value.toFloat()<<m_data.at(index.row()).score;
            sucess =true;
        }
        break;
    }
    if(sucess){
        saveTypeSettings();
        emit dataChanged(index,index,{role});
//        qDebug()<<"修改后："<<m_data;
        return true;
    }
    return false;
}

bool TableModel::setData(int row, int column, const QVariant &value, int role)
{
    return setData(this->index(row,column),value,role);
}

Qt::ItemFlags TableModel::flags(const QModelIndex &index) const
{
    Qt::ItemFlags defaultFlags = QAbstractTableModel::flags(index);
    if(index.column() == 0 || index.column() == 1){
        return defaultFlags | Qt::ItemIsSelectable | Qt::ItemIsEnabled | Qt::ItemIsDragEnabled;
    }
    return defaultFlags | Qt::ItemIsEditable | Qt::ItemIsEnabled | Qt::ItemIsSelectable;
}

QVariant TableModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
            return QVariant();

        if (orientation == Qt::Horizontal) {
            // 返回列标题
            switch (section) {
            case 0: return "题型";
            case 1: return "总数量";
            case 2: return "出题数量";
            case 3: return "单题分值";
            default: return QVariant();
            }
        } else {
            // 返回行号
            return section + 1;
        }
}


bool TableModel::moveRow(int sourceRow, int destinationRow)
{
    if (sourceRow < 0 || sourceRow >= m_data.size() ||
            destinationRow < 0 || destinationRow >= m_data.size() ||
            sourceRow == destinationRow) {
        return false;
    }
    
    // 移动数据
//    qDebug()<<"移动前"<<m_data;
//    beginMoveRows(QModelIndex(), sourceRow, sourceRow, QModelIndex(), destinationRow>sourceRow ? destinationRow+1 : destinationRow);
    beginResetModel();
    m_data.move(sourceRow, destinationRow);
//    endMoveRows()
    endResetModel();
    saveTypeSettings();
//    qDebug()<<"移动后"<<m_data;
    return true;
}

void TableModel::updateAllData(const OrderedMap &data)
{
    beginResetModel();
    m_data.clear();
    m_data = data;
    saveTypeSettings();
    endResetModel();
}

OrderedMap TableModel::retrunAllData()
{
    return m_data;
}

void TableModel::saveTypeSettings()
{//将QVector<QuestionType> m_data;中的数据保存到QSettings文件中
    QString filePath;
    filePath= QCoreApplication::applicationDirPath()+"/typeSettings.ini";
    QSettings settings(filePath,QSettings::IniFormat);
    QStringList tiXingList;//保存题型，有顺序
//    qDebug()<<"写入ini文件前的数据"<<m_data;
    //生成Json数据，不保存总题数
    QJsonObject root;
    for(int i=0;i<m_data.size();i++){
//        QJsonArray array = {m_data.at(i).count,QString::number(m_data.at(i).score)};//浮点数转成字符串，否则会出现误差
        QJsonArray array = {m_data.at(i).count,m_data.at(i).score};
        root[m_data.key(i)] = array;
        tiXingList.append(m_data.key(i));
//        qDebug()<<"测试"<<m_data.key(i);
    }
//    qDebug()<<"写入全部数据"<<root<<"题型列表"<<tiXingList;
    QJsonDocument doc(root);
    QString jsonString = doc.toJson(QJsonDocument::Indented);;
    settings.setValue("typeSettings",jsonString);
    settings.setValue("typeList",tiXingList);
}

QuestionType TableModel::rowData(QString key)
{
    return m_data.value(key);
}

void TableModel::clearUserSet()
{
    for(int i=0;i<m_data.size();i++){
        m_data.setQuestion(i,1,0);
        m_data.setQuestion(i,2,0);
    }
    saveTypeSettings();
    emit dataChanged(index(0,2),index(m_data.size()-1,3));
}


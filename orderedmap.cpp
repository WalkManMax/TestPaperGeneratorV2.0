#include "orderedmap.h"

OrderedMap::OrderedMap()
{

}

void OrderedMap::append(const QString &key, const QuestionType &value)
{
    if(m_hash.contains(key)){
        m_list[m_hash[key]].second = value;//存在则更新数据
    }else{
        m_hash[key] = m_list.size();//新增
        m_list.append({key,value});
    }
}

QuestionType OrderedMap::value(const QString &key) const
{
    if(m_hash.contains(key))
        return m_list[m_hash[key]].second;
    else
        return QuestionType();
}

QuestionType OrderedMap::at(int index) const
{
    return m_list[index].second;
}

QString OrderedMap::key(int index) const
{
    return m_list[index].first;
}

QStringList OrderedMap::keys() const
{
    return m_hash.keys();//不保留顺序
}

void OrderedMap::remove(const QString &key)
{
    if(m_hash.contains(key)){
        int index = m_hash[key];
        m_list.removeAt(index);
        m_hash.remove(key);
        for(int i = index;i<m_list.size();++i){
            //把i之后的索引都更新一下
            m_hash[m_list[i].first] = i;
        }
    }
}

bool OrderedMap::move(int from, int to)
{
    //from和to必须>0,<size()
    if(from <0 || from >=m_hash.size() || to <0 || to >=m_hash.size())
        return false;
    else if(from == to)
        return true;
    else{
        //m_list可以直接移动，m_hash需要更新索引
//        qDebug()<<"移动前"<<m_hash;
        m_list.move(from,to);
//        qDebug()<<"移动后"<<m_list;
        //遍历重置哈希值
        for(int i = 0;i<m_list.size();++i){
            m_hash[m_list[i].first] = i;
        }

//        qDebug()<<"移动后"<<m_hash<<"\n"<<m_list;
        return true;
    }
}

int OrderedMap::size() const
{
    return m_list.size();
}

int OrderedMap::isEmpty() const
{
    return m_hash.isEmpty();
}

void OrderedMap::clear()
{
    m_hash.clear();
    m_list.clear();
}

OrderedMap &OrderedMap::operator =(const OrderedMap &data)
{
    if(this != &data){
        //防止自赋值
        m_hash = data.m_hash;
        m_list = data.m_list;
    }
    return *this;
}

void OrderedMap::setQuestion(int index,int xuhao, const QVariant &value)
{
    switch (xuhao) {
    case 1:
        m_list[index].second.count = value.toInt();
        break;
    case 2:
        m_list[index].second.score = value.toDouble();
        break;
    }
//    qDebug()<<"修改数据后orderedmap"<<index<<xuhao<<m_list[index].first<<m_list[index].second;
}

QDebug operator <<(QDebug debug, const OrderedMap &data)
{
    debug << data.m_list;
    return debug;
}




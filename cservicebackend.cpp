#include "cservicebackend.h"

CServiceBackend::CServiceBackend(QObject* parent) : QObject(parent)
{
    //设置默认页面信息
    m_mainPageSetting.pageSize = "A4";
    //设置页边距，左、上、右、下，依次为27mm(319pix)、35mm(413pix)、27mm(319pix)、37mm(437pix),默认使用磅作为单位
    //    m_mainPageSetting.pageMarMargins = QMarginsF(27/25.4*72,20/25.4*72,27/25.4*72,20/25.4*72);
    m_mainPageSetting.pageMarMargins = QMarginsF(27, 35, 27, 37);//用毫米作为单位

    m_mainPageSetting.isDoublePage = false;
    m_mainPageSetting.islandScape = false;
    m_mainPageSetting.isZhuangDing = false;
    m_mainPageSetting.h1Font = QFont("方正小标宋简体", 22);
    m_mainPageSetting.h2Font = QFont("黑体", 16);
    m_mainPageSetting.hcFont = QFont("仿宋_GB2312", 16);
    m_mainPageSetting.ksFont = QFont("仿宋_GB2312", 14);
    m_mainPageSetting.hJianju = 5;
    m_mainPageSetting.ppi = 300;
    //绘制起点
    m_xStart = 0;
    m_yStart = 0;
    //是否奇数页
    m_isOddPage = true;
    m_pPainter = new QPainter();
    //分值
    m_totalTimu = 0;
    m_totalFenzhi = 0;
    //模型初始化
    m_tableModel = TableModel::instance();
    readTypeSettings();

}

CServiceBackend::~CServiceBackend()
{
    //    m_book->release();
    //    delete m_pdfWriter;
}

QString CServiceBackend::getError()
{
    return  m_error;
}

void CServiceBackend::setError(QString error)
{
    m_error = error;
}

void CServiceBackend::setExcelFileName(QString name)
{
    m_excelFileName = name;
}

bool CServiceBackend::openExcelFile()
{
    //根据Excel的不同后缀确定调用的函数
    QString houzui = m_excelFileName.split(".").last();
    if (houzui == "xls")
        m_book = xlCreateBook();
    else if (houzui == "xlsx")
        m_book = xlCreateXMLBook();
    else {
        setError("你选择不是一个标准的Excel文件！");
        emit error();
        return false;
    }
    if (!m_book) {
        setError(QString(m_book->errorMessage()));
        emit error();
        return false;
    }
    //载入Excel文件
    m_book->setKey(L"qwerasdf", L"windows-2028250e01c3eb0968b2676cadrfr1i6");
    bool ret = m_book->load(m_excelFileName.toStdWString().c_str());//把QString转为wchar_t*
    if (!ret) {
        setError(QString(m_book->errorMessage()));
        emit error();
        return false;
    }
    //查找题库工作表
    m_sheet = NULL;
    for (int i = 0;i < m_book->sheetCount();i++) {
        if (QString::fromStdWString(m_book->getSheetName(i)) == "题库") {
            m_sheet = m_book->getSheet(i);
            if (!m_sheet) {
                setError(QString(m_book->errorMessage()));
                emit error();
                return false;
            }
            break;
        }
    }
    if (m_sheet == NULL) {
        setError("没有找到名称为“题库”的工作表，请将题库所在工作表名称修改为“题库”！");
        emit error();
        return false;
    }
    //如果没有试题，要进行提醒
    if (m_sheet->lastRow() < 4) {
        //无题目
        setError("题库内没有试题，请添加试题后再尝试！");
        emit error();
        return false;
    }
    return true;
}

bool CServiceBackend::readItemBankMsg(bool needStore)
{
    int msgColumn = 1;//表示题型所在的列的列号
    //读取Excel文件数据
    bool ret = openExcelFile();
    if (!ret) {//读取失败
        return false;
    }
    //初始化题库信息
    m_tiMuNumList.clear();
    //Excel题库读取
    m_typeNew.clear();
    QStringList typeNewList;//为了保留Excel中的题型顺序
    for (int row = 2;row < m_sheet->lastRow();row++) {//从第三行开始
        if (m_sheet->cellType(row, msgColumn) == CELLTYPE_STRING) {
            const wchar_t* tiXing = m_sheet->readStr(row, msgColumn);//读取单元格字符串
            QString sTiXing = QString::fromStdWString(tiXing);//转化为字符串
            //添加题型行号到对应数组中，同时把题型名称添加到typeNewList中
            if (!m_tiMuNumList.contains(sTiXing)) {//如果不存在，则新建一个键值对
                QVector<int> temp;
                temp.append(row);
                m_tiMuNumList.insert(sTiXing, temp);
                typeNewList.append(sTiXing);
            }
            else {
                //如果存在，则添加对应行号
                m_tiMuNumList[sTiXing].append(row);
            }
        }
    }
    //获取每种题型的数量,保存到 QVector<QuestionType> m_typeNew 中

    for (const auto& key : typeNewList) {
        //        qDebug()<<"顺序"<<key;
        m_itemBankMsg.insert(key, m_tiMuNumList.value(key).count());
        m_typeNew.append(key, QuestionType(m_tiMuNumList.value(key).count(), 0, 0));
    }
    fusionBankMsg(needStore);

    emit readReady();
    return true;
}

void CServiceBackend::fusionBankMsg(bool needStore)
{
    //获取保存的出题信息
    readTypeSettings();
    if (needStore && !m_typeStore.isEmpty()) {
        //使用保存的出题信息
        //获取m_typeStore中的键值
        QStringList differentType;//保存不同题型
        QStringList sameType;
        //遍历m_typeStore，收集同时存在的元素,只有遍历m_typeStore才能使用m_typeStore中题型的顺序
        for (int i = 0;i < m_typeStore.size();i++) {
            if (m_typeNew.keys().contains(m_typeStore.key(i)))
                sameType.append(m_typeStore.key(i));
        }
        //        qDebug()<<"共同数据"<<sameType;
                //遍历m_typeNew，收集其他元素，只有遍历m_typeNew才能使用m_typeNew中题型的顺序
        for (int i = 0;i < m_typeNew.size();i++) {
            if (!sameType.contains(m_typeNew.key(i)))
                differentType.append(m_typeNew.key(i));
        }
        //        qDebug()<<"其他数据"<<differentType;
                //遍历m_typeStore，生成m_testPaperSet
        m_testPaperSet.clear();
        for (const QString& key : sameType) {//将共同的添加进去,用m_typeNew保存的题型总数，m_typeStore设置上此保存信息
            m_testPaperSet.append(key, QuestionType(m_typeNew.value(key).totalCount, m_typeStore.value(key).count, m_typeStore.value(key).score));
        }

        for (const QString& key : differentType) {//将用户设置的题型添加进去
            m_testPaperSet.append(key, QuestionType(m_typeNew.value(key).totalCount, m_tableModel->rowData(key).count, m_tableModel->rowData(key).score));
        }
    }
    else {
        m_testPaperSet = m_typeNew;
    }
    m_tableModel->updateAllData(m_testPaperSet);
    m_tableModel->saveTypeSettings();
    //    qDebug()<<m_typeStore.value("多选题").score<<m_tableModel->rowData("多选题").score;
}


void CServiceBackend::readPageSetting(QVariantMap map)
{
    m_mainPageSetting.pageSize = map["纸张"].toString();
    //设置页边距，左、上、右、下,使用毫米作为单位
    m_mainPageSetting.pageMarMargins = QMarginsF(map["左边距"].toInt(), map["上边距"].toInt(), map["右边距"].toInt(), map["下边距"].toInt());
    m_mainPageSetting.isDoublePage = map["双面"].toBool();
    m_mainPageSetting.islandScape = map["横向页面"].toBool();
    m_mainPageSetting.isZhuangDing = map["侧面封装"].toBool();
    m_mainPageSetting.h1Font = QFont(map["主标题字体"].toString(), map["主标题字号"].toInt());
    m_mainPageSetting.h2Font = QFont(map["一级标题字体"].toString(), map["一级标题字号"].toInt());
    m_mainPageSetting.hcFont = QFont(map["正文字体"].toString(), map["正文字号"].toInt());
    m_mainPageSetting.ksFont = QFont(map["考生信息字体"].toString(), map["考生信息字号"].toInt());
    m_mainPageSetting.hJianju = map["行间距"].toInt();
    m_mainPageSetting.ppi = map["分辨率"].toInt();
}
bool CServiceBackend::getTestPaperTittle(QString tittle)
{
    m_testPaperTittle = tittle;
    return true;
}
//打印PDF试卷
bool CServiceBackend::printPDFTestPaper()
{
    //在桌面目录下新建一个文件夹，用于存放pdf文件
    QString dirPdf = "试卷";
    QDir dir(QDir::current());
    QString desk = QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
    dir.cd(desk);
    if (dir.exists(dirPdf)) {
        dir.cd(dirPdf);
    }
    else {
        dir.mkdir(dirPdf);
        dir.cd(dirPdf);
    }
    //创建pdf文件
    QFile pdfFile;
    pdfFile.setFileName(dir.path() + "/" + m_testPaperTittle + ".pdf");
    if (pdfFile.exists())
        pdfFile.remove();
    if (!pdfFile.open(QIODevice::WriteOnly)) {
        m_error = "创建PDF文件失败！请检查原文件是否关闭！";
        return false;
    }
    m_pdfWriter = new QPdfWriter(&pdfFile);
    //设置分辨率
    m_pdfWriter->setResolution(m_mainPageSetting.ppi);

    //设置纸张大小
    if (m_mainPageSetting.pageSize == "A3") {
        m_pdfWriter->setPageSize(QPageSize(QPageSize::A3));
    }
    else if (m_mainPageSetting.pageSize == "A4") {
        m_pdfWriter->setPageSize(QPageSize(QPageSize::A4));
    }
    else {
        m_pdfWriter->setPageSize(QPageSize(QPageSize::A4));
    }
    //设置页面方向
    if (m_mainPageSetting.islandScape)
        m_pdfWriter->setPageOrientation(QPageLayout::Landscape);//横向页面
    else
        m_pdfWriter->setPageOrientation(QPageLayout::Portrait);//纵向页面
    //设置奇偶页
    m_isOddPage = true;//初始为奇数
    //设置行间距
    qreal hJianju = (qreal)m_mainPageSetting.hJianju / (qreal)72 * (qreal)300;//行间距
    //设置页边距
    QMarginsF tempMargin = m_mainPageSetting.pageMarMargins;
    m_pdfWriter->setPageMargins(tempMargin, QPageLayout::Millimeter);//用毫米作为单位
    //设置绘制的起始位置
    m_xStart = 0;
    m_yStart = 0;
    //关闭上次的，重新启动
    m_pPainter->begin(m_pdfWriter);
    //先打印侧面信息
    QFontMetricsF metricTemp(m_mainPageSetting.hcFont);
    QSizeF sizeTemp;//打印区域
    //获取更新表格中的出题信息到m_testPaperSet
    m_testPaperSet = m_tableModel->retrunAllData();
    //设置考生信息
    QString msgTemp = "单位:______________  姓名:_________  得分:_________";
    if (m_mainPageSetting.isZhuangDing) {
        //获取页面大小
        double pageContextHeight = m_pdfWriter->height();//内高,单位pix
        //根据字体获取单行文本的宽度和高度
        m_pPainter->save();
        QPen pen(Qt::black, 2, Qt::DashDotLine);
        m_pPainter->setPen(pen);
        m_pPainter->drawLine(0 - 50, 0 - m_mainPageSetting.pageMarMargins.top() * 300 / 25.4, 0 - 50, pageContextHeight + m_mainPageSetting.pageMarMargins.bottom() * 300 / 25.4);
        m_pPainter->setFont(m_mainPageSetting.ksFont);
        m_pPainter->translate(0, pageContextHeight);
        m_pPainter->rotate(-90);//旋转90度
        //打印考生信息
        metricTemp = m_pPainter->fontMetrics();
        sizeTemp = metricTemp.size(Qt::TextSingleLine, msgTemp);
        QRectF ks_rect = QRectF(0, 0 - 200, pageContextHeight, sizeTemp.height());
        m_pPainter->drawText(ks_rect, Qt::AlignCenter, msgTemp);
        //重置坐标系
        m_pPainter->resetTransform();
        m_pPainter->restore();
    }
    //打印试卷标题
    writeText(m_testPaperTittle, m_mainPageSetting.h1Font, 0, 0, true, 0);
    if (!m_mainPageSetting.isZhuangDing) {//如果打印在标题下方
        writeText(msgTemp, m_mainPageSetting.ksFont, hJianju, hJianju + 20, true, 0);
    }
    //打印试题
    bool ret = writeQuestionOrAnswer(true, hJianju);
    if (!ret) {
        return false;
    }
    //打印答案
    //新建一页
    if (m_mainPageSetting.isDoublePage) {//如果是双面打印，则重新设置页面信息
        if (m_isOddPage) {
            //当前为奇数页，则下一个为偶数页，需要更换左右边距
            tempMargin.setLeft(m_mainPageSetting.pageMarMargins.right());
            tempMargin.setRight(m_mainPageSetting.pageMarMargins.left());
        }
        m_pdfWriter->setPageMargins(tempMargin, QPageLayout::Millimeter);//用毫米作为单位
    }
    m_pdfWriter->newPage();
    m_yStart = 0;
    m_xStart = 0;
    //改变奇偶页信息
    m_isOddPage = !m_isOddPage;
    //打印答案标题
    writeText(m_testPaperTittle + "答案", m_mainPageSetting.h1Font, 0, 0, true, 0);
    ret = writeQuestionOrAnswer(false, hJianju);
    if (!ret) {
        return false;
    }

    m_pPainter->end();
    return true;
}
bool CServiceBackend::printDocxTestPaper()
{
    //在桌面目录下新建一个文件夹，用于存放docx文件
    QString dirDocx = "试卷";
    QDir dir(QDir::current());
    QString desk = QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
    dir.cd(desk);
    if (dir.exists(dirDocx)) {
        dir.cd(dirDocx);
    }
    else {
        dir.mkdir(dirDocx);
        dir.cd(dirDocx);
    }
    //检查文件是否存在
    QString filePath =dir.path() + "/" + m_testPaperTittle + ".docx";
    QFileInfo fileInfo(filePath);
    if (fileInfo.exists() && fileInfo.isFile()) {
        // 执行删除
        if (!QFile::remove(filePath)) {
            m_error = "试卷文件无法创建，请关闭同名文件或更改试卷名称后重试！";
            emit error();
            return false;
        }
    }
    try {
        //写入docx文件
        m_doc.reset();
        SectionPointer sect1 = m_doc.addSection();
        //设置纸张大小
        if (m_mainPageSetting.pageSize == "A3") {
            sect1->prop_.size_.width_ = A3_W;
            sect1->prop_.size_.height_ = A3_H;
        }
        else {//默认使用A4
            sect1->prop_.size_.width_ = A4_W;
            sect1->prop_.size_.height_ = A4_H;
        }
        //设置页面方向
        if (m_mainPageSetting.islandScape)
            sect1->prop_.landscape_ = true;//横向页面
        else
            sect1->prop_.landscape_ = false;//纵向页面
        //设置行间距，单位是磅
        qreal hJianju = (qreal)m_mainPageSetting.hJianju;
        //设置页边距，单位是缇
        // 1 厘米 = 28.35 毫米，1 缇 = 1/20 磅，1 英寸 = 72 磅，1 英寸 = 25.4 毫米，所以 1 毫米 = 56.69 缇（约）
        // 这里将毫米转为缇，乘以 56.69 进行近似转换
        sect1->prop_.margins_.top_ = m_mainPageSetting.pageMarMargins.top() * 56.69;
        sect1->prop_.margins_.bottom_ = m_mainPageSetting.pageMarMargins.bottom() * 56.69;
        sect1->prop_.margins_.left_ = m_mainPageSetting.pageMarMargins.left() * 56.69;
        sect1->prop_.margins_.right_ = m_mainPageSetting.pageMarMargins.right() * 56.69;
        //设置文本样式
        //设置主标题样式
        ParagraphStyle paraStyleH1;
        paraStyleH1.name_ = "MyHeadingH1";
        paraStyleH1.align_ = Alignment::Centered;
        paraStyleH1.outlineLevel_ = ParagraphProperties::OutlineLevel::Level1;
        paraStyleH1.fontSize_ = m_mainPageSetting.h1Font.pointSize() * 2;//以二分之一磅为单位指示字号（2 = 1 磅）。
        paraStyleH1.color_ = "black";
        paraStyleH1.font_ = { .ascii_ = m_mainPageSetting.h1Font.family().toStdString(),\
                           .eastAsia_ = m_mainPageSetting.h1Font.family().toStdString() };
        paraStyleH1.ParagraphProperties::spacing_ = { .before_ = {.type_ = ParagraphProperties::SpacingType::Absolute,.value_ = 0},\
                                                    .after_ = {.type_ = ParagraphProperties::SpacingType::Absolute,.value_ = 0},\
                                                    .lineSpacing_ = {.type_ = ParagraphProperties::LineSpacingType::AtLeast} };
        m_doc.addParagraphStyle(paraStyleH1);
        //设置一级标题样式
        ParagraphStyle paraStyleH2;
        paraStyleH2.name_ = "MyHeadingH2";
        paraStyleH2.align_ = Alignment::Left;
        paraStyleH2.outlineLevel_ = ParagraphProperties::OutlineLevel::Level2;
        paraStyleH2.fontSize_ = m_mainPageSetting.h2Font.pointSize() * 2;//以二分之一磅为单位指示字号（2 = 1 磅）。
        paraStyleH2.color_ = "black";
        paraStyleH2.font_ = { .ascii_ = m_mainPageSetting.h2Font.family().toStdString(),\
                           .eastAsia_ = m_mainPageSetting.h2Font.family().toStdString() };
        //设置首行缩进
        paraStyleH2.indent_ = {.left_={.chars_ = false, .value_ = 0},\
                              .right_={.chars_ = false, .value_ = 0},\
                               .special_={.type_ = ParagraphProperties::SpecialIndentationType::FirstLine,.chars_ = true,.value_ = 200}};

        if (hJianju == 0) {
            //行间距为零，则默认最小值单倍行距
            paraStyleH2.ParagraphProperties::spacing_ = { .before_ = {.type_ = ParagraphProperties::SpacingType::Absolute,.value_ = 0},\
                                                         .after_ = {.type_ = ParagraphProperties::SpacingType::Absolute,.value_ = 0},\
                                                         .lineSpacing_ = {.type_ = ParagraphProperties::LineSpacingType::AtLeast} };
        }
        else
            paraStyleH2.ParagraphProperties::spacing_ = { .before_ = {.type_ = ParagraphProperties::SpacingType::Absolute,.value_ = 0},\
                                                         .after_ = {.type_ = ParagraphProperties::SpacingType::Absolute,.value_ = 0},\
                                                         .lineSpacing_ = {.type_ = ParagraphProperties::LineSpacingType::Exactly,.value_ = static_cast<unsigned long long>(qRound(hJianju * 20))} };
        //        paraStyleH2.ParagraphProperties::spacing_= {.lineSpacing_ = {.type_ = ParagraphProperties::LineSpacingType::Exactly,.value_ =static_cast<unsigned long long>(qRound(hJianju*20))}};
        m_doc.addParagraphStyle(paraStyleH2);
        //设置正文样式
        ParagraphStyle paraStyleHc;
        paraStyleHc.name_ = "MyHeadingHc";
        paraStyleHc.align_ = Alignment::Left;
        paraStyleHc.outlineLevel_ = ParagraphProperties::OutlineLevel::BodyText;
        paraStyleHc.fontSize_ = m_mainPageSetting.hcFont.pointSize() * 2;//以二分之一磅为单位指示字号（2 = 1 磅）。
        paraStyleHc.color_ = "black";
        paraStyleHc.font_ = { .ascii_ = m_mainPageSetting.hcFont.family().toStdString(),\
                             .eastAsia_ = m_mainPageSetting.hcFont.family().toStdString() };
        //设置首行缩进
        paraStyleHc.indent_ = paraStyleH2.indent_;
        //设置行间距
        paraStyleHc.ParagraphProperties::spacing_ = paraStyleH2.ParagraphProperties::spacing_;
        m_doc.addParagraphStyle(paraStyleHc);
        //设置考生信息栏样式
        ParagraphStyle paraStyleKs;
        paraStyleKs.name_ = "MyHeadingKs";
        paraStyleKs.align_ = Alignment::Centered;
        paraStyleKs.outlineLevel_ = ParagraphProperties::OutlineLevel::BodyText;
        paraStyleKs.fontSize_ = m_mainPageSetting.ksFont.pointSize() * 2;//以二分之一磅为单位指示字号（2 = 1 磅）。
        paraStyleKs.color_ = "black";
        paraStyleKs.font_ = { .ascii_ = m_mainPageSetting.ksFont.family().toStdString(),\
                            .eastAsia_ = m_mainPageSetting.ksFont.family().toStdString() };
        //设置行间距
        paraStyleKs.ParagraphProperties::spacing_ = paraStyleH2.ParagraphProperties::spacing_;
        m_doc.addParagraphStyle(paraStyleKs);


        //获取更新表格中的出题信息到m_testPaperSet
        m_testPaperSet = m_tableModel->retrunAllData();
        // 输入主标题
        writeText(m_testPaperTittle, "MyHeadingH1", sect1, false);

        // 输入考生信息
        QString msgTemp = "单位:______________  姓名:_________  得分:_________";
        if (m_mainPageSetting.isZhuangDing) {
            //考生信息在侧面
        }
        else {//考生信息在标题下方
            writeText(msgTemp, "MyHeadingKs", sect1, false);
        }
        bool ret = writeTestPaperDocx(true, sect1);
        if (!ret)
            return false;
        //打印答案
        //新建一页
        SectionPointer sect2 = m_doc.addSection();
        sect2->prop_ = sect1->prop_;
        //打印答案标题
        writeText(m_testPaperTittle + "答案", "MyHeadingH1", sect2, false);
        ret = writeTestPaperDocx(false, sect2);
        if (!ret) {
            return false;
        }

        //保存文件,windows默认使用的gbk编码格式
        QTextCodec *codec = QTextCodec::codecForName("GBK");
        std::string fileName = codec->fromUnicode(filePath).toStdString();
        qDebug()<<"文件路径："<<filePath;
        m_doc.saveAs(fileName);
    }
    catch (const Exception& ex) {
        if (QString::fromLocal8Bit(ex.what()).contains("cannot open")) {
            m_error = "试卷文件无法创建，请关闭同名文件或更改试卷名称后重试！";
        }
        else {
            m_error = QString::fromLocal8Bit(ex.what());
            //截取关键信息
            m_error.remove(0, 10);
        }
        emit error();
        return false;
    }
    return true;
}
bool CServiceBackend::printTestPaper(bool isdocx)
{
    if (isdocx) {
        return printDocxTestPaper();
    }
    else {
        return printPDFTestPaper();
    }
}

void CServiceBackend::writeText(QString text, QFont font, qreal hJianju, qreal topMargin, bool isCenter, int indentNum)
{
    //x,y存放的是上一次打印完毕后的位置，所以第一行开始就要加上页边距和字体高度
    //如果是新的一页开始，则需要判断是否为双面打印，如果是就需要重新设置页边距
    //    qDebug()<<"打印字体大小："<<font.family()<<font.poih(); //内宽,单位pix
    QMarginsF tempMargin = m_mainPageSetting.pageMarMargins;
    //获取页面大小
    qreal pageContextWidth = m_pdfWriter->width(); //内宽,单位pix
    qreal pageContextHeight = m_pdfWriter->height();//内高,单位pix
    //打印尺寸
    qreal pagePrintWidth;
    qreal pagePrintHeight = pageContextHeight;
    if (m_mainPageSetting.islandScape) {
        //横向页面,需要分栏，打印区域需要去除中间间隔，默认使用右边距分割
        pagePrintWidth = (pageContextWidth - m_pdfWriter->margins().right / 25.4 * 300) / 2;
    }
    else
        pagePrintWidth = pageContextWidth;

    //根据字体获取单行文本的宽度和高度，字体发生改变以后都要重新调用，获取字符度量信息，用于计算文本宽高等信息
    QFontMetricsF metricTemp(font);//这种方法不准确
    m_pPainter->setFont(font);
    metricTemp = m_pPainter->fontMetrics();
    //调整文本信息,分行打印
    QStringList printText = text.split('\n');
    //去除空白项
    printText = printText.filter(QRegExp("\\S"));

    //保存单行文本的宽高尺寸，便于后续分解
    QSizeF sizeTemp;
    QRectF recTemp;//单行文本的打印区域
    //开始打印
    QString msgTemp;//暂存需要打印的单行文本
    for (int i = 0;i < printText.size();i++) {
        msgTemp = printText.at(i);
        msgTemp = QString(indentNum * 2, ' ') + msgTemp;//通过添加空格，实现首行缩进
        //判断要打印几行
        sizeTemp = metricTemp.size(Qt::TextSingleLine, msgTemp);
        int hangNum = qCeil(sizeTemp.width() / pagePrintWidth);
        for (int j = 0;j < hangNum;j++) {
            int tempHJianju = 0;
            //判断打印行是否超页面
            if (i == 0 && j == 0) {
                //第一行
                tempHJianju = topMargin;
            }
            else
                tempHJianju = hJianju;
            //设置打印起始位置
            float height = 0;
            if (hJianju == 0)//如果是0就用文本最小行高
                height = sizeTemp.height();
            else
                height = hJianju;
                if (m_yStart + height + tempHJianju > pagePrintHeight) {//处理超页
                if (m_mainPageSetting.islandScape) {
                    //横向页面，自动分两栏
                    if (m_xStart == 0) {
                        //换到右边栏
                        m_xStart = pagePrintWidth + m_pdfWriter->margins().right / 25.4 * 300;
                        m_yStart = 0;
                    }
                    else {
                        //已经用完第二栏，需要新建页面
                        if (m_mainPageSetting.isDoublePage) {//如果是双面打印，则重新设置页面信息
                            if (m_isOddPage) {
                                //当前为奇数页，则下一个为偶数页，需要更换左右边距
                                tempMargin.setLeft(m_mainPageSetting.pageMarMargins.right());
                                tempMargin.setRight(m_mainPageSetting.pageMarMargins.left());
                            }
                            m_pdfWriter->setPageMargins(tempMargin, QPageLayout::Millimeter);//用毫米作为单位
                        }
                        m_pdfWriter->newPage();
                        m_yStart = 0;
                        m_xStart = 0;
                        //改变奇偶页信息
                        m_isOddPage = !m_isOddPage;
                    }
                }
                else {
                    //纵向页面需要新建页面
                    if (m_mainPageSetting.isDoublePage) {//如果是双面打印，则重新设置页面信息
                        //左右边距需要更换
                        if (m_isOddPage) {
                            //当前为奇数页，则下一个为偶数页，需要更换左右边距
                            tempMargin.setLeft(m_mainPageSetting.pageMarMargins.right());
                            tempMargin.setRight(m_mainPageSetting.pageMarMargins.left());
                        }
                        m_pdfWriter->setPageMargins(tempMargin, QPageLayout::Millimeter);//用毫米作为单位
                    }
                    m_pdfWriter->newPage();
                    m_yStart = 0;
                    //改变奇偶页信息
                    m_isOddPage = !m_isOddPage;
                }
            }
            else {
                m_yStart += tempHJianju;
            }
            //开始打印
            QString leftStr = metricTemp.elidedText(msgTemp, Qt::ElideRight, pagePrintWidth);
            int leftNum = leftStr.length();//获取可打印字符串长度
            recTemp = QRectF(m_xStart, m_yStart, pagePrintWidth, height);
            //            qDebug()<<"打印文本："<<msgTemp<<pagePrintWidth<<m_pdfWriter->margins().right/25.4*300;
            if (!isCenter)
                m_pPainter->drawText(recTemp, Qt::AlignLeft, msgTemp.left(leftNum));
            else
                m_pPainter->drawText(recTemp, Qt::AlignCenter, msgTemp.left(leftNum));
            //打印位置向下移动一个字符高度
            m_yStart = m_yStart + height;
            //获取剩下的字符串
            msgTemp = msgTemp.right(msgTemp.length() - leftNum);
        }
    }
}

bool CServiceBackend::writeText(QString text, QString styleName, SectionPointer section, bool isquestion)
{
    try {
        // 按照 \n 或 \n\r 字符为分割，分成一个 QStringList 变量
        //如果直接写入text,里面的换行符就会变成软回车，即向下箭头，导致分页错误
        QStringList tempList = text.split(QRegularExpression("[\n\r]+"));
        for (const QString& temp : tempList) {
            if (temp.isEmpty())//如果是空行，则跳过
                continue;
            ParagraphPointer para = section->addParagraph();
            RichTextPointer richtext = para->addRichText(temp.toStdString());
            para->prop_.style_ = styleName.toStdString();
            if (isquestion)
                richtext->prop_.color_ = "white";//如果是简答题的问题，则设置为白色
        }
    }
    catch (const Exception& ex) {
        m_error = QString::fromLocal8Bit(ex.what());
        //截取关键信息
        m_error.remove(0, 10);
        emit error();
        return false;
    }
    return true;
}

void CServiceBackend::xiPaiVector(QVector<int>* vector)
{
    if (vector->size() >= 2) {
        srand(time(NULL));
        for (int i = vector->size() - 1;i > 0;i--) {
            int j = rand() % (i + 1);
            vector->swapItemsAt(i, j);
        }
    }
}

bool CServiceBackend::writeQuestionOrAnswer(bool isQuestion, qreal hJianju)
{
    int tiXingXuhao = 1;//用来保存题型序号
    QString msgTemp;
    QFontMetricsF metricTemp(m_mainPageSetting.hcFont);
    QSizeF sizeTemp;
    for (int i = 0;i < m_testPaperSet.size();i++) {
        //        if(m_itemBankMsg[m_testPaperSet.key(i)]==0)
        if (m_typeNew.at(i).totalCount == 0)//某题型数量为0
            continue;
        int msgColum;//题型所在列,从0开始编号的,第三列为试题信息
        if (isQuestion) {
            msgColum = 3;
        }
        else
            msgColum = 5;
        //按顺序打印各题型
        //        for(auto key : m_tiMuNumList.keys()){//遍历某一题型中的题目
        QVector<int>* tiMuNumListTemp = &m_tiMuNumList[m_testPaperSet.key(i)];//获取题型列表
        if (m_testPaperSet.at(i).count != 0 && m_testPaperSet.at(i).score != 0) {//数量和分值都不能为零
            //打印一级标题
            msgTemp = numberToChinese(tiXingXuhao) + "、" + m_testPaperSet.key(i) + "（每题" + QString::number(m_testPaperSet.at(i).score) + "分）";
            tiXingXuhao += 1;
            //打印标题
            m_pPainter->setFont(m_mainPageSetting.h2Font);
            metricTemp = m_pPainter->fontMetrics();//字体发生变化以后要重新获取一次
            sizeTemp = metricTemp.size(Qt::TextSingleLine, msgTemp);
            writeText(msgTemp, m_mainPageSetting.h2Font, hJianju, hJianju, false, 2);
            //打印试题
            //随机抽取
            if (isQuestion)
                xiPaiVector(tiMuNumListTemp);//试题洗牌，答案不用洗牌，否则答案不正确
            if (m_sheet) {
                if (isQuestion || (m_testPaperSet.key(i) != "单选题" && m_testPaperSet.key(i) != "多选题" && m_testPaperSet.key(i) != "判断题")) {
                    for (int a = 0; a < m_testPaperSet.at(i).count;a++) {
                        int tempTiHao = a % tiMuNumListTemp->size();//如果数量超过题库数量，则取模选题
                        QString tiMuTemp;
                        if (m_sheet->cellType(tiMuNumListTemp->at(tempTiHao), msgColum) == CELLTYPE_STRING) {
                            const wchar_t* tiMu = m_sheet->readStr(tiMuNumListTemp->at(tempTiHao), msgColum);
                            tiMuTemp = QString::fromStdWString(tiMu);
                        }
                        else if (m_sheet->cellType(tiMuNumListTemp->at(tempTiHao), msgColum) == CELLTYPE_NUMBER) {
                            double tiMu = m_sheet->readNum(tiMuNumListTemp->at(tempTiHao), msgColum);
                            tiMuTemp = QString::number(tiMu, 'f');
                        }
                        else {
                            m_error = "第" + QString::number(tiMuNumListTemp->at(tempTiHao) + 1) + "行，第" + QString::number(msgColum + 1) + "列数据类型错误,必须为数字或者字符串";
                            //                            qDebug()<<"读取数据错误："<<m_error;
                            return false;
                        }
                        tiMuTemp = QString::number(a + 1) + "、" + tiMuTemp;//题目前面添加题号
                        writeText(tiMuTemp, m_mainPageSetting.hcFont, hJianju, hJianju, false, 2);
                        if (m_testPaperSet.key(i) == "简答题" && isQuestion) {//简答题试题
                            //简答题还要上答案，确保留下答题空间；只需要把颜色换成透明
                            QPen oldPen = m_pPainter->pen();
                            m_pPainter->setPen(QColor("transparent"));//使用透明字
                            QString daAnTemp;
                            if (m_sheet->cellType(tiMuNumListTemp->at(tempTiHao), msgColum + 2) == CELLTYPE_STRING) {
                                const wchar_t* daAn = m_sheet->readStr(tiMuNumListTemp->at(tempTiHao), msgColum + 2);
                                daAnTemp = QString::fromStdWString(daAn);
                            }
                            else if (m_sheet->cellType(tiMuNumListTemp->at(tempTiHao), msgColum + 2) == CELLTYPE_NUMBER) {
                                double daAn = m_sheet->readNum(tiMuNumListTemp->at(tempTiHao), msgColum + 2);
                                daAnTemp = QString::number(daAn, 'f');
                            }
                            else {
                                m_error = "第" + QString::number(tiMuNumListTemp->at(tempTiHao) + 1) + "行，第" + QString::number(msgColum + 3) + "列数据类型错误,必须为数字或者字符串";
                                qDebug() << "试题：" << m_error;
                                return false;
                            }
                            daAnTemp += "\n空\n空\n空";//多空3行避免不够,后面加空字，避免全空行会被自动去除
                            writeText(daAnTemp, m_mainPageSetting.hcFont, hJianju, hJianju, false, 2);
                            m_pPainter->setPen(oldPen);
                        }
                    }
                }
                else {
                    QString answerGroup;
                    for (int a = 0; a < m_testPaperSet.at(i).count; a++) {
                        int tempTiHao = a % tiMuNumListTemp->size();
                        QString answerTemp;
                        if (m_sheet->cellType(tiMuNumListTemp->at(tempTiHao), msgColum) == CELLTYPE_STRING) {
                            const wchar_t* answer = m_sheet->readStr(tiMuNumListTemp->at(tempTiHao), msgColum);
                            answerTemp = QString::fromStdWString(answer);
                        }
                        else if (m_sheet->cellType(tiMuNumListTemp->at(tempTiHao), msgColum) == CELLTYPE_NUMBER) {
                            double answer = m_sheet->readNum(tiMuNumListTemp->at(tempTiHao), msgColum);
                            answerTemp = QString::number(answer, 'f');
                        }
                        else {
                            m_error = "第" + QString::number(tiMuNumListTemp->at(tempTiHao) + 1) + "行，第" + QString::number(msgColum + 1) + "列数据类型错误,必须为数字或者字符串";
                            //                            qDebug() << "读取数据错误：" << m_error;
                            return false;
                        }
                        answerGroup += answerTemp + " ";
                        if ((a + 1) % 5 == 0 || a == m_testPaperSet.at(i).count - 1) {
                            QString groupMsg;
                            if (a - (a % 5) + 1 == qMin(a + 1, m_testPaperSet.at(i).count)) {
                                groupMsg = QString::number(qMin(a + 1, m_testPaperSet.at(i).count)) + "：" + answerGroup.trimmed();
                            }
                            else {
                                groupMsg = QString::number(a - (a % 5) + 1) + "-" + QString::number(qMin(a + 1, m_testPaperSet.at(i).count)) + "：" + answerGroup.trimmed();
                            }
                            writeText(groupMsg, m_mainPageSetting.hcFont, hJianju, hJianju, false, 2);
                            answerGroup.clear();
                        }
                    }
                }
            }
            else {
                m_error = "无法读取Excel文件！";
                return false;
            }

        }
        //        }


    }
    return true;
}

bool CServiceBackend::writeTestPaperDocx(bool isQuestion, SectionPointer section)
{
    int tiXingXuhao = 1;//用来保存题型序号
    bool ret = true;//保存docx调用情况
    QString msgTemp;
    int msgColum;//题型所在列,从0开始编号的,第三列为试题信息
    if (isQuestion) {
        msgColum = 3;
    }
    else
        msgColum = 5;
    for (int i = 0;i < m_testPaperSet.size();i++) {
        if (m_typeNew.at(i).totalCount == 0)//某题型数量为0
            continue;
        QVector<int>* tiMuNumListTemp = &m_tiMuNumList[m_testPaperSet.key(i)];//获取题型列表
        if (m_testPaperSet.at(i).count != 0 && m_testPaperSet.at(i).score != 0) {//数量和分值都不能为零
            //打印一级标题
            msgTemp = numberToChinese(tiXingXuhao) + "、" + m_testPaperSet.key(i) + "（每题" + QString::number(m_testPaperSet.at(i).score) + "分）";
            tiXingXuhao += 1;
            //打印标题
            ret = writeText(msgTemp, "MyHeadingH2", section, false);
            if (!ret)
                return false;//出现错误
            //打印试题
            //随机抽取
            if (isQuestion)
                xiPaiVector(tiMuNumListTemp);//试题洗牌，答案不用洗牌，否则答案不正确
            if (m_sheet) {
                if (isQuestion || (m_testPaperSet.key(i) != "单选题" && m_testPaperSet.key(i) != "多选题" && m_testPaperSet.key(i) != "判断题")) {
                    for (int a = 0; a < m_testPaperSet.at(i).count;a++) {
                        int tempTiHao = a % tiMuNumListTemp->size();//如果数量超过题库数量，则取模选题
                        QString tiMuTemp;
                        if (m_sheet->cellType(tiMuNumListTemp->at(tempTiHao), msgColum) == CELLTYPE_STRING) {
                            const wchar_t* tiMu = m_sheet->readStr(tiMuNumListTemp->at(tempTiHao), msgColum);
                            tiMuTemp = QString::fromStdWString(tiMu);
                        }
                        else if (m_sheet->cellType(tiMuNumListTemp->at(tempTiHao), msgColum) == CELLTYPE_NUMBER) {
                            double tiMu = m_sheet->readNum(tiMuNumListTemp->at(tempTiHao), msgColum);
                            tiMuTemp = QString::number(tiMu, 'f');
                        }
                        else {
                            m_error = "第" + QString::number(tiMuNumListTemp->at(tempTiHao) + 1) + "行，第" + QString::number(msgColum + 1) + "列数据类型错误,必须为数字或者字符串";
                            return false;
                        }
                        tiMuTemp = QString::number(a + 1) + "、" + tiMuTemp;//题目前面添加题号
                        ret = writeText(tiMuTemp, "MyHeadingHc", section, false);
                        if (!ret)
                            return false;//出现错误
                        if (m_testPaperSet.key(i) == "简答题" && isQuestion) {//简答题试题
                            //简答题还要上答案，确保留下答题空间；只需要把颜色换成透明
                            QString daAnTemp;
                            if (m_sheet->cellType(tiMuNumListTemp->at(tempTiHao), msgColum + 2) == CELLTYPE_STRING) {
                                const wchar_t* daAn = m_sheet->readStr(tiMuNumListTemp->at(tempTiHao), msgColum + 2);
                                daAnTemp = QString::fromStdWString(daAn);
                            }
                            else if (m_sheet->cellType(tiMuNumListTemp->at(tempTiHao), msgColum + 2) == CELLTYPE_NUMBER) {
                                double daAn = m_sheet->readNum(tiMuNumListTemp->at(tempTiHao), msgColum + 2);
                                daAnTemp = QString::number(daAn, 'f');
                            }
                            else {
                                m_error = "第" + QString::number(tiMuNumListTemp->at(tempTiHao) + 1) + "行，第" + QString::number(msgColum + 3) + "列数据类型错误,必须为数字或者字符串";
                                qDebug() << "试题：" << m_error;
                                return false;
                            }
                            daAnTemp += "\n空\n空\n空";//多空3行避免不够,后面加空字，避免全空行会被自动去除
                            ret = writeText(daAnTemp, "MyHeadingHc", section, true);
                            if (!ret)
                                return false;//出现错误
                        }
                    }
                }
                else {
                    QString answerGroup;
                    for (int a = 0; a < m_testPaperSet.at(i).count; a++) {
                        int tempTiHao = a % tiMuNumListTemp->size();
                        QString answerTemp;
                        if (m_sheet->cellType(tiMuNumListTemp->at(tempTiHao), msgColum) == CELLTYPE_STRING) {
                            const wchar_t* answer = m_sheet->readStr(tiMuNumListTemp->at(tempTiHao), msgColum);
                            answerTemp = QString::fromStdWString(answer);
                        }
                        else if (m_sheet->cellType(tiMuNumListTemp->at(tempTiHao), msgColum) == CELLTYPE_NUMBER) {
                            double answer = m_sheet->readNum(tiMuNumListTemp->at(tempTiHao), msgColum);
                            answerTemp = QString::number(answer, 'f');
                        }
                        else {
                            m_error = "第" + QString::number(tiMuNumListTemp->at(tempTiHao) + 1) + "行，第" + QString::number(msgColum + 1) + "列数据类型错误,必须为数字或者字符串";
                            return false;
                        }
                        answerGroup += answerTemp + " ";
                        if ((a + 1) % 5 == 0 || a == m_testPaperSet.at(i).count - 1) {
                            QString groupMsg;
                            if (a - (a % 5) + 1 == qMin(a + 1, m_testPaperSet.at(i).count)) {
                                groupMsg = QString::number(qMin(a + 1, m_testPaperSet.at(i).count)) + "：" + answerGroup.trimmed();
                            }
                            else {
                                groupMsg = QString::number(a - (a % 5) + 1) + "-" + QString::number(qMin(a + 1, m_testPaperSet.at(i).count)) + "：" + answerGroup.trimmed();
                            }
                            ret = writeText(groupMsg, "MyHeadingHc", section, false);
                            if (!ret)
                                return false;//出现错误
                            answerGroup.clear();
                        }
                    }
                }
            }
        }
    }
    return true;
}

QString CServiceBackend::numberToChinese(int num)
{
    if (num < 0 || num >99999) {
        m_error = "标题序号超出范围，请确保一级标题在0~99999之间";
        emit error();
        return QString("超出范围");
    }
    static const QVector<QString> units = { "","十","百","千","万" };
    static const QVector<QString> digits = { "零","一","二","三","四","五","六","七","八","九" };
    QString result;
    int unitIndex = 0;
    while (num > 0) {
        int digit = num % 10;//取余数
        if (digit != 0) {
            result.prepend(digits[digit] + units[unitIndex]);
        }
        else {
            if (!result.isEmpty() && result[0] != "零") {
                result.prepend(digits[digit]);
            }
        }
        num /= 10;//取商
        unitIndex++;
    }
    //处理特殊情况，10-19的数字
    if (result.size() > 2 && result.mid(0, 2) == "一十") {
        result = result.mid(1);
    }
    return result;
}

void CServiceBackend::readTypeSettings()
{//获取上次保留的数值
    QString filePath;
    filePath = QCoreApplication::applicationDirPath() + "/typeSettings.ini";
    //    qDebug()<<"设置文件"<<filePath;
    QSettings settings(filePath, QSettings::IniFormat);
    QString jsonString = settings.value("typeSettings").toString();
    QStringList keys = settings.value("typeList").toStringList();
    m_typeStore.clear();
    if (jsonString != "") {
        QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonString.toUtf8());
        QJsonObject jsonRoot = jsonDoc.object();
        //        qDebug()<<"读取数据"<<jsonRoot<<keys;
        for (const QString& key : keys) {
            QJsonValue value = jsonRoot.value(key);
            QJsonArray array = value.toArray();
            //读取，里面某有总题数，需要自己设置
//            qDebug()<<"读取数据"<<array.at(1).toString()<<array.at(1).toString().toDouble();
            m_typeStore.append(key, QuestionType(0, array.at(0).toInt(), array.at(1).toDouble()));
        }
    }
}

QVariantList CServiceBackend::checkZuJuan(QString tittle)
{
    QString errorMsg;
    QString warningMsg;
    int errorNum = 0;//错误信息序号
    int warningNum = 0;
    QString typeTemp;//题型名称暂存
    //严重错误
    //缺少标题，缺少有效题目即总分为0
    if (tittle == "") {
        errorNum += 1;
        if (errorNum > 1)//第二行开始要换行
            errorMsg += "\n";
        errorMsg += "    " + QString::number(errorNum) + ".未设置试卷标题！";
    }
    //警告信息
    //某一题型出题数量超出总数，某一题型未设置出题数量或分值没有相关题目，总分不是100分
    if (m_totalFenzhi == 0) {
        errorNum += 1;
        if (errorNum > 1)//第二行开始要换行
            errorMsg += "\n";
        errorMsg += "    " + QString::number(errorNum) + ".必须设置至少1种有效题型！";
    }
    for (int i = 0;i < m_tableModel->rowCount();i++) {//遍历表格
        if (m_tableModel->data(m_tableModel->index(i, 2)).toInt() > m_tableModel->data(m_tableModel->index(i, 1)).toInt()) {
            //出题数量超过总题数
            typeTemp = m_tableModel->data(m_tableModel->index(i, 0)).toString();
            warningNum += 1;
            if (warningNum > 1)//第二行开始要换行
                warningMsg += "\n";
            //            warningMsg +="    "+ QString::number(warningNum) +"."+typeTemp+"总分为0，试卷中将不会出现"+typeTemp+"！";
            warningMsg += "    " + QString::number(warningNum) + "." + typeTemp + "出题数量超过题库中该题型数量，将出现重复试题！";
        }
        //某一题型总分值为0
        if (m_tableModel->data(m_tableModel->index(i, 2)).toString() == "" || m_tableModel->data(m_tableModel->index(i, 3)).toString() == "" \
            || m_tableModel->data(m_tableModel->index(i, 2)).toInt() == 0 || m_tableModel->data(m_tableModel->index(i, 3)).toDouble() == 0) {
            typeTemp = m_tableModel->data(m_tableModel->index(i, 0)).toString();
            warningNum += 1;
            if (warningNum > 1)//第二行开始要换行
                warningMsg += "\n";
            warningMsg += "    " + QString::number(warningNum) + "." + typeTemp + "设置总分值为0，试卷中将不会出现" + typeTemp + "！";
        }
    }

    //总分不是100分
    if (m_totalFenzhi != 100) {
        warningNum += 1;
        if (warningNum > 1)//第二行开始要换行
            warningMsg += "\n";
        warningMsg += "    " + QString::number(warningNum) + ".试卷总分值不是100分！";
    }
    return { errorMsg,warningMsg };
}

QVariantList CServiceBackend::getFenzhi()
{
    m_totalFenzhi = 0;
    m_totalTimu = 0;
    for (int i = 0;i < m_tableModel->rowCount();i++) {//遍历表格
        if (m_tableModel->data(m_tableModel->index(i, 2)).toString() != "" && m_tableModel->data(m_tableModel->index(i, 3)).toString() != "" \
            && m_tableModel->data(m_tableModel->index(i, 2)).toInt() != 0 && m_tableModel->data(m_tableModel->index(i, 3)).toDouble() != 0) {
            m_totalFenzhi += m_tableModel->data(m_tableModel->index(i, 2)).toInt() * m_tableModel->data(m_tableModel->index(i, 3)).toDouble();
            m_totalTimu += m_tableModel->data(m_tableModel->index(i, 2)).toInt();
        }
    }
    return { m_totalTimu,m_totalFenzhi };
}

void CServiceBackend::testPaperSetClear()
{
    m_tableModel->clearUserSet();
}



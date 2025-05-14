# 1 关于编译运行
# 1.1 添加 Excel 文件读取库的配置

在工程文件中添加
```cpp
INCLUDEPATH = F:/MyProject/libxl-3.8.3.0/include_cpp
LIBS += F:/MyProject/libxl-3.8.3.0/lib64/libxl.lib
```
根据自己实际情况添加，64位编译器必须使用对应库，如果使用lib/libxl.lib，就会出现找不到xlCreateBook和xlCreateXMLBook的错误 2. 将 bin\libxl.dll(32 位编译器时)或bin 64\libxl.dll（64 位编译器时）复制到编译目录下，在“项目->构建目录”中查看编译目录
## 1.2 需要编译器支持 C++20
```cpp
CONFIG += c++20
```
由于我是用的 `Qt 5.14` 自带编译器为 `mingw 7.3.0` 并不支持 C++20 特性，我自己安装了 `mingw 13.1.0` ，安装后将该编译器的 `\bin` 目录添加到系统环境变量中，这样 `QtCreator` 就可以识别到该编译器。通过 `QtCreator` 的 `工具->选项->kits` 下的【编译器】标签下有一个【auto-detection settings】，点击它就能识别到。然后转到【构建套件】标签下，点击【添加】按钮，自行添加新的编译器套件，其中 Compiler 编译器必须选择新安装 `mingw 13.1.0` ，`qt version` 需要选择当前使用的版本，比如我用的 `Qt 5.14 Mingw64`。
## 1.3 将项目libxl 目录下的 libxl.dll复制到编译目录下
否则，编译可以通过，但程序无法正常运行。
## 1.4 添加 [minidocx库](https://gitee.com/totravel/minidocx)
需要自行编译，编译 minidocx库的编译器必须与编译本程序的编译器版本一致，否则本程序编译会出错，也就是说，如果你使用的编译器不是我用的 `mingw 13.1.0` 版本，需要自行编译 minidocx 库，然后添加到工程文件中：
```cpp
#minidocx
# 添加minidocx头文件路径
INCLUDEPATH += $$PWD/./minidocx/include
# 添加minidocx库路径,-L 指定库文件目录， -l 指定库文件名（去掉lib前缀和.so/.a/.dll等后缀）
LIBS += -L$$PWD/./minidocx/lib -llibminidocx
```

# 2 使用说明
1. 题库格式要按照"题库模板.xls"的格式，也支持xlsx文件
2. 题库对应的工作表名称必须是"题库"
3. 点击【导入题库按钮】，将自动打开最近一次打开的文件夹
4. 如果你打开“使用上次出题设置”，软件能够自动保存组题设置（包括上次的题型顺序、出题数量和分值），如果本次打开的题型与上次不同，则软件会尽量使用上次题库中的题型和设置进行，新增题型按照题库中出现的顺序依次排在后面；如果没有打开“使用上次出题设置”，则默认按照题库中各题型出现的顺序排列，且出题数量和分值都设置为 0；
5. 拖动组题设置表格中题型名称可以调整题型输出的顺序；
6. 设置成横向页面后，如果输出为PDF文件，则自动分2栏显示；如果选择Docx文件则不分栏；
7. 项目使用的是 [minidocx库](https://gitee.com/totravel/minidocx) （感谢该库作者的支持，感兴趣的可以收藏学习），如果选择输出为docx文件暂时不支持将考生信息输出至侧面、双面等功能，用户可以使用Office软件自行更改；
8. 此次更新对生成的答案进行了优化，单选题、多选题、判断题会按照 5 个一组进行组合，节约纸张并且方便批改

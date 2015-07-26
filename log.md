#### 7/17/2015 12:17:53 PM 

程序建立完毕，使用之前注意事项：

- 配置BOM数据源，ODBC驱动

- 配置排产文件位置以及格式

优化了程序结构：

- 处理端放在Server之前，避免重复的计算。

- 下一步考虑管道操作进一步简化代码。

- 实现了材料的查询功能。

---

#### 7/20/2015 9:00:40 AM 
 
- 优化了data.frame空行处理的逻辑。

#### 7/20/2015 1:37:13 PM

- 加入了夜班。

---

#### 7/21/2015 8:23:31 AM 

- 增加了SNOW，BF code 修正为Bead code

- add `reactiveTimer` 计时器 200 sec

- add `withProcess` & current time

---

#### 7/23/2015 10:55:46 AM 

- add schedule & delect td column
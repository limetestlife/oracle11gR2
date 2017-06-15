==========================================
**        启动和关闭数据库实例          **
==========================================
lsnrctl start --启动监听
lsnrctl status --监听状态
lsnrctl stop --关闭监听

sqlplus / as sysdba --进入sqlplus
startup[nomount|mount|open|force][resetrict][pfile=filename] --启动数据库
nomount;启动实例不加载数据库
mount;启动实例，加载数据库并保持数据库关闭
open；启动实例，加载并打开数据库。默认选项
force;终止实例并重新启动数据库
resetrict;以受限制的会话方式启动数据库
pfile;用于指定启动实例时所使用的文本参数化

shutdown--关闭数据库
normal;正常方式关闭。默认值
transactional;当前事物活动被提交完毕后，关闭数据库
immediate;立即关闭
abort;终止方式关闭


==========================================
**        oracle11g体系结构             **
==========================================
--1、逻辑存储结构



--2、物理存储结构

--3、服务器结构


--4、数据字典









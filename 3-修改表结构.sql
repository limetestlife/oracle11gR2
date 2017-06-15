--修改表结构，语法
alter table aateat add column_name|modify column_name|drop column column_name

--增加字段
alter table aateat add isbn varchar2(20);
--修改列
alter table aateat modify publish varchar2(80) not null;
/*  删除列
删除列相对于其他DDL[drop column]操作是一个耗时的事情，因为删除各列之后，必须重新构造各行来删除列的数据。
如果删除没有用过的列最好用【set unused】alter table tablename drop unused column;这样就会把所有没有用过的列全部去掉
*/
alter table aateat drop column isbn;
alter table aate set unused column publish; --标记未使用的列

--重命名列
alter table aate rename column isbn to iss;

--重命名表
rename aateat to aate;
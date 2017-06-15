--简单查询
select * from rbac_user;
select t.id,t.loginname,t.groupid from rbac_user t;
--带有表达式的查询
select t.groupid||'你好' 变量 from rbac_user t;
select distinct t.groupid from rbac_user t;
--筛选查询  <,>,<>,!,=,>=,<=,all,any,like,not like,in,not in,between and,not bettween and,is null 
select * from rbac_user t where t.groupid = '930000';
select * from rbac_user t where t.groupid like '930%';
select * from rbac_user t where t.groupid = any('930000','930100');
--分组查询,常和聚合函数一起使用。之后对聚合函数进行筛选用having
select t.groupid,sum(t.valid) from rbac_user t where t.groupid = any('930000','930100') group by t.groupid having sum(t.valid)>7;
--排序查询  order by desc倒序 asc默认正序
select t.groupid from rbac_user t where t.groupid like '930%' group by t.groupid order by t.groupid desc;
--多表关联查询,表别名
select ru.* from rbac_user ru,rbac_group rg where ru.groupid = rg.id and rg.name='北京分行风险管理处';
--内连接
select ru.* from rbac_user ru join rbac_group rg where ru.groupid = rg.id and rg.name='北京分行风险管理处';





---------------------------------------------------------------------
grant create any trigger to my;--给用户创建触发器的权限

---------------------------------------------------------------------
--准备环境，创建触发器要操作的表，创建触发器写入的日志表。


CREATE TABLE T3 (NAME VARCHAR2(20),MONEY NUMBER);
INSERT INTO T3 VALUES ('A',10);
INSERT INTO T3 VALUES ('B',20);
CREATE TABLE T4 (NAME VARCHAR2(20),MONEY NUMBER);
INSERT INTO T4 VALUES ('A',30);
INSERT INTO T4 VALUES ('C',20);
COMMIT;

create table dep_log(operate_tag varchar2(10),operate_tab varchar2(30),operate_time date); 
  
--创建语句级（行级）触发器,定义在表上
create or replace trigger tri_my  before insert or update or delete on t3  
  for each row --去掉for each row后就会变成只触发一次。
declare
  var_tag varchar2(10);
begin
   if inserting then --可以写成inserting(name)，这样就是对name这个字段监控更新。
     var_tag:='插入';
   elsif updating then
     var_tag:='修改';
   elsif deleting then
     var_tag:='删除';
   end if;
   insert into dep_log values(var_tag,sysdate);
end tri_my;
-------------------------------------------------------------------
--用户事件触发器环境准备。
create table ddl_log(
dname varchar2(20),
dtype varchar2(20),
daction varchar2(20),
duser varchar2(20),
ddate date
);
--创建用户事件触发器，定义在用户上。
create or replace trigger tri_ddl
  before create or alter or drop
  on my.schema
begin
  insert into ddl_log values
  (ora_dict_obj_name,--操作的数据对象名称；
  ora_dict_obj_type,--操作的数据对象类型；
  ora_sysevent,--系统事件名称；
  ora_login_user,--登陆用户；
  sysdate);--系统时间。
end;
---------------------------------------------------------------------
--替换触发器，定义在视图上。




---------------------------------------------------------------------

--删除触发器
drop trigger TRI_DEP_LOG;

--禁用表上的所有触发器
alter table table_name disable all triggers;

--关闭特定的触发器；
alter trigger tri_my disable;
--开启特定的触发器
alter trigger tri_my enable;

--查询所有的触发器
select * from all_triggers;
--查询特定表的触发器。
select * from all_triggers t where t.TABLE_NAME='MI';

------------------------------------------------------------------------
--批量生成创建触发器脚本
select
'create or replace trigger tri_'||tb.tname||'  before insert or update or delete on '||tb.tname||
' declare
  var_tag varchar2(10);'||
'begin
   if inserting then 
     var_tag:='||chr(39)||'插入'||chr(39)||';'||
   'elsif updating then
     var_tag:='||chr(39)||'修改'||chr(39)||';'||
   'elsif deleting then
     var_tag:='||chr(39)||'删除'||chr(39)||';'||
   'end if;'||
   'insert into dep_log values(var_tag,sysdate);'||
'end tri_'||tb.tname||';'
from (select T.TABLE_NAME tname from all_tables t where t.OWNER='MY') tb;

--批量创建触发器的存储过程
create or replace procedure create_trigger is
 v_tablename varchar2(30);
 v_sql varchar2(1000);
 cursor cur_table is select t.TABLE_NAME from all_tables t where t.OWNER='MY' and t.TABLE_NAME<>'DEP_LOG';
begin
  open cur_table;
  fetch cur_table into v_tablename;
  while cur_table%found 
     loop          
          v_sql:='create or replace trigger tri_'||v_tablename||'  before insert or update or delete on '||v_tablename||
                ' declare
                  var_tag varchar2(10);'||
                'begin
                   if inserting then 
                     var_tag:='||chr(39)||'插入'||chr(39)||';'||
                   'elsif updating then
                     var_tag:='||chr(39)||'修改'||chr(39)||';'||
                   'elsif deleting then
                     var_tag:='||chr(39)||'删除'||chr(39)||';'||
                   'end if;'||
                   'insert into dep_log values(var_tag,sysdate);'||
                'end tri_'||v_tablename||';';
          execute immediate v_sql;
          fetch cur_table into v_tablename;
     end loop;
end create_trigger;




--生成批量关闭触发器的脚本
select 'alter trigger tri_'||tb.tname|| ' disable;'
from (select T.TABLE_NAME tname from all_tables t where t.OWNER='TC') tb;
--批量关闭触发器的存储过程
create or replace procedure alter_trigger_disable is
 v_tablename varchar2(30);
 v_drop_sql varchar2(1000);
 cursor cur_table is select t.TABLE_NAME from all_tables t where t.OWNER='MY' and t.TABLE_NAME<>'DEP_LOG';
begin
  --dbms_output.enable(buffer_size=>null);
  open cur_table;
  fetch cur_table into v_tablename;
  while cur_table%found 
     loop          
          v_drop_sql:='alter trigger TRI_'||v_tablename||' disable';
          dbms_output.put_line(v_drop_sql);
          execute immediate v_drop_sql;
          fetch cur_table into v_tablename;
     end loop;
end alter_trigger_disable;

--生成批量开启触发器的脚本
select
'alter trigger tri_'||tb.tname|| ' enable;'
from (select T.TABLE_NAME tname from all_tables t where t.OWNER='MY') tb;
--批量开启触发器的存储过程
create or replace procedure alter_trigger_disable is
 v_tablename varchar2(30);
 v_drop_sql varchar2(1000);
 cursor cur_table is select t.TABLE_NAME from all_tables t where t.OWNER='MY' and t.TABLE_NAME<>'DEP_LOG';
begin
  --dbms_output.enable(buffer_size=>null);
  open cur_table;
  fetch cur_table into v_tablename;
  while cur_table%found 
     loop          
          v_drop_sql:='alter trigger TRI_'||v_tablename||' enable';
          dbms_output.put_line(v_drop_sql);
          execute immediate v_drop_sql;
          fetch cur_table into v_tablename;
     end loop;
end alter_trigger_disable;
--生成批量删除触发器的脚本
select
'drop trigger tri_'||tb.tname|| ';'
from (select T.TABLE_NAME tname from all_tables t where t.OWNER='MY') tb;
--删除触发器的存储过程
create or replace procedure drop_trigger is
 v_tablename varchar2(30);
 v_drop_sql varchar2(1000);
 cursor cur_table is select t.TABLE_NAME from all_tables t where t.OWNER='MY' and t.TABLE_NAME<>'DEP_LOG';
begin
  open cur_table;
  fetch cur_table into v_tablename;
  while cur_table%found 
     loop          
          v_drop_sql:='drop trigger TRI_'||v_tablename;
          dbms_output.put_line(v_drop_sql);
          execute immediate v_drop_sql;
          fetch cur_table into v_tablename;
     end loop;
end drop_trigger;


-------------------------------------------------------------------------





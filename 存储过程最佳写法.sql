---------------------------------------------------
--在存储过程中执行的创建语句都必须显示赋权，如创建表，创建触发器
--grant create table to user_name;
--在存储过程中不区分大小写，故在区分参数时不能像java一样用大小写区分
--
--
--
--
--
-----------------------------------------------------





-------------在plsql developer中创建存储过程，在新建>>程序窗口---------------------------
=======
--语法
=======
create or replace procedure test(Name in out type, Name in out type, ...) is --创建（重建）带有传入和传出参数的存储过程
 --定义变量
 --定义游标
begin
 --逻辑主体
exception
  --异常处理
  when too_many_rows then
    
end test;
===================
--无参数的存储过程。
===================
create procedure in_dept is
begin
 insert into dept values(70,'www','www');
end;
========================
--调用过程,在命令窗口中
========================
SQL > exec in_dept;
SQL > call in_dept;--建议用该方法，应该方法通用，对于其他数据库也使用，在JAVA中也会使用它。


--删除记录的过程
create or replace procedure de_dept(in_deptno number) is
begin
  delete from dept where deptno=in_deptno;
end;
--**********************************************************-----
pl/sql 可以做什么？
1 可以开发过程
2 开发函数
3 开发包
4 开发触发器
他们的基本测试单元是块。

注释 
单行 --
多行/**/
定义变量 v_sal
定义常量 c_sql
定义游标 emp_cursor;
定义例外 e_error;

---块（bock)的语法-------------------
declare 
  -- Local variables here
  i integer;
begin
  -- Test statements here
exception
  --获取异常
end;
---------最简单的块,只有begin和end----
SQL > set serveroutput on;
SQL > begin
       -- Test statements here
       dbms_output.put_line('hello word');
     end;
--在默认情况下，不会输出hello word，需要set serveroutput on;
----
declare 
  v_ename varchar2(20);
begin
  select ename into v_ename from emp where empno=&empno;
  dbms_output.put_line(v_ename);
end;
--改成过程--
create procedure pro3(in_empno number) is 
  v_ename varchar2(20);
begin
  select ename into v_ename from emp where empno=in_empno;
  dbms_output.put_line(v_ename);
end;
-------------Java中调用过程,存储过程是可以有返回值的。-----------------------

create or replace procedure insert_dept(
num_deptno in number,
var_ename in varchar2,
var_loc in varchar2) is
begin
  insert into dept values(num_deptno,var_ename,var_loc);
  commit;
end insert_dept;

---
create or replace procedure select_dept(
       num_deptno in number,
       var_dname out dept.dname%type,
       var_loc out dept.loc%type) is
begin
  select dname,loc into var_dname,var_loc from dept where deptno=num_deptno;
exception
  when no_data_found then
    dbms_output.put_line('该部门不存在');
end select_dept;



-------------函数--------------------------
create function 函数名(参数)  return 返回的数据类型 is
--定义变量
begin
--执行语句
end;
--创建
create or replace function fun1(in_v_ename varchar2) return number is
  v_sal number;
begin
  select sal*13 into v_sal from emp where ename=in_v_ename;
  return v_sal;
end;

--调用
SQL> select fun1('SMITH') from dual;


---包，可以更好的管理自己写的函数和过程---
create package 包名 is
	--声明函数
	function ... return ...;
	--声明过程
	procedure ;
end;

--包的例子
create package mypack1 is
       procedure pro1(in_v_ename varchar2,v_in_sal number);
       function fun1(v_in_name varchar2) return number;    
end;

--包体，写包体之前应该有包，是用于包中声明的函数和过程实现--

--异常判断
exception
  when others then
      dbms_output.put_line('进入异常');
end;



-------------------------------------------------
--在涉及到其他用户下的表操作时，在执行存储过程时回报表或试图不存在的错误。
 grant select,insert,update,delete on tc.AFRPINT to my;
 grant select any table to userName;

--在存储过程中，解决查不到数据时的报错方法
 select (SELECT t.pkid FROM wfdir t where rownum=1)  from dual ;


-----------------------------------------------------------------------------
--异常处理，在执行存储过程中需要有异常处理机制，而有异常后应打印日志

--1，创建记录日志的表
create table pub_proc_err_log(log_id number,module_name varchar2(100),proc_name varchar2(100),err_time date,sql_code varchar2(50),sql_errm varchar2(100),err_content varchar2(500));
 
--2,创建序列
create sequence seq_record_proc_err minvalue 1 maxvalue 999999999999999999999 start with 21 increment by 1 cache 20;

--3.通用记录错误的存储过程
create or replace procedure record_proc_err_log(module_name varchar2,
                                                proc_name   varchar2,
                                                v_sqlcode   varchar2,
                                                v_sqlerrm   varchar2,
                                                v_err_line  varchar2) is
begin
  insert into pub_proc_err_log
    (log_id,
     module_name,
     proc_name,
     err_time,
     sql_code,
     sql_errm,
     err_content)
  values
    (seq_record_proc_err.nextval,
     module_name,
     proc_name,
     sysdate,
     v_sqlcode,
     v_sqlerrm,
     v_err_line);
  commit;
end record_proc_err_log;

--4引用
 

 
 
--------------------------------------------------------------------------
--打印日志的另一种思路
--创建一张表
create table cbct_log(table_name varchar2(50),column_name varchar2(500),column_values varchar2(500),ctype varchar2(50),c_data date);



--------------------------------------------------------------------------
=================================
======编写存储过程的思路=========
=1、为数据上线用的零时存储过程  =
=2、在批量程序中使用的存储过程  =
=3、程序中调用的公用存储过程    =
=================================

-------------------------------------------------
--存储过程的测试，新建一个测试窗口
-------------------------------------------------


/*1、零时存储过程的编写
		需要考虑数据数目的对应关系，若是一对一的关系需考虑查出多条或没有查出数据的错误情况。
		在零时的存储过程中不能简单的把异常抓取到后就不管
		抓取到异常后必须给予精准的提示，
		给予客户选择的项，是继续还是回退
		记录日志到本地的txt文件
*/






/*2、批量中的存储过程
	大的并发量
	记录日志，在数据库中的错误日志表中
	设计通用的错误日志表和记录错误日志的存储过程，以便所用的批量程序都能记录到该日志中
*/






/*3、平常业务调用的的存储过程
		写成通用的方法，以便方法的复用
		在参数中有传入参数和传出参数（非必需）
		必须异常捕获，给予精准提示
*/












--------------------------------------------------------------------------

====================
==  存储过程模版  ==
====================

--循环一个游标
create or replace test is
   var_oldzh gszh.oldzh%type;
   cursor cur_gszh is select oldzh from gszh;
begin
   open cur_gszh
   fetch cur_gszh into var_oldzh;
   while cur_gszh%found loop    
		--sql主体   
     fetch cur_gszh into row_gszh;
   end loop;
   close cur_gszh;
end test;

--用for循环遍历游标，比显示遍历游标更简单
create or replace procedure test is
  cursor cur_gszh is select * from gszh;
begin
  for gszh_row in cur_gszh loop
    dbms_output.put(gszh_row.oldzh);
  end loop;
end test;

--for循环的使用
-- Created on 2016/11/21 by LIANG_MENG 
declare 
begin
   for v_a in -5..5 loop
     dbms_output.put_line(v_a);
   end loop;
end;




execute immediate 时不要在语句中出现DDL的操作。这样会使得前面出现的修改数据语句提交，导致一致性被破坏，无法回退。









--------------------------------------------------------------
=======================================================
==					存储过程案例					 ==
=======================================================












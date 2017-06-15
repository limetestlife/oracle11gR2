/*
语法：
MERGE [hint] INTO [schema .] table [t_alias] USING [schema .] 
{ table | view | subquery } [t_alias] ON ( condition ) 
WHEN MATCHED THEN merge_update_clause 
WHEN NOT MATCHED THEN merge_insert_clause;

*/



--1、基本用法
merge into tt using emp on (emp.empno=tt.empno and emp.ename=tt.ename)
when matched then
update set tt.sal=emp.sal
when not matched then
insert values (emp.empno,emp.ename,emp.job,emp.mgr,emp.hiredate,emp.sal,emp.comm,emp.deptno);


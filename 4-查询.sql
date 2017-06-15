--语法
select [distinct|all] --去重
select_list 		  --占位符
from table_name 	  --表名
[where ]              --查询条件
[group by ]			  --对结果集进行分组，通常与聚合函数一起用
[HAVING ]             --返回选取的结果集中行三数目
[order by ]           --排序

--sql执行顺序
1、from
2、where
3、group by 
4、having
5、order by 
6、
conn user_n/n@(DESCRIPTION=(ADDRESS_LIST =(ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.202.171)(PORT = 1521)))(CONNECT_DATA =(SERVICE_NAME = xdgl)));

set echo off     --设置start启动的脚本中的每个sql命令，默认值是on,即执行的所有sql命令都会显示出来。     
set feedback off --显示本次sql命令处理的记录条数，默认为on,即输出      
set heading off   --输出域标题，默认值为on     
set verify off        
set trimspool off  --去除重定向输出每行的拖尾空格，默认值为on
set pagesize 1000 --输出每页行数，默认值是24，为避免分页可以设为0
set linesize 653 --输出一行字符的个数，默认值是80。

spool systime.txt
select value from pmsysparam where code='0001';
spool off
quit

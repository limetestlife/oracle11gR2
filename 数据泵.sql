
--常规数据泵
<<!
LIME 2016-7-6
执行脚本前修改用户名和密码，备份数据存放路径
该脚本只用于oaracle 11G
备份路径文件夹必须赋予其他用户的可写权限
修改环境变量
!

USERID=tc
PASSWORD=tc
fileName=`date +'%Y%m%d%H%M%S'`
sysDate=`date +'%Y-%m-%d %H:%M:%S'`
schemasUser=tc
dbBakPath=/cmisbatch/oradata_bak/$fileName

export LC__FASTMSG=true
export LOCPATH=/usr/lib/nls/loc
export LOGIN=cmis
export MAILMSG='[YOU HAVE NEW MAIL]'
export NLSPATH=/usr/lib/nls/msg/%L/%N:/usr/lib/nls/msg/%L/%N.cat:/usr/lib/nls/msg/%l.%c/%N:/usr/lib/nls/msg/%l.%c/%N.cat
export ODMDIR=/etc/objrepos
export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
export MAIL=/var/spool/mail/oracle
export ORACLE_BASE=/oracle/app/oracle
export ORACLE_BIN=/oracle/app/oracle/product/11.2.0/db_1/bin
export ORACLE_HOME=/oracle/app/oracle/product/11.2.0/db_1
export ORACLE_SID=xdgl
export PATH=/oracle/app/oracle/product/11.2.0/db_1/bin:/usr/bin:/etc:/usr/sbin:/usr/ucb:/home/oracle/bin:/usr/bin/X11:/sbin:.

if [ ! -d "$dbBakPath" ];
then
	mkdir -p -m 777 $dbBakPath 
else
	chmod 777 $dbBakPath 
fi

sqlplus $USERID/$PASSWORD<<EOF
create or replace directory dump as '$dbBakPath';
grant read,write on directory dump to system;
EOF

expdp $USERID/$PASSWORD directory=dump dumpfile=$fileName.dmp logfile=$fileName.log full=y compression=ALL
--多线程导出
expdp $USERID/$PASSWORD directory=dump dumpfile=$fileName.dmp logfile=$fileName.log full=y compression=ALL parallel=4


--导出和导入不含数据的空库,在导出时加只导数据库结构，在导入时加，不论dmp文件有无数据都只导入数据库结构
content=METADATA_ONLY;


exit 

-----------------------------------------------
#!/bin/bash
#************************************************************#
#该脚本在oracle账户下执行                                    #
#执行前需做的工作有                                          #
#1)创建备份目录：mkdir -p -m 766 $dbBakPath                  #
#2)为目录更改所有者及所属组：chown -R oracle:dba $dbBakPath  #
#3)更改用户名和密码及备份目录。								 #
#************************************************************#

USERID=user_o
PASSWORD=o
fileName=`date +'%Y%m%d%H%M'`
schemasUser=tt
dbBakPath=/oradata/dump

#mkdir -p -m 766 $dbBakPath

sqlplus / as sysdba<<EOF
create or replace directory dump as '$dbBakPath';
grant read,write on directory dump to $USERID;
EOF

impdp $USERID/$PASSWORD directory=dump dumpfile=20160926230006.dmp remap_tablespace='(INDX:USER_OLD,USERS:USER_OLD)' remap_schema=eximuser:user_o
#remap_tablespace=USERS:TT remap_schema=eximuser:tt
#remap_tablespace=USERS:JYUAT remap_schema=$USERID:$USERID
#content=METADATA_ONLY
exit 




--现在要把197数据库的eximuser_yw用户下的数据导入到194库的te用户下
--在本地库创建远程连接
-- Drop existing database link 
drop database link EXIMUSER_YW;
-- Create database link 
create database link EXIMUSER_YW
  connect to EXIMUSER_YW
  using '(DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.202.197)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = xdgl197)
    )
  )';
--为远程用户赋予权限
grant exp_full_database to eximuser_yw;





--常见问题
--查询数据泵的所有任务
select * from dba_datapump_jobs;




导入报错ORA-39151的错
ORA-39151: Table "SYSTEM"."REPCAT$_REPSCHEMA" exists. All dependent metadata and data will be skipped due to table_exists_action of skip
添加两个参数，
SKIP_UNUSABLE_INDEXES=Y
TABLE_EXISTS_ACTION=TRUNCATE

ORA-39083: Object type TABLESPACE failed to create with error:
对象创建错误，其后面会跟随着错误的原因。

ORA-02236: invalid file name


ORA-07443: function VERIFY_FUNCTION_11G not found
对象没找到

ORA-31684: Object type USER:"OUTLN" already exists
对象已经存在

--约束类型有五种：主键，外键，唯一，检查，非空

--在Oracle中建立一张具有所有约束条件及添加注释的表
/*
1、在建立表时，后面不会跟随数据表存放的表空间，其会存放在默认表空间中。
2、有两种创建表的方式：1.规范创建。2.子查询创建

*/
create table aateat(
     bookid int not null, 
     bookname char not null,
     publish varchar2(20),
     pubdate varchar2(20),
     price decimal(7,2),
     author char,
     store int default 0,
     reader int,
     remarks varchar2(50),
     constraint ck_price check(price>=10 and price<=100) , --检查约束
     constraint un_bookname unique (bookname),--唯一性约束
     constraint fk_publish foreign key(publish) references publishinfo(publishid) --外键
);

create table publishinfo(
       publishid varchar2(20) primary key, --主键
       publishname varchar2(30)
);
/*
子查询创建表
子查询创建出来的表和原表结构一致。
列上所有的非空约束和检查约束和原表一致。
主键，唯一值，外键则不会随着一起创建。
*/
create table table_name as select * from table_name

/*  创建和使用临时表
临时表与永久表类似；都有
*/





--删除约束条件
alter table aateat drop [constraint] FK_PUBLISH;
---------------------------------------------------------------------------------------------
-- Create table
create table PUBLISHINFO
(
  PUBLISHID   VARCHAR2(20) not null,
  PUBLISHNAME VARCHAR2(30)
)
tablespace USER_OLD
  pctfree 10
  initrans 1
  maxtrans 255;
-- Create/Recreate primary, unique and foreign key constraints 
alter table PUBLISHINFO
  add primary key (PUBLISHID)
  using index 
  tablespace USER_OLD
  pctfree 10
  initrans 2
  maxtrans 255;


-- Create table
create table AATEAT
(
  BOOKID   INTEGER not null,
  BOOKNAME CHAR(1) not null,
  PUBLISH  VARCHAR2(20),
  PUBDATE  VARCHAR2(20),
  PRICE    NUMBER(7,2),
  AUTHOR   CHAR(1),
  STORE    INTEGER default 0,
  READER   INTEGER,
  REMARKS  VARCHAR2(50)
)
tablespace USER_OLD
  pctfree 10
  initrans 1
  maxtrans 255;
-- Create/Recreate primary, unique and foreign key constraints 
alter table AATEAT
  add constraint UN_BOOKNAME unique (BOOKNAME)
  using index 
  tablespace USER_OLD
  pctfree 10
  initrans 2
  maxtrans 255;
alter table AATEAT
  add constraint FK_PUBLISH foreign key (PUBLISH)
  references PUBLISHINFO (PUBLISHID);
-- Create/Recreate check constraints 
alter table AATEAT
  add constraint CK_PRICE
  check (price>=10 and price<=100);

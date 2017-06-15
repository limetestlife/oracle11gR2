--------------------------------------------------
-- Export file for user TCTEST                  --
-- Created by liang_meng on 2016/6/30, 11:09:42 --
--------------------------------------------------

spool cunchu.log

drop table DEP_LOG;

prompt

prompt Creating table DEP_LOG
prompt ======================
prompt

create table DEP_LOG
(
  OPERATE_TAG  VARCHAR2(10),
  OPERATE_TAB  VARCHAR2(30),
  OPERATE_TIME DATE
)
;

prompt
prompt Creating procedure ALTER_TRIGGER_DISABLE
prompt ========================================
prompt
create or replace procedure alter_trigger_disable is
 v_tablename varchar2(30);
 v_drop_sql varchar2(200);
 cursor cur_table is select t.TABLE_NAME from user_tables t where t.TABLE_NAME<>'DEP_LOG';
begin
  --dbms_output.enable(buffer_size=>null);
  open cur_table;
  fetch cur_table into v_tablename;
  while cur_table%found
     loop
          v_drop_sql:='alter trigger '||v_tablename||' disable';
          --dbms_output.put_line(v_drop_sql);
          execute immediate v_drop_sql;
          fetch cur_table into v_tablename;
     end loop;
end alter_trigger_disable;
/

prompt
prompt Creating procedure ALTER_TRIGGER_ENABLE
prompt =======================================
prompt
create or replace procedure alter_trigger_enable is
 v_tablename varchar2(30);
 v_drop_sql varchar2(200);
  cursor cur_table is select t.TABLE_NAME from user_tables t where t.TABLE_NAME<>'DEP_LOG';
begin
  --dbms_output.enable(buffer_size=>null);
  open cur_table;
  fetch cur_table into v_tablename;
  while cur_table%found
     loop
          v_drop_sql:='alter trigger '||v_tablename||' enable';
          --dbms_output.put_line(v_drop_sql);
          execute immediate v_drop_sql;
          fetch cur_table into v_tablename;
     end loop;
end alter_trigger_enable;
/

prompt
prompt Creating procedure CREATE_TRIGGER
prompt =================================
prompt
create or replace procedure create_trigger is

 v_tablename varchar2(30);
 v_sql varchar2(500);

  cursor cur_table is select t.TABLE_NAME from user_tables t where t.TABLE_NAME<>'DEP_LOG';
begin
  --dbms_output.enable(buffer_size=>null);
  open cur_table;
  fetch cur_table into v_tablename;
  while cur_table%found
     loop
          --dbms_output.put_line(v_tablename);
          v_sql:='create or replace trigger '||v_tablename||'  before insert or update or delete on '||v_tablename||
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
                   'insert into dep_log values(var_tag,'||chr(39)||v_tablename||chr(39)||',sysdate);'||
                'end '||v_tablename||';';
          --dbms_output.put_line(v_sql);
          execute immediate v_sql;
          fetch cur_table into v_tablename;
     end loop;
end create_trigger;
/

prompt
prompt Creating procedure DROP_TRIGGER
prompt ===============================
prompt
create or replace procedure drop_trigger is
 v_tablename varchar2(30);
 v_drop_sql varchar2(200);
  cursor cur_table is select t.TABLE_NAME from user_tables t where t.TABLE_NAME<>'DEP_LOG';
begin
  open cur_table;
  fetch cur_table into v_tablename;
  while cur_table%found
     loop
          v_drop_sql:='drop trigger '||v_tablename;
          --dbms_output.put_line(v_drop_sql);
          execute immediate v_drop_sql;
          fetch cur_table into v_tablename;
     end loop;
end drop_trigger;
/

exec create_trigger;

spool off


--------------------------------------------------
-- Export file for user MY                      --
-- Created by liang_meng on 2016/7/15, 17:58:37 --
--------------------------------------------------

spool recover.log

prompt
prompt Creating procedure RECOVER
prompt ==========================
prompt
create or replace procedure recover(userName in varchar2) is
   v_table varchar2(40);
   truncate_sql varchar2(100);
   copy_sql varchar2(100);
   cursor cur_tables is select t.operate_tab from batch_table t; 
begin 
   open cur_tables;
   fetch cur_tables into v_table;
   while  cur_tables%found
     loop
        truncate_sql:='truncate table '||v_table;
        copy_sql:='insert into '||v_table||' select * from '||userName||'.'||v_table;
        execute immediate truncate_sql;
        execute immediate copy_sql;       
       fetch cur_tables into v_table; 
       commit;
     end loop;    
exception
  when others then
    rollback;
end;
/


spool off





drop table batch_table;
create table batch_table 
	as select distinct(t.operate_tab) from user_o.dep_log t;

drop table BATCH_RESULT;
create table BATCH_RESULT
(
  RESULT_TABLE VARCHAR2(50),
  RESULT_REASON VARCHAR2(500),
  RESULT_COUNT INTEGER
);

create or replace procedure get_result(userName in varchar2) is
  v_tablename varchar2(50);
  v_sql_1     varchar2(500);
  v_sql_2     varchar2(500);
  v_insert    varchar2(200);
  v_count_1   integer;
  v_count_2   integer;
  cursor cur_batch_table is
    select *
      from batch_table t
     where t.operate_tab not in ('MESS_MESSAGE', 'PMBATCHJOBSTATE');
begin
  execute immediate 'truncate table batch_result';
  open cur_batch_table;
  fetch cur_batch_table
    into v_tablename;
  while cur_batch_table%found loop
    v_sql_1 := 'select count(*) from (select * from ' || userName || '.' ||
               v_tablename || ' minus select * from ' || v_tablename || ')';
    v_sql_2 := 'select count(*) from (select * from ' || v_tablename ||
               ' minus select * from ' || userName || '.' || v_tablename || ')';
    execute immediate v_sql_1
      into v_count_1;
    execute immediate v_sql_2
      into v_count_2;
    if v_count_1 > 0 then
      v_insert := 'insert into batch_result values (' || chr(39) || 
                  v_tablename ||chr(39)|| ','|| chr(39) || '旧表比新表多' || chr(39) || ',' || v_count_1 || ')';
      execute immediate v_insert;
    end if;
    if v_count_2 > 0 then
      v_insert := 'insert into batch_result values (' || chr(39) || 
                  v_tablename ||chr(39)|| ','|| chr(39) || '新表比旧表多' || chr(39) || ',' || v_count_1 || ')';
      execute immediate v_insert;
    end if;
    commit;
    fetch cur_batch_table
      into v_tablename;
  end loop;
end get_result;
/

exec get_result(user_o);

---------------------------------------------------
-- Export file for user CF                       --
-- Created by liang_meng on 2016/11/25, 11:00:12 --
---------------------------------------------------

spool a.log

prompt
prompt Creating procedure CBTC
prompt =======================
prompt
create or replace procedure cbtc is
  -- 合同表 gccontactmain
  v_keycode gccontractmain.keycode%type; --合同编号

  -- 合同临时表 LCONTANT
  v_LCONTANT_row LCONTANT%rowtype;

  CURSOR LCONTANT_cur IS
    SELECT * FROM LCONTANT; --查询合同临时表所有记录的游标

  -- 船舶临时表 LSHIP
  v_LSHIP_row LSHIP%rowtype;

  CURSOR LSHIP_cur(COM_LNACC LCONTANT.LNACC%TYPE) IS
    SELECT * FROM LSHIP ship WHERE ship.LNACC = COM_LNACC; --查询船舶临时表所有记录的游标

  -- 借据临时表 LGCLOANCREDIT
  v_LGCLOANCREDIT_row LGCLOANCREDIT%rowtype;

  CURSOR LGCLOANCREDIT_cur(COM_GCSHIPCODE LSHIP.GCSHIPCODE%TYPE) IS
    SELECT * FROM LGCLOANCREDIT lgc WHERE lgc.GCSHIPCODE = COM_GCSHIPCODE; --查询借据临时表所有记录的游标

  -- 借据表 gcloancredit
  v_gcloancredit_row gcloancredit%rowtype;

  CURSOR gcloancredit_cur(COM_V_KEYCODE gccontractmain.keycode%TYPE) IS
    SELECT *
      FROM gcloancredit gcl
     WHERE gcl.upkeycode = COM_V_KEYCODE
       AND gcl.keyeffectedstate = '0002'
       AND gcl.keycode not like 'JYYZ000%'; --查询借据表老数据的游标

  -- 还款计划临时表 Lgccredplanpay
  v_Lgccredplanpay_row Lgccredplanpay%rowtype;

  CURSOR Lgccredplanpay_cur(COM_KEYCODE LGCLOANCREDIT.KEYCODE%TYPE) IS
    SELECT * FROM Lgccredplanpay lgc WHERE lgc.keycode = COM_KEYCODE; --查询还款计划临时表所有记录的游标

  -- CLCREDENCE表
  v_CLCREDENCE_row CLCREDENCE%rowtype;

  CURSOR CLCREDENCE_cur(COM_GCLKEYCODE GCLOANCREDIT.KEYCODE%TYPE) IS
    SELECT * FROM CLCREDENCE clc WHERE clc.creditreqcode = COM_GCLKEYCODE; --查询CLCREDENCE表所有记录的游标

  -- RRMAXLMTENGROSS表
  v_RRMAXLMTENGROSS_row RRMAXLMTENGROSS%rowtype;

  CURSOR RRMAXLMTENGROSS_cur(COM_GCLKEYCODE GCLOANCREDIT.KEYCODE%TYPE) IS
    SELECT *
      FROM RRMAXLMTENGROSS rrm
     WHERE rrm.CREDITKEYCODE = COM_GCLKEYCODE; --查询CLCREDENCE表所有记录的游标

  --合同授信品种表 gccredittypeinformation 三个字段（更新还款计划表）
  v_KEYTYPE         gccredittypeinformation.KEYTYPE%type;
  v_GCBUSINESSLEVEL gccredittypeinformation.GCBUSINESSLEVEL%type;
  v_GCSYSLEVEL      gccredittypeinformation.GCSYSLEVEL%type;
  v_oldkeycode      gcloancredit.keycode%type;

  -- 用于计算的临时变量
  v_rate            float; --新借据的贷款金额与老借据的贷款金额之比（用来拆分金额）
  v_moneyNew        float; --新借据的money之和
  v_moneyOld        float; --老借据的money值
  v_aoto_gct_rownum BINARY_INTEGER; -- 用来记录贷款账号关联到的合同表记录条数
  v_update_flag     BINARY_INTEGER := 1; ------------------------ 数据库更新标志  0为测试  1为执行更新  9清理表数据

begin
  OPEN LCONTANT_cur;
  FETCH LCONTANT_cur
    INTO v_LCONTANT_row;

  LOOP
    --循环临时表游标的所有记录
    exit when LCONTANT_cur%notfound;

    -- 根据贷款账号查询对应的合同授信品种信息表记录数目
    SELECT COUNT(1)
      INTO v_aoto_gct_rownum
      FROM gcCreditTypeInformation GCC
     WHERE GCC.COLUMN_07 = v_LCONTANT_row.LNACC
       AND KEYEFFECTEDSTATE = '0002';

    -- 根据贷款账号从授信业务品种表中获得合同表的合同编号
    SELECT GCC.KEYCODE
      INTO V_KEYCODE -- 合同表 合同编号
      FROM gcCreditTypeInformation GCC
     WHERE GCC.COLUMN_07 = v_LCONTANT_row.LNACC
       AND KEYEFFECTEDSTATE = '0002';

    -- 根据贷款账号从授信业务品种表中获得合同表的三个字段
    SELECT GCC.KEYTYPE
      INTO v_KEYTYPE
      FROM gcCreditTypeInformation GCC
     WHERE GCC.COLUMN_07 = v_LCONTANT_row.LNACC
       AND KEYEFFECTEDSTATE = '0002';

    SELECT GCC.GCBUSINESSLEVEL
      INTO v_GCBUSINESSLEVEL
      FROM gcCreditTypeInformation GCC
     WHERE GCC.COLUMN_07 = v_LCONTANT_row.LNACC
       AND KEYEFFECTEDSTATE = '0002';

    SELECT GCC.GCSYSLEVEL
      INTO v_GCSYSLEVEL
      FROM gcCreditTypeInformation GCC
     WHERE GCC.COLUMN_07 = v_LCONTANT_row.LNACC
       AND KEYEFFECTEDSTATE = '0002';

    -- 取得授信业务品种表关联到的合同表记录条数
    SELECT COUNT(1)
      INTO v_aoto_gct_rownum
      FROM gccontractmain GCT
     WHERE GCT.KEYCODE = V_KEYCODE
       AND KEYEFFECTEDSTATE = '0002';

    IF v_update_flag = 1 THEN
      -- 根据合同编号更新合同表
      update gccontractmain gc
         SET gc.CENTRALIZEFLAG = '2' --分散集中标识为2
       WHERE gc.keycode = v_keycode;

      update gccontractmain gc
         SET gc.ISSHIPFINANCING = '1' --是否船舶融资按船计息置为1 是
       WHERE gc.keycode = v_keycode;

      update gccontractmain gc
         SET gc.toleratedate = '3' --容忍期为3天
       WHERE gc.keycode = v_keycode;
    END IF;

    -- 打开船舶临时表的游标
    OPEN LSHIP_cur(v_LCONTANT_row.LNACC);
    FETCH LSHIP_cur
      INTO v_LSHIP_row;
    LOOP
      EXIT WHEN LSHIP_cur%NOTFOUND;

      IF v_update_flag = 1 THEN
        --根据船舶编号插入船舶表
        INSERT INTO gccontractshipinfo gcs
        values
          (v_LSHIP_row.GCSHIPCODE,
           v_LSHIP_row.SHIPNAME,
           v_LSHIP_row.SHIPFINANCEBUSI,
           v_LSHIP_row.MILLIONTONNAGE,
           v_LSHIP_row.BUSISUM,
           v_LSHIP_row.BUSISUMUNIT,
           v_LSHIP_row.ISHIGHTECHNOLOGY,
           v_LSHIP_row.PROMISEMONEY,
           V_KEYCODE,
           v_LSHIP_row.EFFECTSTATE,
           v_LSHIP_row.OPERSIGN,
           v_LSHIP_row.RELESHIPCODE,
           v_LSHIP_row.AMOUNTMONEY,
           v_LSHIP_row.USEDMONEY,
           v_LSHIP_row.AVAILABLEMONEY,
           v_LSHIP_row.ISLOAN);

        INSERT INTO datatranslogs
        VALUES
          ('UPDATE_gccontractshipinfo',
           v_LCONTANT_row.lnacc,
           V_KEYCODE,
           v_LSHIP_row.GCSHIPCODE,
           '',
           '',
           '当前根据船舶编号插入船舶表，船舶编号为: ' || v_LSHIP_row.GCSHIPCODE);

      END IF;

      --取得合同编号关联到的借据表记录条数
      SELECT count(1)
        INTO v_aoto_gct_rownum
        FROM gcloancredit
       WHERE upkeycode = V_KEYCODE
         AND KEYEFFECTEDSTATE = '0002'
         AND keycode not like 'JYYZ%';

      --查询原来的借据数据（行）
      OPEN gcloancredit_cur(V_KEYCODE);
      FETCH gcloancredit_cur
        INTO v_gcloancredit_row;
      CLOSE gcloancredit_cur;

      --测试此贷款账号下所有对应的新借据money和是否与老借据的money值相同
      IF v_update_flag = 0 THEN
        SELECT SUM(lgcl.money)
          INTO v_moneyNew
          FROM LGCLOANCREDIT lgcl
         WHERE lgcl.gcshipcode IN
               (SELECT gcshipcode
                  FROM lship
                 WHERE lnacc = '1360000100000779545');

        v_moneyOld := v_gcloancredit_row.money;

        IF v_moneyNew != v_moneyOld THEN
          INSERT INTO datatranslogs
          VALUES
            ('ERROR_money',
             v_LCONTANT_row.lnacc,
             V_KEYCODE,
             v_LSHIP_row.GCSHIPCODE,
             '',
             '',
             '新借据money之和与老借据money值不同！:' || v_moneyNew || ' , ' ||
             v_moneyOld);

        END IF;

      END IF;

      -- 打开借据表临时表的游标
      OPEN LGCLOANCREDIT_cur(v_LSHIP_row.GCSHIPCODE);
      FETCH LGCLOANCREDIT_cur
        INTO v_LGCLOANCREDIT_row;
      LOOP
        EXIT WHEN LGCLOANCREDIT_cur%NOTFOUND;

        IF v_update_flag = 1 THEN

          --记录老借据号
          v_oldkeycode := v_gcloancredit_row.KEYCODE;

          ---替换查出的老借据中的keycode
          v_gcloancredit_row.KEYCODE := v_LGCLOANCREDIT_row.KEYCODE;
          ---将替换过keycode的老借据数据插入到借据表中
          INSERT INTO gcloancredit VALUES v_gcloancredit_row;

          ----将借据临时表数据更新到新插入的借据信息表数据中
          UPDATE gcloancredit
             SET GCSHIPCODE = v_LGCLOANCREDIT_row.GCSHIPCODE
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET Column_08 = v_LGCLOANCREDIT_row.Column_08
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET oldCoreCode = v_LGCLOANCREDIT_row.oldCoreCode
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET money = v_LGCLOANCREDIT_row.money
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET payeeName = v_LGCLOANCREDIT_row.payeeName
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET lnUsing = v_LGCLOANCREDIT_row.lnUsing
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET startDate = v_LGCLOANCREDIT_row.startDate
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET fintrstRateFlag = v_LGCLOANCREDIT_row.fintrstRateFlag
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET fintrstRateMode = v_LGCLOANCREDIT_row.fintrstRateMode
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET fintrstRateBase = v_LGCLOANCREDIT_row.fintrstRateBase
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET frateLimit = v_LGCLOANCREDIT_row.frateLimit
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET fintrstRateFType = v_LGCLOANCREDIT_row.fintrstRateFType
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET fintrstRateFMethod = v_LGCLOANCREDIT_row.fintrstRateFMethod
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET fintrstRateFRate = v_LGCLOANCREDIT_row.fintrstRateFRate
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET fintrstRateFDot = v_LGCLOANCREDIT_row.fintrstRateFDot
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET fintrstRateChangePeriod = v_LGCLOANCREDIT_row.fintrstRateChangePeriod
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET fintrstRateChangeUnit = v_LGCLOANCREDIT_row.fintrstRateChangeUnit
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET intrstRateFlag = v_LGCLOANCREDIT_row.intrstRateFlag
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET intrstRateMode = v_LGCLOANCREDIT_row.intrstRateMode
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET intrstRateBase = v_LGCLOANCREDIT_row.intrstRateBase
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET rateLimit = v_LGCLOANCREDIT_row.rateLimit
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET intrstRateFType = v_LGCLOANCREDIT_row.intrstRateFType
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET intrstRateFMethod = v_LGCLOANCREDIT_row.intrstRateFMethod
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET intrstRateFRate = v_LGCLOANCREDIT_row.intrstRateFRate
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET loanRate = v_LGCLOANCREDIT_row.loanRate
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET intrstRateChangePeriod = v_LGCLOANCREDIT_row.intrstRateChangePeriod
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET intrstRateChangeUnit = v_LGCLOANCREDIT_row.intrstRateChangeUnit
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET overdueRateCountMethod = v_LGCLOANCREDIT_row.overdueRateCountMethod
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET overdueRate = v_LGCLOANCREDIT_row.overdueRate
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET divertRateCountMethod = v_LGCLOANCREDIT_row.divertRateCountMethod
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET divertRate = v_LGCLOANCREDIT_row.divertRate
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET intrstCountMethod = v_LGCLOANCREDIT_row.intrstCountMethod
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET firstInterestDate = v_LGCLOANCREDIT_row.firstInterestDate
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET repayInterestType = v_LGCLOANCREDIT_row.repayInterestType
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET lastRepayDate = v_LGCLOANCREDIT_row.lastRepayDate
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET isLastLoan = v_LGCLOANCREDIT_row.isLastLoan
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET firstPayDate = v_LGCLOANCREDIT_row.firstPayDate
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET firstRepayDate = v_LGCLOANCREDIT_row.firstRepayDate
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET intrstMod = v_LGCLOANCREDIT_row.intrstMod
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET payeeAccBankName = v_LGCLOANCREDIT_row.payeeAccBankName
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET column_14 = v_LGCLOANCREDIT_row.column_14
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;
          UPDATE gcloancredit
             SET repaytype = v_LGCLOANCREDIT_row.repaytype
           WHERE keycode = v_LGCLOANCREDIT_row.KEYCODE;

          --获取新借据与老借据中的贷款金额之比
          v_rate := v_LGCLOANCREDIT_row.money / v_gcloancredit_row.money;

          --获取老借据号所对应的老CLCREDENCE表数据条数
          SELECT COUNT(1)
            INTO v_aoto_gct_rownum
            FROM CLCREDENCE clc
           WHERE clc.creditreqcode = v_oldkeycode;

          IF v_aoto_gct_rownum != 0 THEN
            --拆分CLCREDENCE表金额

            --根据老借据号获得所对应的CLCREDENCE表的数据
            OPEN CLCREDENCE_cur(v_oldkeycode);
            FETCH CLCREDENCE_cur
              INTO v_CLCREDENCE_row;
            CLOSE CLCREDENCE_cur;
            ---替换查出的老借据中的keycode
            v_CLCREDENCE_row.creditreqcode := v_LGCLOANCREDIT_row.KEYCODE;
            ---将替换过keycode的老CLCREDENCE表数据插入到CLCREDENCE表中
            INSERT INTO CLCREDENCE VALUES v_CLCREDENCE_row;
            ----将拆分的金额更新到新插入的数据中
            UPDATE CLCREDENCE
               SET CTGUAUSEAMT = v_CLCREDENCE_row.CTGUAUSEAMT * v_rate
             WHERE creditreqcode = v_CLCREDENCE_row.creditreqcode;
            UPDATE CLCREDENCE
               SET NONGUAUSEAMT = v_CLCREDENCE_row.NONGUAUSEAMT * v_rate
             WHERE creditreqcode = v_CLCREDENCE_row.creditreqcode;
            UPDATE CLCREDENCE
               SET USEAMT = v_CLCREDENCE_row.USEAMT * v_rate
             WHERE creditreqcode = v_CLCREDENCE_row.creditreqcode;
            UPDATE CLCREDENCE
               SET RENEWAMT = v_CLCREDENCE_row.RENEWAMT * v_rate
             WHERE creditreqcode = v_CLCREDENCE_row.creditreqcode;
            UPDATE CLCREDENCE
               SET CTGUARENEWAMT = v_CLCREDENCE_row.CTGUARENEWAMT * v_rate
             WHERE creditreqcode = v_CLCREDENCE_row.creditreqcode;
            UPDATE CLCREDENCE
               SET NONGUARENEWAMT = v_CLCREDENCE_row.NONGUARENEWAMT * v_rate
             WHERE creditreqcode = v_CLCREDENCE_row.creditreqcode;

          END IF;

          --获取老借据号所对应的老RRMAXLMTENGROSS表数据条数
          SELECT COUNT(1)
            INTO v_aoto_gct_rownum
            FROM RRMAXLMTENGROSS rrm
           WHERE rrm.CREDITKEYCODE = v_oldkeycode;

          IF v_aoto_gct_rownum != 0 THEN
            --拆分RRMAXLMTENGROSS表金额

            --根据老借据号获得所对应的RRMAXLMTENGROSS表的数据
            OPEN RRMAXLMTENGROSS_cur(v_oldkeycode);
            FETCH RRMAXLMTENGROSS_cur
              INTO v_RRMAXLMTENGROSS_row;
            CLOSE RRMAXLMTENGROSS_cur;
            ---替换查出的老借据中的keycode
            v_RRMAXLMTENGROSS_row.CREDITKEYCODE  := v_LGCLOANCREDIT_row.KEYCODE;
            v_RRMAXLMTENGROSS_row.ENGROSSKEYCODE := v_LGCLOANCREDIT_row.KEYCODE;
            ---将替换过keycode的老RRMAXLMTENGROSS表数据插入到RRMAXLMTENGROSS表中
            INSERT INTO RRMAXLMTENGROSS VALUES v_RRMAXLMTENGROSS_row;
            ----将拆分的金额更新到新插入的数据中
            UPDATE RRMAXLMTENGROSS
               SET RENEWLMT = v_RRMAXLMTENGROSS_row.RENEWLMT * v_rate
             WHERE CREDITKEYCODE = v_RRMAXLMTENGROSS_row.CREDITKEYCODE;
            UPDATE RRMAXLMTENGROSS
               SET BALANCELMT = v_RRMAXLMTENGROSS_row.BALANCELMT * v_rate
             WHERE CREDITKEYCODE = v_RRMAXLMTENGROSS_row.CREDITKEYCODE;
            UPDATE RRMAXLMTENGROSS
               SET BASECURENGROSSLMT = v_RRMAXLMTENGROSS_row.BASECURENGROSSLMT *
                                       v_rate
             WHERE CREDITKEYCODE = v_RRMAXLMTENGROSS_row.CREDITKEYCODE;
            UPDATE RRMAXLMTENGROSS
               SET ENGROSSLMT = v_RRMAXLMTENGROSS_row.ENGROSSLMT * v_rate
             WHERE CREDITKEYCODE = v_RRMAXLMTENGROSS_row.CREDITKEYCODE;
            UPDATE RRMAXLMTENGROSS
               SET INITENGROSSLMT = v_RRMAXLMTENGROSS_row.INITENGROSSLMT *
                                    v_rate
             WHERE CREDITKEYCODE = v_RRMAXLMTENGROSS_row.CREDITKEYCODE;

            INSERT INTO datatranslogs
            VALUES
              ('UPDATE_rrmaxlmtengross',
               v_LCONTANT_row.lnacc,
               V_KEYCODE,
               v_LSHIP_row.GCSHIPCODE,
               v_LGCLOANCREDIT_row.KEYCODE,
               '',
               '该条RRMAXLMTENGROSS数据插入成功');

          END IF;

        END IF;

        --跟据合同编号删除凭证信息表中的数据
        IF v_update_flag = 9 THEN
          DELETE gcloancredit gcl
           WHERE gcl.upkeycode = V_KEYCODE
             AND gcl.keyeffectedstate = '0002'; ------------------------------------------------------------是否需要加状态标识

        END IF;

        -- 打开还款计划临时表的游标
        OPEN Lgccredplanpay_cur(v_LGCLOANCREDIT_row.KEYCODE);
        FETCH Lgccredplanpay_cur
          INTO v_Lgccredplanpay_row;
        LOOP
          EXIT WHEN Lgccredplanpay_cur%NOTFOUND;

          --将还款计划临时表数据插入到还款计划表
          IF v_update_flag = 1 THEN
            INSERT INTO gccredplanpay
              (keycode,
               sequenceno,
               lnrepayflag,
               planrevdate,
               amtmoney,
               keyeffectedstate,
               column_08,
               column_10,
               shipcode,
               KEYTYPE,
               GCBUSINESSLEVEL,
               GCSYSLEVEL,
               TERM)
            values
              (v_Lgccredplanpay_row.keycode,
               v_Lgccredplanpay_row.sequenceno,
               v_Lgccredplanpay_row.lnrepayflag,
               v_Lgccredplanpay_row.planrevdate,
               v_Lgccredplanpay_row.amtmoney,
               v_Lgccredplanpay_row.keyeffectedstate,
               v_Lgccredplanpay_row.column_08,
               v_Lgccredplanpay_row.column_10,
               v_Lgccredplanpay_row.shipcode,
               V_KEYTYPE,
               V_GCBUSINESSLEVEL,
               V_GCSYSLEVEL,
               '0');

          END IF;

          --还款计划表循环
          FETCH Lgccredplanpay_cur
            INTO v_Lgccredplanpay_row;
        END LOOP;
        CLOSE Lgccredplanpay_cur;
        --借据表循环
        FETCH LGCLOANCREDIT_cur
          INTO v_LGCLOANCREDIT_row;
      END LOOP;
      CLOSE LGCLOANCREDIT_cur;
      --船舶循环
      FETCH LSHIP_cur
        INTO v_LSHIP_row;
    END LOOP;
    CLOSE LSHIP_cur;

    --合同表循环
    FETCH LCONTANT_cur
      INTO v_LCONTANT_row;
  END LOOP;
  CLOSE LCONTANT_cur;
end cbtc;
/

prompt
prompt Creating procedure CBTC_1
prompt =========================
prompt
create or replace procedure cbtc_1 is
  CURSOR LCONTANT_cur IS
    SELECT lc.* FROM LCONTANT lc,gcloancredit gcl where
    lc.lnacc = gcl.lnacc and gcl.keyeffectedstate = '0002' and gcl.oldcorecode ='1' and gcl.keycode not like '%JYYZ%'; --查询合同临时表所有记录的游标

  v_LCONTANT_row   LCONTANT%rowtype;
  v_oldLoanKeycode VARCHAR2(100);
  v_newLoanKeycode VARCHAR2(100);
begin
  --遍历合同临时表
  OPEN LCONTANT_cur;
  LOOP
    FETCH LCONTANT_cur
      INTO v_LCONTANT_row;

    EXIT WHEN LCONTANT_cur%notfound;


    --查询出合同临时表对应的借据表中原有的集中借据的借据编号
    SELECT KEYCODE
      INTO v_oldLoanKeycode
      FROM GCLOANCREDIT GCL
     WHERE GCL.LNACC = v_LCONTANT_row.LNACC
       AND GCL.KEYCODE NOT LIKE 'JYYZ%'
       AND GCL.OLDCORECODE = '1'
       AND GCL.KEYEFFECTEDSTATE = '0002';


    --删除集中借据
    DELETE FROM GCLOANCREDIT GCL WHERE GCL.KEYCODE = v_oldLoanKeycode;


    --查询出借据临时表中生成的借据序号为1的借据编号

    SELECT KEYCODE
      INTO v_newLoanKeycode
      FROM LGCLOANCREDIT LGC, LCONTANT LCO, LSHIP LSH
     WHERE LCO.LNACC = LSH.LNACC
       AND LSH.GCSHIPCODE = LGC.GCSHIPCODE
       AND LCO.LNACC = v_LCONTANT_row.LNACC
       AND LGC.OLDCORECODE = '1'
       AND LGC.KEYCODE LIKE 'JYYZ%';

    --将老借据序号更新到借据表中
    UPDATE GCLOANCREDIT GCL
       SET GCL.KEYCODE = v_oldLoanKeycode
     WHERE GCL.KEYCODE = v_newLoanKeycode;


    --删除还款计划中keycode为老借据的记录
    DELETE FROM GCCREDPLANPAY GCC WHERE GCC.KEYCODE = v_oldLoanKeycode;


    --更新还款计划表中keycode字段
    UPDATE GCCREDPLANPAY GCC
       SET GCC.KEYCODE = v_oldLoanKeycode
     WHERE GCC.KEYCODE = v_newLoanKeycode;

    --更新还款计划表中column_08字段
    UPDATE GCCREDPLANPAY GCC
       SET GCC.COLUMN_08 = v_oldLoanKeycode
     WHERE GCC.COLUMN_08 = v_newLoanKeycode;

    --更新还款计划表中column_10字段
    UPDATE GCCREDPLANPAY GCC
       SET GCC.COLUMN_10 = v_oldLoanKeycode
     WHERE GCC.COLUMN_10 = v_newLoanKeycode;

  END LOOP;
  CLOSE LCONTANT_cur;
end cbtc_1;
/

prompt
prompt Creating procedure CBTC_2
prompt =========================
prompt
create or replace procedure cbtc_2 is
  sql1       varchar2(200);
  sql2       varchar2(200);
  sql3       varchar2(200);
  sql5       varchar2(200);
  sql6       varchar2(200);
  sql7       varchar2(500);
  var_number number := 1001;
  var_count  number;
  var_num    number := 0;

  var_gccredittypeinformation gccredittypeinformation%rowtype;
  --keycode gccontractshipinfo.keycode%type;
  var_gcloancredit_keycode gcloancredit.keycode%type;
  var_lnacc                lancctemp.lnacc%type;
  cursor cur_lancctemp is
    select lnacc from lancctemp;

  cursor cur_sql8(var_gccredittypeinformation gccredittypeinformation%rowtype) is
    select keycode
      from gcloancredit
     where upkeycode = var_gccredittypeinformation.keycode
       and Keyeffectedstate = '0002';
begin
  dbms_output.enable(buffer_size => null);
  open cur_lancctemp;
  fetch cur_lancctemp
    into var_lnacc;
  while cur_lancctemp%found loop
    INSERT INTO cbct_log
    VALUES
      ('gccredittypeinformation ',
       'column_07',
       var_lnacc || ',' || var_number,
       '插入',
       sysdate);

    sql1 := 'select * from gccredittypeinformation gc where gc.column_07 =''' ||
            var_lnacc || ''' and gc. Keyeffectedstate = ''0002''';
    execute immediate sql1
      into var_gccredittypeinformation;
    sql2 := 'insert into gccontractshipinfo (keycode,gcshipcode,isloan) values(''' ||
            var_gccredittypeinformation.keycode || ''',''' || 'virtua' ||
            var_number || ''',''2'')';
    execute immediate sql2;
    --打印日志-------------------------------------------------------------------------
    select count(*)
      into var_num
      from gccontractshipinfo
     where keycode = var_gccredittypeinformation.keycode
       and gcshipcode = 'virtua' || var_number
       and isloan = '2';
    if var_num = 1 then
      INSERT INTO cbct_log
      VALUES
        ('gccontractshipinfo',
         'keycode,gcshipcode,isloan',
         var_gccredittypeinformation.keycode || ',' || 'virtua' ||
         var_number || ',' || '2',
         '插入',
         sysdate);

    ELSIF var_num > 1 THEN
      INSERT INTO cbct_log
      VALUES
        ('gccontractshipinfo',
         'keycode,gcshipcode,isloan',
         var_gccredittypeinformation.keycode || '多个值，是错误性息',
         '插入',
         sysdate);

    elsif var_num = 0 then
      INSERT INTO cbct_log
      VALUES
        ('gccontractshipinfo',
         'keycode,gcshipcode,isloan',
         var_gccredittypeinformation.keycode || '插入失败',
         '插入',
         sysdate);

    END IF;
    -----------------------------------------------------------------

    sql3 := 'update gcloancredit set gcshipcode=''' || 'virtua' ||
            var_number || ''' where upkeycode=''' ||
            var_gccredittypeinformation.keycode ||
            ''' and Keyeffectedstate=''0002''';
    execute immediate sql3;
    -------------------------打印日志----------------------------------
    var_num := 0;
    select count(*)
      into var_num
      from gcloancredit
     where gcshipcode = 'virtua' || var_number;
    if var_num = 1 then
      INSERT INTO cbct_log
      VALUES
        ('gcloancredit',
         'gcshipcode',
         var_gccredittypeinformation.keycode || ',' || 'virtua' ||
         var_number || ',' || '2',
         '更新',
         sysdate);

    ELSIF var_num > 1 THEN
      INSERT INTO cbct_log
      VALUES
        ('gcloancredit',
         'gcshipcode',
         var_gccredittypeinformation.keycode || '多个值',
         '更新',
         sysdate);

    elsif var_num = 0 then
      INSERT INTO cbct_log
      VALUES
        ('gcloancredit',
         'gcshipcode',
         var_gccredittypeinformation.keycode || '没有更新',
         '更新',
         sysdate);

    END IF;
    --------------------------------------------------------------------
    open cur_sql8(var_gccredittypeinformation);
    fetch cur_sql8
      into var_gcloancredit_keycode;
    while cur_sql8%found loop
      --查询gccredplanpay表，有则改，没有不改。
      sql5 := 'select count(*) from gccredplanpay where keycode=''' ||
              var_gcloancredit_keycode ||
              ''' and keyeffectedstate=''0002'' and lnrepayflag in (''0'',''9'')';
      execute immediate sql5
        into var_count;
      if var_count is not null then
        sql6 := 'update gccredplanpay set shipcode=''' || 'virtua' ||
                var_number || ''' where keycode=''' ||
                var_gcloancredit_keycode ||
                ''' and keyeffectedstate=''0002'' and lnrepayflag in (''0'',''9'')';
        execute immediate sql6;
        ------------------------------------
        var_num := 0;
        select count(*)
          into var_num
          from gccredplanpay
         where shipcode = 'virtua' || var_number
           and keycode = var_gcloancredit_keycode
           and keyeffectedstate = '0002'
           and lnrepayflag in ('0', '9');
        if var_num = 1 then
          INSERT INTO cbct_log
          VALUES
            ('gccredplanpay',
             'shipcode',
             var_gcloancredit_keycode || ',' || 'virtua' || var_number || ',' || '2',
             '更新',
             sysdate);

        ELSIF var_num > 1 THEN
          INSERT INTO cbct_log
          VALUES
            ('gccredplanpay',
             'shipcode',
             var_gcloancredit_keycode || '多个值',
             '更新',
             sysdate);

        elsif var_num = 0 then
          INSERT INTO cbct_log
          VALUES
            ('gccredplanpay',
             'shipcode',
             var_gcloancredit_keycode || '没有更新',
             '更新',
             sysdate);

        END IF;
        -------------------------------------
        sql7 := 'insert into gccredplanpay select ''' || 'virtua' ||
                var_number ||
                ''',KEYTYPE,GCBUSINESSLEVEL,GCSYSLEVEL,SEQUENCENO,TERM,LNREPAYFLAG,PLANREVDATE,CURRENCY,AMTMONEY,REPAYENDDATE,COMMENTS,EDITIONNO,PLANSTATE,KEYEFFECTEDSTATE,KEYDATESTATE,COLUMN_01,COLUMN_02,COLUMN_03,COLUMN_04,COLUMN_05,COLUMN_06,COLUMN_07,COLUMN_08,COLUMN_09,COLUMN_10,PROCESSID,ITEMID,MODIFYFLAG,DATAORIGINFLAG,SHIPCODE,REMARKS from gccredplanpay where  keycode=''' ||
                var_gcloancredit_keycode ||
                ''' and keyeffectedstate=''0002'' and lnrepayflag in (''0'',''9'')';
        execute immediate sql7;
        ---------------------------------------
        var_num := 0;
        select count(*)
          into var_num
          from gccredplanpay
         where keycode = 'virtua' || var_number;
        INSERT INTO cbct_log
        VALUES
          ('gccredplanpay',
           'shipcode',
           'virtua' || var_number,
           '更新',
           sysdate);
        ---------------------------------------

      end if;

      fetch cur_sql8
        into var_gcloancredit_keycode;
    end loop;
    close cur_sql8;
    var_number := var_number + 1;
    fetch cur_lancctemp
      into var_lnacc;
  end loop;

end cbtc_2;
/

prompt
prompt Creating procedure DEALBALCARD
prompt ==============================
prompt
create or replace procedure dealBalCard(v_workDate in varchar2) is
  selectsql   varchar2(200);
  row_AFRPBAL AFRPBAL%rowtype;
  sqloanno    varchar2(200);
  sql_2       varchar2(200);
  sql_3       varchar2(200);
  sql_4       varchar2(200);
  sql_5       varchar2(200);
  v_keycode   varchar2(34);
  v_MiCONTNO  varchar2(34);
  v_PrOTSENO  varchar2(34);
  v_count     integer := 0;
   /******************************************************************************
      NAME:       dealBalCard
      PURPOSE:    澶勭悊璐锋缁煎悎璐︽埛浣欓鍗＄墖
      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        2016/07/21  姊佺寷             1. Created this procedure
   ******************************************************************************/
  cursor cur_AFRPBAL is
    select * from AFRPBAL;
begin
  open cur_AFRPBAL;
  fetch cur_AFRPBAL
    into row_AFRPBAL;
  while cur_AFRPBAL%found loop
    sqloanno := 'select (select keycode from GcLoanCredit where lnacc=''' ||
                row_AFRPBAL.Mediumid ||
                ''' and keyeffectedstate=''0002'' and rownum=1) from dual';
    execute immediate sqloanno
      into v_keycode;
    if v_keycode is null then
      sql_2 := 'select (select keycode from TlLoanCredit  where oldcorecode=''' ||
               row_AFRPBAL.Subserno || ''' and lnacc= ''' ||
               row_AFRPBAL.Mediumid ||
               ''' and keyeffectedstate=''0002'' and rownum=1) from dual';
      execute immediate sql_2
        into v_keycode;
      if v_keycode is null then
        sql_3 := 'select (select keycode from TlLoanCredit where lnacc= ''' ||
                 row_AFRPBAL.Mediumid ||
                 ''' and keyeffectedstate=''0002'' and rownum=1) from dual';
        execute immediate sql_3
          into v_keycode;
        dbms_output.put_line(sql_3 || ',' || v_keycode);
      end if;
    end if;
    if v_keycode is not null then
      sql_4 := 'select (select UpKeyCode from GcLoanCredit where keycode=''' ||
               v_keycode || '''and rownum=1) from dual';
      execute immediate sql_4
        into v_MiCONTNO;
      if v_MiCONTNO is null then
        sql_5 := 'select (select UpKeyCode from TlLoanCredit where keycode=''' ||
                 v_keycode || '''and rownum=1) from dual';
        execute immediate sql_5
          into v_MiCONTNO;
      end if;
    else
      v_MiCONTNO := v_keycode;
    end if;

    v_count   := v_count + 1;
    selectsql := 'select (select PrOTSENO  from miafrpBalAll where PrOTSENO=''' ||
                 row_AFRPBAL.Protseno || ''' and SuBSERNO=''' ||
                 row_AFRPBAL.Subserno || ''') from dual';
    dbms_output.put_line(selectsql);
    execute immediate selectsql
      into v_PrOTSENO;

    if v_PrOTSENO is null then
      insert into miafrpBalAll
        (ZONENO,
         WORKDATE,
         PROTSENO,
         SUBSERNO,
         CURRTYPE,
         PRTYCODE,
         PRSERNO,
         PCUSTNO,
         PCUSTNAM,
         MEDIUMID,
         MEDSENO,
         BALANCE1,
         BALANCE2,
         BALANCE3,
         BALANCE4,
         STATUS,
         miLoanNo,
         miContNo)
      values
        (row_AFRPBAL.ZONENO,
         v_workDate,
         row_AFRPBAL.PROTSENO,
         row_AFRPBAL.SUBSERNO,
         row_AFRPBAL.CURRTYPE,
         row_AFRPBAL.PRTYCODE,
         row_AFRPBAL.PRSERNO,
         row_AFRPBAL.PCUSTNO,
         row_AFRPBAL.PCUSTNAM,
         row_AFRPBAL.MEDIUMID,
         row_AFRPBAL.MEDSENO,
         row_AFRPBAL.BALANCE1,
         row_AFRPBAL.BALANCE2,
         row_AFRPBAL.BALANCE3,
         row_AFRPBAL.BALANCE4,
         row_AFRPBAL.STATUS,
         v_keycode,
         v_MiCONTNO);
    else
      update miafrpBalAll
         set WORKDATE = v_workDate,
             CURRTYPE = row_AFRPBAL.CURRTYPE,
             PRTYCODE = row_AFRPBAL.PRTYCODE,
             PRSERNO  = row_AFRPBAL.PRSERNO,
             PCUSTNO  = row_AFRPBAL.PCUSTNO,
             PCUSTNAM = row_AFRPBAL.PCUSTNAM,
             MEDIUMID = row_AFRPBAL.MEDIUMID,
             MEDSENO  = row_AFRPBAL.MEDSENO,
             BALANCE1 = row_AFRPBAL.BALANCE1,
             BALANCE2 = row_AFRPBAL.BALANCE2,
             BALANCE3 = row_AFRPBAL.BALANCE3,
             BALANCE4 = row_AFRPBAL.BALANCE4,
             STATUS   = row_AFRPBAL.STATUS,
             miLoanNo = v_keycode,
             miContNo = v_MiCONTNO
       where PROTSENO = row_AFRPBAL.PROTSENO
         and SUBSERNO = row_AFRPBAL.SUBSERNO;
    end if;
    if v_count / 1000 = 0 then
      commit;
    end if;
    fetch cur_AFRPBAL
      into row_AFRPBAL;
  end loop;
  commit;
  close cur_AFRPBAL;
exception
  when others then
    rollback;
end;
/

prompt
prompt Creating procedure DEALHBFXSTORE
prompt ================================
prompt
create or replace procedure dealHbfxStore is
   /******************************************************************************
      NAME:       dealHbfxStore
      PURPOSE:    璐锋鍊熸嵁鍗＄墖鏁版嵁澶囦唤
      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        2016/07/21  姊佺寷             1. Created this procedure
   ******************************************************************************/
begin
 merge into MIAFPCLONSTORE mi
using (select * from MIAFPCLONALL t  where exists (select mediumid from miafitdtlall  where t.mediumid = mediumid group by mediumid, protseno)) mm
on (mi.protseno=mm.protseno and  mi.subserno=mm.subserno)
WHEN MATCHED THEN
  UPDATE
     SET
    ZONENO=mm.ZONENO,
    MEDIUMID=mm.MEDIUMID,
    STATUS=mm.STATUS,
    CURRTYPE=mm.CURRTYPE,
    PRTYCODE=mm.PRTYCODE,
PRSERNO=mm.PRSERNO,
XDMEMNO=mm.XDMEMNO,
ASSPFLAG=mm.ASSPFLAG,
EXHFLAG=mm.EXHFLAG,
CUTFLAG=mm.CUTFLAG,
AHFLAG=mm.AHFLAG,
LOANDATE=mm.LOANDATE,
INTDATE=mm.INTDATE,
MATUDATE=mm.MATUDATE,
EXHDATE=mm.EXHDATE,
LNAMOUNT=mm.LNAMOUNT,
PRAFLAG=mm.PRAFLAG,
PRACCF=mm.PRACCF,
PROACCNO=mm.PROACCNO,
PRACCSN=mm.PRACCSN,
EXRFLAG=mm.EXRFLAG,
EXCHRAT=mm.EXCHRAT,
AHDRTNF=mm.AHDRTNF,
OLGBFLAG=mm.OLGBFLAG,
TATGBF=mm.TATGBF,
RTNMODE=mm.RTNMODE,
EQUAMT=mm.EQUAMT,
UPERIOD=mm.UPERIOD,
PERIOD=mm.PPERIOD,
PUPERIOD=mm.PUPERIOD,
PPERIOD=mm.PPERIOD,
GHDATE=mm.GHDATE,
GBAFLAG=mm.GBAFLAG,
GBACCF=mm.GBACCF,
GBCURR=mm.GBCURR,
GBACCNO=mm.GBACCNO,
GBACCSN=mm.GBACCSN,
CASHEXF=mm.CASHEXF,
GBEXRF=mm.GBEXRF,
BEXCHRAT=mm.BEXCHRAT,
EXTYPE=mm.EXTYPE,
EXDAYS=mm.EXDAYS,
TOEXDAYS=mm.TOEXDAYS,
REXDAYS=mm.REXDAYS,
EXBDATE=mm.EXBDATE,
EXEDATE=mm.EXEDATE,
NGBSEQ=mm.NGBSEQ,
OGBSEQ=mm.OGBSEQ,
ASSVALF1=mm.ASSVALF1,
ASSACCF1=mm.ASSACCF1,
ASSACCT1=mm.ASSACCT1,
ASACCSN1=mm.ASACCSN1,
ASSEXRF1=mm.ASSEXRF1,
ASSEXR1=mm.ASSEXR1,
ASSVALF2=mm.ASSVALF2,
ASSACCF2=mm.ASSACCF2,
ASSACCT2=mm.ASSACCT2,
ASACCSN2=mm.ASACCSN2,
ASSEXRF2=mm.ASSEXRF2,
ASSEXR2=mm.ASSEXR2,
ASSVALF3=mm.ASSVALF3,
ASSACCF3=mm.ASSACCF3,
ASSACCT3=mm.ASSACCT3,
ASACCSN3=mm.ASACCSN3,
ASSEXRF3=mm.ASSEXRF3,
ASSEXR3=mm.ASSEXR3,
CALINTF=mm.CALINTF,
NUPERI=mm.NUPERI,
NPERI=mm.NPERI,
OVCALINF=mm.OVCALINF,
OVUPERI=mm.OVUPERI,
OVPERI=mm.OVPERI,
NINTTYPE=mm.NINTTYPE,
NISERNO=mm.NISERNO,
NINTSELMO=mm.NINTSELMO,
NUPERIOD=mm.NUPERIOD,
NPERIOD=mm.NPERIOD,
NRATE=mm.NRATE,
NRATECOD=mm.NRATECOD,
NFLTYPE=mm.NFLTYPE,
NINFLRAT=mm.NINFLRAT,
EINTTYPE=mm.EINTTYPE,
EISERNO=mm.EISERNO,
EINTSELMO=mm.EINTSELMO,
EUPERIOD=mm.EUPERIOD,
EPERIOD=mm.EPERIOD,
ERATE=mm.ERATE,
ERATECOD=mm.ERATECOD,
EFLTYPE=mm.EFLTYPE,
EINFLRAT=mm.EINFLRAT,
ECRDATE=mm.ECRDATE,
OVITYPE=mm.OVITYPE,
OVISERNO=mm.OVISERNO,
OINTSELMO=mm.OINTSELMO,
OUPERIOD=mm.OUPERIOD,
OPERIOD=mm.OPERIOD,
ORATE=mm.OfRATE,
ORATECOD=mm.ORATECOD,
OFLTYPE=mm.OfFLTYPE,
OINFLRAT=mm.OINFLRAT,
INITYPE=mm.INITYPE,
INISERNO=mm.INISERNO,
IINTSELMO=mm.IINTSELMO,
IUPERIOD=mm.IUPERIOD,
IPERIOD=mm.IPERIOD,
IRATE=mm.IRATE,
IRATECOD=mm.IRATECOD,
IFLTYPE=mm.IFLTYPE,
IINFLRAT=mm.IINFLRAT,
OFITYPE=mm.OFITYPE,
OFISERNO=mm.OFISERNO,
OFINSELMO=mm.OFINSELMO,
OFUPERI=mm.OFUPERI,
OFPERI=mm.OFPERI,
OFRATE=mm.OFRATE,
OFRATCOD=mm.OFRATCOD,
OFFLTYPE=mm.OFFLTYPE,
OFINFRAT=mm.OFINFRAT,
NBILU=mm.NBILU,
DISTYPE=mm.DISTYPE,
DISRATE=mm.DISRATE,
DISAFLAG=mm.DISAFLAG,
DISACCF=mm.DISACCF,
DISACCNO=mm.DISACCNO,
DISACCSN=mm.DISACCSN,
DISINT=mm.DISINT,
DISCTRLF=mm.DISCTRLF,
DISUPERI=mm.DISUPERI,
DISPERI=mm.DISPERI,
DISNDATE=mm.DISNDATE,
DISPFLAG=mm.DISPFLAG,
DISBDATE=mm.DISBDATE,
DISEDATE=mm.DISEDATE,
TOTTIMES=mm.TOTTIMES,
NEXTIMES=mm.NEXTIMES,
NXGBDATE=mm.NXGBDATE,
CEXDAYS=mm.CEXDAYS,
LSGBDATE=mm.LSGBDATE,
CALBAL=mm.CALBAL,
CALTOT=mm.CALTOT,
CALNEXT=mm.CALNEXT,
ADZONENO=mm.ADZONENO,
PRCRDATE=mm.PRCRDATE,
CRZONENO=mm.CRZONENO,
CRBRNO=mm.CRBRNO,
CTELLERN=mm.CTELLERN,
PRENDATE=mm.PRENDATE,
ENDZONENO=mm.ENDZONENO,
ENDBRNO=mm.ENDBRNO,
ETELLERN=mm.ETELLERN,
LADJDATE=mm.LADJDATE,
LTITDATE=mm.LTITDATE,
LTRDDATE=mm.LTRDDATE,
LCTRDDAT=mm.LCTRDDAT,
PHYBRNO=mm.PHYBRNO,
ACTBRNO=mm.ACTBRNO,
LGLOCKNO=mm.LGLOCKNO,
INTAMT=mm.INTAMT,
INTBAL=mm.INTBAL,
GHINDATE=mm.GHINDATE,
VALUEDAY=mm.VALUEDAY,
NXGBFLAG=mm.NXGBFLAG,
ECALINF=mm.ExCALINF,
EVUPERI=mm.EVUPERI,
EVPERI=mm.EVPERI,
INCALINF=mm.INCALINF,
INUPERI=mm.INUPERI,
INPERI=mm.INPERI,
OCALINF=mm.OvCALINF,
OUPERI=mm.OfUPERI,
OPERI=mm.OfPERI,
PRITERM=mm.PRITERM,
INTTERM=mm.INTTERM,
PCUSTNO=mm.PCUSTNO,
EXCALINF=mm.EXCALINF,
INTCAPF=mm.INTCAPF,
PRIEXDAT=mm.PRIEXDAT,
HOLIDAYF=mm.HOLIDAYF,
NOMALTYPE=mm.NOMALTYPE,
EPERTYPE=mm.EPERTYPE,
YPERTYPE=mm.YPERTYPE,
BIAONTYPE=mm.BIAONTYPE,
BIAOWTYPE=mm.BIAOWTYPE,
SUBSERNO1=mm.SUBSERNO1,
PREINTF=mm.PREINTF,
PRINTTM=mm.PRINTTM,
AHDRTOT=mm.AHDRTOT,
AHDRBAL=mm.AHDRBAL,
LTAHDRDT=mm.LTAHDRDT,
EXLNAMT=mm.EXLNAMT,
CALGHDAT=mm.CALGHDAT,
AUTOINTD=mm.AUTOINTD,
GBTYPE=mm.GBTYPE,
REMTERM=mm.REMTERM,
HOLIINTF=mm.HOLIINTF,
FRATECOD=mm.FRATECOD
WHEN NOT MATCHED THEN
  INSERT(ZONENO,MEDIUMID,PROTSENO,SUBSERNO,STATUS,CURRTYPE,PRTYCODE,PRSERNO,XDMEMNO,ASSPFLAG,EXHFLAG,CUTFLAG,AHFLAG,LOANDATE,INTDATE,MATUDATE,EXHDATE,LNAMOUNT,PRAFLAG,PRACCF,PROACCNO,PRACCSN,EXRFLAG,EXCHRAT,AHDRTNF,OLGBFLAG,TATGBF,RTNMODE,EQUAMT,UPERIOD,PERIOD,PUPERIOD,PPERIOD,GHDATE,GBAFLAG,GBACCF,GBCURR,GBACCNO,GBACCSN,CASHEXF,GBEXRF,BEXCHRAT,EXTYPE,EXDAYS,TOEXDAYS,REXDAYS,EXBDATE,EXEDATE,NGBSEQ,OGBSEQ,ASSVALF1,ASSACCF1,ASSACCT1,ASACCSN1,ASSEXRF1,ASSEXR1,ASSVALF2,ASSACCF2,ASSACCT2,ASACCSN2,ASSEXRF2,ASSEXR2,ASSVALF3,ASSACCF3,ASSACCT3,ASACCSN3,ASSEXRF3,ASSEXR3,CALINTF,NUPERI,NPERI,OVCALINF,OVUPERI,OVPERI,NINTTYPE,NISERNO,NINTSELMO,NUPERIOD,NPERIOD,NRATE,NRATECOD,NFLTYPE,NINFLRAT,EINTTYPE,EISERNO,EINTSELMO,EUPERIOD,EPERIOD,ERATE,ERATECOD,EFLTYPE,EINFLRAT,ECRDATE,OVITYPE,OVISERNO,OINTSELMO,OUPERIOD,OPERIOD,ORATE,ORATECOD,OFLTYPE,OINFLRAT,INITYPE,INISERNO,IINTSELMO,IUPERIOD,IPERIOD,IRATE,IRATECOD,IFLTYPE,IINFLRAT,OFITYPE,OFISERNO,OFINSELMO,OFUPERI,OFPERI,OFRATE,OFRATCOD,OFFLTYPE,OFINFRAT,NBILU,DISTYPE,DISRATE,DISAFLAG,DISACCF,DISACCNO,DISACCSN,DISINT,DISCTRLF,DISUPERI,DISPERI,DISNDATE,DISPFLAG,DISBDATE,DISEDATE,TOTTIMES,NEXTIMES,NXGBDATE,CEXDAYS,LSGBDATE,CALBAL,CALTOT,CALNEXT,ADZONENO,PRCRDATE,CRZONENO,CRBRNO,CTELLERN,PRENDATE,ENDZONENO,ENDBRNO,ETELLERN,LADJDATE,LTITDATE,LTRDDATE,LCTRDDAT,PHYBRNO,ACTBRNO,LGLOCKNO,INTAMT,INTBAL,GHINDATE,VALUEDAY,NXGBFLAG,ECALINF,EVUPERI,EVPERI,INCALINF,INUPERI,INPERI,OCALINF,OUPERI,OPERI,PRITERM,INTTERM,PCUSTNO,EXCALINF,INTCAPF,PRIEXDAT,HOLIDAYF,NOMALTYPE,EPERTYPE,YPERTYPE,BIAONTYPE,BIAOWTYPE,SUBSERNO1,PREINTF,PRINTTM,AHDRTOT,AHDRBAL,LTAHDRDT,EXLNAMT,CALGHDAT,AUTOINTD,GBTYPE,REMTERM,HOLIINTF,FRATECOD)
  values(mm.ZONENO,mm.MEDIUMID,mm.PROTSENO,mm.SUBSERNO,mm.STATUS,mm.CURRTYPE,mm.PRTYCODE,mm.PRSERNO,mm.XDMEMNO,mm.ASSPFLAG,mm.EXHFLAG,mm.CUTFLAG,mm.AHFLAG,mm.LOANDATE,mm.INTDATE,mm.MATUDATE,mm.EXHDATE,mm.LNAMOUNT,mm.PRAFLAG,mm.PRACCF,mm.PROACCNO,mm.PRACCSN,mm.EXRFLAG,mm.EXCHRAT,mm.AHDRTNF,mm.OLGBFLAG,mm.TATGBF,mm.RTNMODE,mm.EQUAMT,mm.UPERIOD,mm.pperiod,mm.PUPERIOD,mm.PPERIOD,mm.GHDATE,mm.GBAFLAG,mm.GBACCF,mm.GBCURR,mm.GBACCNO,mm.GBACCSN,mm.CASHEXF,mm.GBEXRF,mm.BEXCHRAT,mm.EXTYPE,mm.EXDAYS,mm.TOEXDAYS,mm.REXDAYS,mm.EXBDATE,mm.EXEDATE,mm.NGBSEQ,mm.OGBSEQ,mm.ASSVALF1,mm.ASSACCF1,mm.ASSACCT1,mm.ASACCSN1,mm.ASSEXRF1,mm.ASSEXR1,mm.ASSVALF2,mm.ASSACCF2,mm.ASSACCT2,mm.ASACCSN2,mm.ASSEXRF2,mm.ASSEXR2,mm.ASSVALF3,mm.ASSACCF3,mm.ASSACCT3,mm.ASACCSN3,mm.ASSEXRF3,mm.ASSEXR3,mm.CALINTF,mm.NUPERI,mm.NPERI,mm.OVCALINF,mm.OVUPERI,mm.OVPERI,mm.NINTTYPE,mm.NISERNO,mm.NINTSELMO,mm.NUPERIOD,mm.NPERIOD,mm.NRATE,mm.NRATECOD,mm.NFLTYPE,mm.NINFLRAT,mm.EINTTYPE,mm.EISERNO,mm.EINTSELMO,mm.EUPERIOD,mm.EPERIOD,mm.ERATE,mm.ERATECOD,mm.EFLTYPE,mm.EINFLRAT,mm.ECRDATE,mm.OVITYPE,mm.OVISERNO,mm.OINTSELMO,mm.OUPERIOD,mm.OPERIOD,mm.OfRATE,mm.ORATECOD,mm.OfFLTYPE,mm.OINFLRAT,mm.INITYPE,mm.INISERNO,mm.IINTSELMO,mm.IUPERIOD,mm.IPERIOD,mm.IRATE,mm.IRATECOD,mm.IFLTYPE,mm.IINFLRAT,mm.OFITYPE,mm.OFISERNO,mm.OFINSELMO,mm.OFUPERI,mm.OFPERI,mm.OFRATE,mm.OFRATCOD,mm.OFFLTYPE,mm.OFINFRAT,mm.NBILU,mm.DISTYPE,mm.DISRATE,mm.DISAFLAG,mm.DISACCF,mm.DISACCNO,mm.DISACCSN,mm.DISINT,mm.DISCTRLF,mm.DISUPERI,mm.DISPERI,mm.DISNDATE,mm.DISPFLAG,mm.DISBDATE,mm.DISEDATE,mm.TOTTIMES,mm.NEXTIMES,mm.NXGBDATE,mm.CEXDAYS,mm.LSGBDATE,mm.CALBAL,mm.CALTOT,mm.CALNEXT,mm.ADZONENO,mm.PRCRDATE,mm.CRZONENO,mm.CRBRNO,mm.CTELLERN,mm.PRENDATE,mm.ENDZONENO,mm.ENDBRNO,mm.ETELLERN,mm.LADJDATE,mm.LTITDATE,mm.LTRDDATE,mm.LCTRDDAT,mm.PHYBRNO,mm.ACTBRNO,mm.LGLOCKNO,mm.INTAMT,mm.INTBAL,mm.GHINDATE,mm.VALUEDAY,mm.NXGBFLAG,mm.ExCALINF,mm.EVUPERI,mm.EVPERI,mm.INCALINF,mm.INUPERI,mm.INPERI,mm.OvCALINF,mm.OfUPERI,mm.OfPERI,mm.PRITERM,mm.INTTERM,mm.PCUSTNO,mm.EXCALINF,mm.INTCAPF,mm.PRIEXDAT,mm.HOLIDAYF,mm.NOMALTYPE,mm.EPERTYPE,mm.YPERTYPE,mm.BIAONTYPE,mm.BIAOWTYPE,mm.SUBSERNO1,mm.PREINTF,mm.PRINTTM,mm.AHDRTOT,mm.AHDRBAL,mm.LTAHDRDT,mm.EXLNAMT,mm.CALGHDAT,mm.AUTOINTD,mm.GBTYPE,mm.REMTERM,mm.HOLIINTF,mm.FRATECOD);
commit;
end;
/

prompt
prompt Creating procedure DEALMIAFPCTMRALL
prompt ===================================
prompt
create or replace procedure dealMIAFPCTMRALL is
  row_AFPCTMR AFPCTMR%rowtype;
  sqloanno    varchar2(200);
  sql_2       varchar2(200);
  sql_3       varchar2(200);
  sql_4       varchar2(200);
  sql_5       varchar2(200);
  v_keycode   varchar2(34);
  v_MiCONTNO  varchar2(34);
  v_count     integer := 0;
     /******************************************************************************
      NAME:       dealMIAFPCTMRALL
      PURPOSE:    澶囦唤AFPCTMR琛ㄤ腑鏁版嵁
      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        2016/07/21  姊佺寷             1. Created this procedure
   ******************************************************************************/
  cursor cur_AFPCTMR is
    select * from AFPCTMR;
begin
  open cur_AFPCTMR;
  fetch cur_AFPCTMR
    into row_AFPCTMR;
  while cur_AFPCTMR%found loop
    sqloanno := 'select (select keycode from GcLoanCredit where lnacc=''' ||
                row_AFPCTMR.Mediumid ||
                ''' and keyeffectedstate=''0002'' and rownum=1) from dual';
    execute immediate sqloanno
      into v_keycode;
    if v_keycode is null then
      sql_2 := 'select (select keycode from TlLoanCredit  where oldcorecode=''' ||
               row_AFPCTMR.Subserno || ''' and lnacc= ''' ||
               row_AFPCTMR.Mediumid ||
               ''' and keyeffectedstate=''0002'' and rownum=1) from dual';
      execute immediate sql_2
        into v_keycode;
      if v_keycode is null then
        sql_3 := 'select (select keycode from TlLoanCredit where lnacc= ''' ||
                 row_AFPCTMR.Mediumid ||
                 ''' and keyeffectedstate=''0002'' and rownum=1) from dual';
        execute immediate sql_3
          into v_keycode;
      end if;
    end if;
    if v_keycode is not null then
      sql_4 := 'select (select UpKeyCode from GcLoanCredit where keycode=''' ||
               v_keycode || '''and rownum=1) from dual';
      execute immediate sql_4
        into v_MiCONTNO;
      if v_MiCONTNO is null then
        sql_5 := 'select (select UpKeyCode from TlLoanCredit where keycode=''' ||
                 v_keycode || '''and rownum=1) from dual';
        execute immediate sql_5
          into v_MiCONTNO;
      end if;
    else
      v_MiCONTNO := v_keycode;
    end if;
    v_count := v_count + 1;
    insert into MIAFPCTMRSTORE
      (ZONENO,
       MEDIUMID,
       PROTSENO,
       SUBSERNO,
       TERMNUM,
       TIMESTAT,
       CURRTYPE,
       DATEREOC,
       OVGBDATE,
       LSTTDATE,
       LSTINTD,
       NINTDATE,
       NXGBDATE,
       PRIAMT,
       INT,
       OVRBAL,
       LSTLSBAL,
       OVRINT,
       OVRRTAMT,
       INZCQXD,
       INBAL,
       INLSBAL,
       ININT,
       INRTAMT,
       OFZCQXD,
       OFBAL,
       OFLSBAL,
       OFINT,
       OFRTAMT,
       DELAYINT,
       REXDAYS,
       PHYBRNO,
       ACTBRNO,
       INZCQXD1,
       INBAL1,
       INLSBAL1,
       ININT1,
       INRTAMT1,
       INZCQXD2,
       INBAL2,
       INLSBAL2,
       ININT2,
       INRTAMT2,
       INZCQXD3,
       INBAL3,
       INLSBAL3,
       ININT3,
       INRTAMT3,
       INZCQXD4,
       INBAL4,
       INLSBAL4,
       ININT4,
       INRTAMT4,
       INZCQXD5,
       INBAL5,
       INLSBAL5,
       ININT5,
       INRTAMT5,
       INZCQXD6,
       INBAL6,
       INLSBAL6,
       ININT6,
       INRTAMT6,
       OFZCQXD1,
       OFBAL1,
       OFLSBAL1,
       OFINT1,
       OFRTAMT1,
       OFZCQXD2,
       OFBAL2,
       OFLSBAL2,
       OFINT2,
       OFRTAMT2,
       OFZCQXD3,
       OFBAL3,
       OFLSBAL3,
       OFINT3,
       OFRTAMT3,
       OFZCQXD4,
       OFBAL4,
       OFLSBAL4,
       OFINT4,
       OFRTAMT4,
       OFZCQXD5,
       OFBAL5,
       OFLSBAL5,
       OFINT5,
       OFRTAMT5,
       OFZCQXD6,
       OFBAL6,
       OFLSBAL6,
       OFINT6,
       OFRTAMT6,
       FEEAMTNO1,
       FEEAMT1,
       LFEEAMT1,
       LGBLFDAT1,
       FEEAMTNO2,
       FEEAMT2,
       LFEEAMT2,
       LGBLFDAT2,
       FEEAMTNO3,
       FEEAMT3,
       LFEEAMT3,
       LGBLFDAT3,
       FEEAMTNO4,
       FEEAMT4,
       LFEEAMT4,
       LGBLFDAT4,
       FEEAMTNO5,
       FEEAMT5,
       LFEEAMT5,
       LGBLFDAT5,
       FEEAMTNO6,
       FEEAMT6,
       LFEEAMT6,
       LGBLFDAT6,
       FEEAMTNO7,
       FEEAMT7,
       LFEEAMT7,
       LGBLFDAT7,
       FEEAMTNO8,
       FEEAMT8,
       LFEEAMT8,
       LGBLFDAT8,
       FEEAMTNO9,
       FEEAMT9,
       LFEEAMT9,
       LGBLFDAT9,
       FEEAMTNO10,
       FEEAMT10,
       LFEEAMT10,
       LGBLFDAT10,
       FEEAMTNO11,
       FEEAMT11,
       LFEEAMT11,
       LGBLFDAT11,
       FEEAMTNO12,
       FEEAMT12,
       LFEEAMT12,
       LGBLFDAT12,
       FEEAMTNO13,
       FEEAMT13,
       LFEEAMT13,
       LGBLFDAT13,
       FEEAMTNO14,
       FEEAMT14,
       LFEEAMT14,
       LGBLFDAT14,
       FEEAMTNO15,
       FEEAMT15,
       LFEEAMT15,
       LGBLFDAT15,
       FEEAMTNO16,
       FEEAMT16,
       LFEEAMT16,
       LGBLFDAT16,
       FEEAMTNO17,
       FEEAMT17,
       LFEEAMT17,
       LGBLFDAT17,
       FEEAMTNO18,
       FEEAMT18,
       LFEEAMT18,
       LGBLFDAT18,
       FEEAMTNO19,
       FEEAMT19,
       LFEEAMT19,
       LGBLFDAT19,
       FEEAMTNO20,
       FEEAMT20,
       LGBLFDAT20,
       FEEAMTNO21,
       FEEAMT21,
       LFEEAMT21,
       LFEEAMT20,
       LGBLFDAT21,
       FEEAMTNO22,
       FEEAMT22,
       LFEEAMT22,
       LGBLFDAT22,
       FEEAMTNO23,
       FEEAMT23,
       LFEEAMT23,
       LGBLFDAT23,
       FEEAMTNO24,
       FEEAMT24,
       LFEEAMT24,
       LGBLFDAT24,
       FEEAMTNO25,
       FEEAMT25,
       LFEEAMT25,
       LGBLFDAT25,
       MILOANNO,
       MICONTNO)
    values
      (row_AFPCTMR.ZONENO,
       row_AFPCTMR.MEDIUMID,
       row_AFPCTMR.PROTSENO,
       row_AFPCTMR.SUBSERNO,
       row_AFPCTMR.TERMNUM,
       row_AFPCTMR.TIMESTAT,
       row_AFPCTMR.CURRTYPE,
       row_AFPCTMR.DATEREOC,
       row_AFPCTMR.OVGBDATE,
       row_AFPCTMR.LSTTDATE,
       row_AFPCTMR.LSTINTD,
       row_AFPCTMR.NINTDATE,
       row_AFPCTMR.NXGBDATE,
       row_AFPCTMR.PRIAMT,
       row_AFPCTMR.INT,
       row_AFPCTMR.OVRBAL,
       row_AFPCTMR.LSTLSBAL,
       row_AFPCTMR.OVRINT,
       row_AFPCTMR.OVRRTAMT,
       row_AFPCTMR.INZCQXD,
       row_AFPCTMR.INBAL,
       row_AFPCTMR.INLSBAL,
       row_AFPCTMR.ININT,
       row_AFPCTMR.INRTAMT,
       row_AFPCTMR.OFZCQXD,
       row_AFPCTMR.OFBAL,
       row_AFPCTMR.OFLSBAL,
       row_AFPCTMR.OFINT,
       row_AFPCTMR.OFRTAMT,
       row_AFPCTMR.DELAYINT,
       row_AFPCTMR.REXDAYS,
       row_AFPCTMR.PHYBRNO,
       row_AFPCTMR.ACTBRNO,
       row_AFPCTMR.INZCQXD1,
       row_AFPCTMR.INBAL1,
       row_AFPCTMR.INLSBAL1,
       row_AFPCTMR.ININT1,
       row_AFPCTMR.INRTAMT1,
       row_AFPCTMR.INZCQXD2,
       row_AFPCTMR.INBAL2,
       row_AFPCTMR.INLSBAL2,
       row_AFPCTMR.ININT2,
       row_AFPCTMR.INRTAMT2,
       row_AFPCTMR.INZCQXD3,
       row_AFPCTMR.INBAL3,
       row_AFPCTMR.INLSBAL3,
       row_AFPCTMR.ININT3,
       row_AFPCTMR.INRTAMT3,
       row_AFPCTMR.INZCQXD4,
       row_AFPCTMR.INBAL4,
       row_AFPCTMR.INLSBAL4,
       row_AFPCTMR.ININT4,
       row_AFPCTMR.INRTAMT4,
       row_AFPCTMR.INZCQXD5,
       row_AFPCTMR.INBAL5,
       row_AFPCTMR.INLSBAL5,
       row_AFPCTMR.ININT5,
       row_AFPCTMR.INRTAMT5,
       row_AFPCTMR.INZCQXD6,
       row_AFPCTMR.INBAL6,
       row_AFPCTMR.INLSBAL6,
       row_AFPCTMR.ININT6,
       row_AFPCTMR.INRTAMT6,
       row_AFPCTMR.OFZCQXD1,
       row_AFPCTMR.OFBAL1,
       row_AFPCTMR.OFLSBAL1,
       row_AFPCTMR.OFINT1,
       row_AFPCTMR.OFRTAMT1,
       row_AFPCTMR.OFZCQXD2,
       row_AFPCTMR.OFBAL2,
       row_AFPCTMR.OFLSBAL2,
       row_AFPCTMR.OFINT2,
       row_AFPCTMR.OFRTAMT2,
       row_AFPCTMR.OFZCQXD3,
       row_AFPCTMR.OFBAL3,
       row_AFPCTMR.OFLSBAL3,
       row_AFPCTMR.OFINT3,
       row_AFPCTMR.OFRTAMT3,
       row_AFPCTMR.OFZCQXD4,
       row_AFPCTMR.OFBAL4,
       row_AFPCTMR.OFLSBAL4,
       row_AFPCTMR.OFINT4,
       row_AFPCTMR.OFRTAMT4,
       row_AFPCTMR.OFZCQXD5,
       row_AFPCTMR.OFBAL5,
       row_AFPCTMR.OFLSBAL5,
       row_AFPCTMR.OFINT5,
       row_AFPCTMR.OFRTAMT5,
       row_AFPCTMR.OFZCQXD6,
       row_AFPCTMR.OFBAL6,
       row_AFPCTMR.OFLSBAL6,
       row_AFPCTMR.OFINT6,
       row_AFPCTMR.OFRTAMT6,
       row_AFPCTMR.FEEAMTNO1,
       row_AFPCTMR.FEEAMT1,
       row_AFPCTMR.LFEEAMT1,
       row_AFPCTMR.LGBLFDAT1,
       row_AFPCTMR.FEEAMTNO2,
       row_AFPCTMR.FEEAMT2,
       row_AFPCTMR.LFEEAMT2,
       row_AFPCTMR.LGBLFDAT2,
       row_AFPCTMR.FEEAMTNO3,
       row_AFPCTMR.FEEAMT3,
       row_AFPCTMR.LFEEAMT3,
       row_AFPCTMR.LGBLFDAT3,
       row_AFPCTMR.FEEAMTNO4,
       row_AFPCTMR.FEEAMT4,
       row_AFPCTMR.LFEEAMT4,
       row_AFPCTMR.LGBLFDAT4,
       row_AFPCTMR.FEEAMTNO5,
       row_AFPCTMR.FEEAMT5,
       row_AFPCTMR.LFEEAMT5,
       row_AFPCTMR.LGBLFDAT5,
       row_AFPCTMR.FEEAMTNO6,
       row_AFPCTMR.FEEAMT6,
       row_AFPCTMR.LFEEAMT6,
       row_AFPCTMR.LGBLFDAT6,
       row_AFPCTMR.FEEAMTNO7,
       row_AFPCTMR.FEEAMT7,
       row_AFPCTMR.LFEEAMT7,
       row_AFPCTMR.LGBLFDAT7,
       row_AFPCTMR.FEEAMTNO8,
       row_AFPCTMR.FEEAMT8,
       row_AFPCTMR.LFEEAMT8,
       row_AFPCTMR.LGBLFDAT8,
       row_AFPCTMR.FEEAMTNO9,
       row_AFPCTMR.FEEAMT9,
       row_AFPCTMR.LFEEAMT9,
       row_AFPCTMR.LGBLFDAT9,
       row_AFPCTMR.FEEAMTNO10,
       row_AFPCTMR.FEEAMT10,
       row_AFPCTMR.LFEEAMT10,
       row_AFPCTMR.LGBLFDAT10,
       row_AFPCTMR.FEEAMTNO11,
       row_AFPCTMR.FEEAMT11,
       row_AFPCTMR.LFEEAMT11,
       row_AFPCTMR.LGBLFDAT11,
       row_AFPCTMR.FEEAMTNO12,
       row_AFPCTMR.FEEAMT12,
       row_AFPCTMR.LFEEAMT12,
       row_AFPCTMR.LGBLFDAT12,
       row_AFPCTMR.FEEAMTNO13,
       row_AFPCTMR.FEEAMT13,
       row_AFPCTMR.LFEEAMT13,
       row_AFPCTMR.LGBLFDAT13,
       row_AFPCTMR.FEEAMTNO14,
       row_AFPCTMR.FEEAMT14,
       row_AFPCTMR.LFEEAMT14,
       row_AFPCTMR.LGBLFDAT14,
       row_AFPCTMR.FEEAMTNO15,
       row_AFPCTMR.FEEAMT15,
       row_AFPCTMR.LFEEAMT15,
       row_AFPCTMR.LGBLFDAT15,
       row_AFPCTMR.FEEAMTNO16,
       row_AFPCTMR.FEEAMT16,
       row_AFPCTMR.LFEEAMT16,
       row_AFPCTMR.LGBLFDAT16,
       row_AFPCTMR.FEEAMTNO17,
       row_AFPCTMR.FEEAMT17,
       row_AFPCTMR.LFEEAMT17,
       row_AFPCTMR.LGBLFDAT17,
       row_AFPCTMR.FEEAMTNO18,
       row_AFPCTMR.FEEAMT18,
       row_AFPCTMR.LFEEAMT18,
       row_AFPCTMR.LGBLFDAT18,
       row_AFPCTMR.FEEAMTNO19,
       row_AFPCTMR.FEEAMT19,
       row_AFPCTMR.LFEEAMT19,
       row_AFPCTMR.LGBLFDAT19,
       row_AFPCTMR.FEEAMTNO20,
       row_AFPCTMR.FEEAMT20,
       row_AFPCTMR.LGBLFDAT20,
       row_AFPCTMR.FEEAMTNO21,
       row_AFPCTMR.FEEAMT21,
       row_AFPCTMR.LFEEAMT21,
       row_AFPCTMR.LFEEAMT20,
       row_AFPCTMR.LGBLFDAT21,
       row_AFPCTMR.FEEAMTNO22,
       row_AFPCTMR.FEEAMT22,
       row_AFPCTMR.LFEEAMT22,
       row_AFPCTMR.LGBLFDAT22,
       row_AFPCTMR.FEEAMTNO23,
       row_AFPCTMR.FEEAMT23,
       row_AFPCTMR.LFEEAMT23,
       row_AFPCTMR.LGBLFDAT23,
       row_AFPCTMR.FEEAMTNO24,
       row_AFPCTMR.FEEAMT24,
       row_AFPCTMR.LFEEAMT24,
       row_AFPCTMR.LGBLFDAT24,
       row_AFPCTMR.FEEAMTNO25,
       row_AFPCTMR.FEEAMT25,
       row_AFPCTMR.LFEEAMT25,
       row_AFPCTMR.LGBLFDAT25,
       v_keycode,
       v_MiCONTNO);

    fetch cur_AFPCTMR
      into row_AFPCTMR;
    if v_count / 1000 = 0 then
      commit;
    end if;
  end loop;
  commit;
  close cur_AFPCTMR;
exception
  when others then
    rollback;
end dealMIAFPCTMRALL;
/

prompt
prompt Creating procedure PRO_CLCREDENCE
prompt =================================
prompt
create or replace procedure pro_CLCREDENCE is

var_gm_keycode gccontractmain.keycode%type;
var_gc_keycode gcloancredit.keycode%type;
var_cl_CREDITREQCODE CLCREDENCE.CREDITREQCODE%type;
sql1 varchar2(200);
sql2 varchar2(400);
sql3 varchar2(200);
sql4 varchar2(200);
cursor cur_gm_keycode is select gm.keycode from gccontractmain gm,gccontractshipinfo gs 
       where gm.keycode = gs.keycode and gs.gcshipcode like '%CB%' group by gm.keycode;

begin
  dbms_output.enable(buffer_size => null);
  open cur_gm_keycode;
  fetch cur_gm_keycode into var_gm_keycode;
  while cur_gm_keycode%found loop
    --dbms_output.put_line(var_gm_keycode);
    sql1 := 'select keycode from gcloancredit gc where gc.upkeycode  = '||chr(39)||var_gm_keycode||chr(39)||' and gc.oldcorecode = ''1'' and gc.keyeffectedstate =''0002''';
    execute immediate sql1 into var_gc_keycode;
    sql2 :='select cl.creditreqcode from CLCREDENCE cl where cl.uptypecode = '||chr(39)||var_gm_keycode||chr(39)||' and cl.creditreqcode like ''%JY%'' and cl.creditreqcode not in(
  select gc.keycode from gcloancredit gc where gc.upkeycode = '||chr(39)||var_gm_keycode||chr(39)||'     
)';
dbms_output.put_line(sql2);
  execute immediate sql2 into var_cl_CREDITREQCODE;
  sql3:='delete from CLCREDENCE cl where cl.creditreqcode = '||chr(39)||var_gc_keycode||chr(39)||' and cl.uptypecode = '||chr(39)||var_gm_keycode||chr(39);

  sql4 :='update CLCREDENCE cl set cl.creditreqcode = '||chr(39)||var_gc_keycode||chr(39)||' where cl.creditreqcode = '||chr(39)||var_cl_CREDITREQCODE||chr(39)||' and cl.uptypecode = '||chr(39)||var_gm_keycode||chr(39);
  --dbms_output.put_line(var_gm_keycode||','||var_gc_keycode||','||var_cl_CREDITREQCODE);
   --dbms_output.put_line(sql3);
   --dbms_output.put_line(sql4);
  execute immediate sql3;
  execute immediate sql4; 
    fetch cur_gm_keycode into var_gm_keycode;
  end loop;
  
end pro_CLCREDENCE;
/

prompt
prompt Creating procedure PRO_DEALGCAMAINTONSQUARE
prompt ===========================================
prompt
CREATE OR REPLACE PROCEDURE pro_dealgcamaintonsquare IS
--DKHTPCL-BatchLnCont-dealgcassuremaintonotsquare
/******************************************************************************
      NAME:       pro_dealgcamaintonsquare
      PURPOSE:    鏇存柊浠庡悎鍚岀粨娓呯姸鎬侊紝鐢辩粨娓呭埌鏈粨娓?
      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        2016/07/21  閭典紵             1. Created this procedure
   ******************************************************************************/
BEGIN
  UPDATE gcassuremain gc
     SET gc.keyeffectedstate = '0002'
   WHERE gc.keyeffectedstate = '0003'
     AND EXISTS
   (SELECT 1
            FROM gccontractmain gcm, gcassurecorrespond spond
           WHERE spond.keycode = gcm.keycode
             AND gcm.keyeffectedstate = '0002'
             AND (gcm.squarestate IS NULL OR gcm.squarestate != '1')
             AND spond.keyeffectedstate != '0004'
             AND spond.acontkeycode = gc.keycode);

  UPDATE gcassuremain gc
     SET gc.keyeffectedstate = '0002'
   WHERE gc.keyeffectedstate = '0003'
     AND nvl((SELECT SUM(credamt)
            FROM traderelainfo ti, gcassurecorrespond spond
           WHERE ti.contno = spond.keycode
             AND spond.keycode LIKE 'CMSCL%'
             AND spond.keyeffectedstate != '0004'
             AND spond.acontkeycode = gc.keycode),0) <> 0;
END;
/

prompt
prompt Creating procedure PRO_DEALLNCLASS
prompt ==================================
prompt
CREATE OR REPLACE PROCEDURE pro_deallnclass IS
--DKHTPCL-BatchLnCont-deallnclass
/******************************************************************************
      NAME:       pro_deallnclass
      PURPOSE:    鏍规嵁鍊熸嵁璐锋浣欓鏇存柊鍚堝悓璐锋鐘舵�?
      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        2016/07/21  閭典紵             1. Created this procedure
   ******************************************************************************/
BEGIN
  UPDATE micontractinfo t
     SET t.lnclass = (CASE
                       WHEN (SELECT MAX(pridays)
                               FROM miafrpoitzall
                              WHERE micontno = t.lncontno
                                AND ovrbalance <> 0.00) > 0 OR
                            (SELECT MAX(intdays)
                               FROM miafrpoitzall
                              WHERE micontno = t.lncontno
                                AND (incurbal <> 0.00 OR ofcurbal <> 0.00)) > 0 THEN
                        '1'
                       ELSE
                        '2'
                     END),
         t.lndays    =
         nvl((SELECT MAX(pridays)
            FROM miafrpoitzall
           WHERE micontno = t.lncontno
             AND ovrbalance <> 0.00),0),
         t.intrstdays =
         nvl((SELECT MAX(intdays)
            FROM miafrpoitzall
           WHERE micontno = t.lncontno
             AND (incurbal <> 0.00 OR ofcurbal <> 0.00)),0)
   WHERE t.itemtype = 'K02100000'
     AND EXISTS
   (SELECT 1 FROM miafrpoitzall maz WHERE maz.micontno = t.lncontno);

  UPDATE micontractinfo t
     SET t.lnclass = '2', t.lndays = '0', t.intrstdays = '0'
   WHERE t.itemtype = 'K02100000'
     AND NOT EXISTS
   (SELECT 1 FROM miafrpoitzall maz WHERE maz.micontno = t.lncontno);

  UPDATE micontractinfo t
     SET t.lnclass = (CASE
                       WHEN (SELECT MAX(pridays)
                               FROM miafrpoitall
                              WHERE micontno = t.lncontno
                                AND ovrbalance <> 0.00) > 0 OR
                            (SELECT MAX(intdays)
                               FROM miafrpoitall
                              WHERE micontno = t.lncontno
                                AND (incurbal <> 0.00 OR ofcurbal <> 0.00)) > 0 THEN
                        '1'
                       ELSE
                        '2'
                     END),
         t.lndays    =
         nvl((SELECT MAX(pridays)
            FROM miafrpoitall
           WHERE micontno = t.lncontno
             AND ovrbalance <> 0.00),0),
         t.intrstdays =
         nvl((SELECT MAX(intdays)
            FROM miafrpoitall
           WHERE micontno = t.lncontno
             AND (incurbal <> 0.00 OR ofcurbal <> 0.00)),0)
   WHERE nvl(t.itemtype, 'null') <> 'K02100000'
     AND EXISTS
   (SELECT 1 FROM miafrpoitall maz WHERE maz.micontno = t.lncontno);

  UPDATE micontractinfo t
     SET t.lnclass = '2', t.lndays = '0', t.intrstdays = '0'
   WHERE nvl(t.itemtype, 'null') <> 'K02100000'
     AND NOT EXISTS
   (SELECT 1 FROM miafrpoitall maz WHERE maz.micontno = t.lncontno);
END;
/

prompt
prompt Creating procedure PRO_UPDATECONTRACTMONEY
prompt ==========================================
prompt
CREATE OR REPLACE PROCEDURE pro_updatecontractmoney IS
--DKHTPCL-BatchLnCont-updatecontractmoney
/******************************************************************************
      NAME:       pro_updatecontractmoney
      PURPOSE:    鏍规嵁鍊熸嵁璐锋浣欓鏇存柊鍚堝悓璐锋浣欓
      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        2016/07/21  閭典紵             1. Created this procedure
   ******************************************************************************/
BEGIN
  UPDATE micontractinfo t
     SET t.payamt =
         nvl((SELECT SUM(payamt)
            FROM milncard mc
           WHERE mc.lncontno = t.lncontno
             AND mc.curtype = t.curtype),0),
         t.lnbal =
          nvl((SELECT SUM(balance1 + balance2)
            FROM milncard mc
           WHERE mc.lncontno = t.lncontno
             AND mc.curtype = t.curtype),0)
   WHERE EXISTS (SELECT 1
            FROM milncard mci
           WHERE mci.lncontno = t.lncontno
             AND mci.curtype = t.curtype);
  UPDATE micontractinfo t
     SET t.repayamt = t.payamt - t.lnbal
   WHERE EXISTS (SELECT 1
            FROM milncard mci
           WHERE mci.lncontno = t.lncontno
             AND mci.curtype = t.curtype);
END;
/

prompt
prompt Creating procedure RRMAXLMTENGROSS_SS
prompt =====================================
prompt
create or replace procedure RRMAXLMTENGROSS_ss is
  cursor cur_rrmax is
    select *
      from rrmaxsureengross rr
     where rr.creditkeycode in
           (select gcl.keycode
              from gccredittypeinformation gt,
                   gccontractshipinfo      gs,
                   lship                   ls,
                   gcloancredit            gcl
             where gt.keycode = gs.keycode
               and ls.gcshipcode = gs.gcshipcode
               and gt.keyeffectedstate = '0002'
               and gt.keycode = gcl.upkeycode
               and gcl.gcshipcode = gs.gcshipcode) order by rr.creditkeycode;
 
 cursor cur_cred(rrma_contractkeycode gcloancredit.upkeycode%type) is
    select *
      from gcloancredit gc
     where gc.upkeycode = rrma_contractkeycode
       and gc.keyeffectedstate = '0002';

  var_sum_money gcloancredit.money%type;
  var_cur_money gcloancredit.money%type;
  sqlsum        varchar2(200);
  sql1 varchar2(200);
  v_rate        float;
  var_cred_engr varchar2(200);
  sql2 varchar2(200);
  sqlupdate varchar2(400);
  sqldelete varchar2(400);
  str constant varchar2(15):='JY0000';
  s_num integer:=100;
  var_gc_upkeycode gcloancredit.upkeycode%type;
begin
  dbms_output.enable(buffer_size => null);
  for row_rrmax in cur_rrmax loop  
    sql2 :='select gc.upkeycode from gcloancredit gc where gc.keycode =:1'; 
    var_cred_engr :=row_rrmax.engrosskeycode;  
    execute immediate sql2 into var_gc_upkeycode using row_rrmax.creditkeycode;
    sqlsum :='select sum(gc.money) from gcloancredit gc where gc.upkeycode = :1 and gc.keyeffectedstate = ''0002'''; 
    execute immediate sqlsum into var_sum_money using var_gc_upkeycode;
    for row_cred in cur_cred(var_gc_upkeycode) loop
      sql1:='select gc.money from gcloancredit gc where gc.keycode =:1 and gc.keyeffectedstate = ''0002''';
      execute immediate sql1 into var_cur_money using row_cred.keycode;
      v_rate := var_cur_money / var_sum_money;
      row_rrmax.engrosskeycode :=str||s_num;
      s_num :=s_num+1;
      row_rrmax.creditkeycode :=row_cred.keycode;
      dbms_output.put_line(row_cred.keycode);
      insert into rrmaxsureengross values row_rrmax;
      sqlupdate :='update rrmaxsureengross rr set 
                  rr.renewlmt =:1,
                  rr.balancelmt=:2,
                  rr.basemoney=:3,
                  rr.engrosslmt=:4,
                  rr.initengrosslmt=:5                  
                  where rr.creditkeycode =:6
                  and rr.engrosskeycode =:7 ';
      execute immediate sqlupdate using  row_rrmax.renewlmt*v_rate,
                                         row_rrmax.balancelmt*v_rate,
                                         row_rrmax.basemoney*v_rate,
                                         row_rrmax.engrosslmt*v_rate,
                                         row_rrmax.initengrosslmt*v_rate,
                                         row_cred.keycode,
                                         row_rrmax.engrosskeycode;                                                              
    end loop;
     sqldelete :='delete from rrmaxsureengross rr where rr.engrosskeycode =:1';
     execute immediate sqldelete using var_cred_engr;
  end loop;
end RRMAXLMTENGROSS_ss;
/


spool off



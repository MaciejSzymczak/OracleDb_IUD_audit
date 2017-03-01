prompt ------------------------------ trial mechanism for table <your_table_name> -------------------------------------

alter table <your_table_name> add (effective_start_date date, effective_end_date date);
alter table <your_table_name> add (last_updated_by varchar2(30));
alter table <your_table_name> add (operation_flag char(1));

comment on column <your_table_name>.effective_start_date is 'Used by trail mechanism';
comment on column <your_table_name>.effective_end_date is 'Used by trail mechanism';
comment on column <your_table_name>.last_updated_by is 'Used by trail mechanism';
comment on column <your_table_name>.operation_flag is 'Used by trail mechanism';

create table <your_table_name>_history as select * from <your_table_name> where 0=1;
create index <your_table_name>_i  on <your_table_name>_history ( id );
create index <your_table_name>_i2 on <your_table_name>_history ( effective_start_date );
create index <your_table_name>_i3 on <your_table_name>_history ( effective_end_date );

CREATE OR REPLACE package <your_table_name>_history_pkg as
  type t is table of number index by binary_integer;
  ids t;
  trial_active boolean := true;
END;
/

CREATE OR REPLACE TRIGGER <your_table_name>_history_t1
AFTER INSERT or update or delete ON <your_table_name>
REFERENCING NEW AS NEW
FOR EACH ROW
DECLARE
i  NUMBER;
BEGIN
  if <your_table_name>_history_pkg.trial_active then 
    i := <your_table_name>_history_pkg.ids.count;
    <your_table_name>_history_pkg.ids( i+1 ) := nvl(:old.id, :new.id);
  end if;	
END;
/

CREATE OR REPLACE TRIGGER <your_table_name>_history_t2 after update or insert or delete  
on <your_table_name>
DECLARE
j            NUMBER;
procedure  process ( pid number ) is
 rec <your_table_name>%rowtype;
 psysdate date := sysdate;
begin
 if deleting then
    select * into rec from <your_table_name>_history where id = pid and effective_end_date is null;
 else
    select * into rec from <your_table_name> where id = pid;
 end if;
 update <your_table_name>_history
    set effective_end_date = psysdate - NumTodsInterval(1, 'second')
    where id = pid
    and effective_end_date is null;
 rec.effective_start_date := psysdate;
 if deleting then rec.effective_end_date := psysdate; end if;
 rec.last_updated_by := user;
 if inserting then rec.operation_flag := 'I'; end if;
 if updating then rec.operation_flag := 'U'; end if;
 if deleting then rec.operation_flag := 'D'; end if;   
 insert into <your_table_name>_history values rec;
exception when no_data_found then null; --no record in history table, likely trial was disabled before
end;
BEGIN
j := <your_table_name>_history_pkg.ids.first;
WHILE j IS NOT NULL LOOP
    process ( <your_table_name>_history_pkg.ids (j) );
    j := <your_table_name>_history_pkg.ids.next(j);
END LOOP;
<your_table_name>_history_pkg.ids.delete;
END;
/

Note:
this mechanizm does not log deleted records which were inserted when log was disabled ( see comment in code: no record in history table, likely trial was disabled before)
To workaround this, you need additional trigger T0 + additional temp table + change in trigger T2:

create global temporary table classes_h_temp as select * from classes where 0=1;

-- unfoftunatelly not generic version ( column names have to be enumerated ) - we cannot refer to table classes directly due mutanting table problem
CREATE OR REPLACE TRIGGER PLANNER.classes_history_t0
before INSERT or update or delete ON classes
REFERENCING NEW AS NEW
FOR EACH ROW
DECLARE
  i  NUMBER;
BEGIN
  if deleting then
    --xxmsz_tools.insertIntoEventLog('T0 id: '||nvl(:old.id, :new.id) ,'I');
    insert into classes_h_temp (id, day, hour, fill, sub_id, for_id, desc1, desc2, calc_lecturers, calc_groups, calc_rooms, calc_lec_ids, calc_gro_ids, calc_rom_ids, created_by, owner, status, colour, calc_rescat_ids, creation_date, desc3, desc4, effective_start_date, effective_end_date, last_updated_by, operation_flag)
    values (:old.id, :old.day, :old.hour, :old.fill, :old.sub_id, :old.for_id, :old.desc1, :old.desc2, :old.calc_lecturers, :old.calc_groups, :old.calc_rooms, :old.calc_lec_ids, :old.calc_gro_ids, :old.calc_rom_ids, :old.created_by, :old.owner, :old.status, :old.colour, :old.calc_rescat_ids, :old.creation_date, :old.desc3, :old.desc4, :old.effective_start_date, :old.effective_end_date, :old.last_updated_by, :old.operation_flag);
  end if;
END;
/

--changes marked by: --<-- 2013.03.06 
CREATE OR REPLACE TRIGGER PLANNER.classes_history_t2 after update or insert or delete  
on classes
DECLARE
  j NUMBER;
  procedure  process ( pid number ) is
   rec classes%rowtype;
   psysdate date := sysdate;
  begin
     if deleting then
        begin
          select * into rec from classes_history where id = pid and effective_end_date is null;
        exception when no_data_found then 
          --no record in history table, likely trial was disabled before
          select * into rec from classes_h_temp where id = pid and effective_end_date is null; --<-- 2013.03.06         
        end;
     else
        select * into rec from classes where id = pid;
     end if;
     update classes_history
        set effective_end_date = psysdate - NumTodsInterval(1, 'second')
        where id = pid
        and effective_end_date is null;
     rec.effective_start_date := psysdate;
     if deleting then rec.effective_end_date := psysdate; end if;
     rec.last_updated_by := user;
     if inserting then rec.operation_flag := 'I'; end if;
     if updating then rec.operation_flag := 'U'; end if;
     if deleting then rec.operation_flag := 'D'; end if;   
     -- exception when no_data_found then null; --no record in history table, likely trial was disabled before --<-- 2013.03.06 
     insert into classes_history values rec;
  end;
BEGIN
  j := classes_history_pkg.ids.first;
  WHILE j IS NOT NULL LOOP
      --xxmsz_tools.insertIntoEventLog('T2 id: '|| classes_history_pkg.ids (j) ,'I');
      process ( classes_history_pkg.ids (j) );
      j := classes_history_pkg.ids.next(j);
  END LOOP;
  classes_history_pkg.ids.delete;
  delete from classes_h_temp;  --<-- 2013.03.06
END;
/

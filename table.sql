CREATE TABLE AUDIT_DATA
(
  ID                    NUMBER                  NOT NULL,
  SOURCE_ID             NUMBER                  NOT NULL,
  SOURCE_SCHEMA_NAME    VARCHAR2(30 BYTE)       NOT NULL,
  SOURCE_TABLE_NAME     VARCHAR2(30 BYTE)       NOT NULL,
  SOURCE_COLUMN_NAME    VARCHAR2(30 BYTE)       NOT NULL,
  SOURCE_VALUE_CONTEXT  VARCHAR2(255 BYTE),
  OLD_VALUE             VARCHAR2(4000 BYTE),
  NEW_VALUE             VARCHAR2(4000 BYTE),
  OPERATION_TYPE        VARCHAR2(10 BYTE)       NOT NULL,
  OPERATION_TIME        TIMESTAMP(6)            NOT NULL,
  INITIATOR_IP          VARCHAR2(15 BYTE),
  INITIATOR_LOGIN       VARCHAR2(255 BYTE),
  SESSIONID             NUMBER,
  TRANSACTION_ID        NUMBER
);

COMMENT ON TABLE AUDIT_DATA IS 'ENCJA = Tabela audytowa * ALIAS = AUDA';

COMMENT ON COLUMN AUDIT_DATA.SOURCE_ID IS 'ATRYBUT ENCJI =  * OPIS = Unikalny identyfikator rekordu audytowanej tabeli ';

COMMENT ON COLUMN AUDIT_DATA.SOURCE_SCHEMA_NAME IS 'ATRYBUT ENCJI =  * OPIS = Nazwa schematu z ktorego pochodzi audytowana tabela ';

COMMENT ON COLUMN AUDIT_DATA.SOURCE_TABLE_NAME IS 'ATRYBUT ENCJI =  * OPIS = Nazwa audytowanej tabeli ';

COMMENT ON COLUMN AUDIT_DATA.SOURCE_COLUMN_NAME IS 'ATRYBUT ENCJI =  * OPIS = Nazwa audytowanej kolumny ';

COMMENT ON COLUMN AUDIT_DATA.SOURCE_VALUE_CONTEXT IS 'ATRYBUT ENCJI =  * OPIS = Dodatkowa informacja opisujaca kontekst uzycia danej kolumny (np. dla referencji do slownikow znaczenie danej kolumny) ';

COMMENT ON COLUMN AUDIT_DATA.OLD_VALUE IS 'ATRYBUT ENCJI =  * OPIS = Wartosc kolumny przed zmiana (konwersja do VARCHAR) - przy INSERT = NULL ';

COMMENT ON COLUMN AUDIT_DATA.NEW_VALUE IS 'ATRYBUT ENCJI =  * OPIS = Wartosc kolumny po zmianie (konwersja do VARCHAR) - przy DELETE = NULL ';

COMMENT ON COLUMN AUDIT_DATA.OPERATION_TYPE IS 'ATRYBUT ENCJI =  * OPIS = Typ operacji: INSERT, UPDATE, DELETE ';

COMMENT ON COLUMN AUDIT_DATA.OPERATION_TIME IS 'ATRYBUT ENCJI =  * OPIS = Dokladny czas dokonania zmiany ';

COMMENT ON COLUMN AUDIT_DATA.INITIATOR_IP IS 'ATRYBUT ENCJI =  * OPIS = Adres IP stacji roboczej z ktroej dokonano zmiany ';

COMMENT ON COLUMN AUDIT_DATA.INITIATOR_LOGIN IS 'ATRYBUT ENCJI =  * OPIS = Login osoby, ktora dokonala zmiany ';


CREATE UNIQUE INDEX AUDA_PK ON AUDIT_DATA
(ID);


ALTER TABLE AUDIT_DATA ADD (
  CONSTRAINT AUDA_PK
 PRIMARY KEY
 (ID)
    USING INDEX 
    TABLESPACE USERS
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
               ));


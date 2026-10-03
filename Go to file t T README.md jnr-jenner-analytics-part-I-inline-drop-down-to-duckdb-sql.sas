/*---
c:/utl/jnr-jenner-analytics-part-I-inline-drop-down-to-duckdb-sql.sas
 ---*/

Jenner Analytics-part-I-inline-drop-down-to-duckdb-sql.sas

Too long to post, see
https://github.com/rogerjdeangelis/jnr-jenner-analytics-part-I-inline-drop-down-to-duckdb-sql

CONTENTS

   1. Macro sandwich           - Compute average of age
   2. Macro wrapper interface  - Compute ave of  age, height and weight by sex
   3. Macro wrapper interface  - Execute macro interface inside a datastep

ENHANCEMENTS (PROC R and PROC PYTHON DO NOT SUPPPORT THESE ENHANCEMENTS)

   1.  Macro wrapper interface
   2.  Aditional quoting character, backtic
   3.  Can resolve imbededed macro variables
   4.  Can return a macro variable

The libname duckdb engine is under development along with duckdb passthru. But
currently you can use these two drop down intefaces. Thiese interface can
be used with any database/language that supports  or has a public odbc driver,
duckdb, mysql, postgreql, sql server, oracle,
sqlite, sybase, matlab(octave), r, python, perl, spss(pspp), powershell,
excel, google sheets, libre office, revolution R...
More interfaces to follow.I will defer to libname and passthru for sql when supported.

THE MACRO SANDWICH CONSISTS OF THREE SECTIONS.

 SECTION 2 THE MIDDLE FILLING IS THE RAW UNRESOLVED DUCKDB SQL SCRIPT

   cards4;
   create table class as select * from read_parquet(`&prq./class.parquet`);
   Create table avgAge as select 'avgAge' as name, avg(age) as age from class;
   ;;;;

 SECTION 1 APPLIES THE ENHANCEMENTS AND CREATES RESOLVED CODE FOR THE DUCKDB SCRIPT IN SECTON 2

 data _null_;
   file "&pth/duck_resolve.sql";
   input;
   if upcase("&resolve")=:"Y" then _infile_=resolve(_infile_); /*--- resolve the macro triggers ---*/
   if index(_infile_,"`") then
       _infile_=translate(_infile_,"27"x,"`");/*--- add addtional quote using the bactic        ---*/
   put _infile_;
   putlog _infile_;  /*--- echo resolved sql script to the log ---*/

 SECTION 3 EXECUTE THE RESOLVED SCRIPT AND RETURN A MACRO VARIABLE

   filename rut pipe "duckdb &duckdb -f &pth/duck_resolve.sql";  /*---
   run;quit;
   data _null_;
     infile rut;
     input;
     putlog _infile_;
   run;

   filename rut clear;

   /*---  DUCKDB DOES NOT SUPPORT THE WINDOWS CLIPBOARD SO USE PARQUET FILE ---*/
   %if "&return" ^= "" %then %do;
     data _null_;
      set "&prq.\clipboard.parquet";      /*--- created from the sql script ---*/
      input;
      putlog "*******  " macvar "  ********"; /*--- ECHO MACVAR TO LOG      ---*/
      call symputx("&return",macvar,"G");
     run;quit;
   %end;


/******************************************************************************************************************/
/* 1. MACRO SANDWICH MACROS                                                                                       */
/******************************************************************************************************************/

filename ft15f001 "c:/otojnr/jnr_duckbeginx.sas";
parmcards4;
%macro jnr_duckdeginx(
    resolve=
    )/des="Allow additional quote(backtic) and provide for macro resolution";

  %local pth;
  %let pth=%sysfunc(pathname(work));

  %utlfkil(&pth/duck_resolve.sql);

  data _null_;
    length _infile_ $255;
    file "&pth/duck_resolve.sql";
    input;
    if upcase("&resolve")=:"Y" then _infile_=resolve(_infile_);
    if index(_infile_,"`") then
        _infile_=translate(_infile_,"27"x,"`");
    put _infile_;
    putlog _infile_;

%mend jnr_duckdeginx;
;;;;
run;

filename ft15f001 "c:/otojnr/jnr_duckendx.sas";
parmcards4;
%macro jnr_duckendx(
   duckdb=d:/parquet/mydb.duckdb
   ,prq=d:/parquet
   ,return=numobs
   )/des="DUCKDB  execute sql script";
run;
  %local pth;
  %let pth=%sysfunc(pathname(work));
  options noxwait noxsync;
  filename rut pipe "duckdb &duckdb -f &pth/duck_resolve.sql";
  run;quit;
  data _null_;
    infile rut;
    input;
    putlog _infile_;
  run;

  filename rut clear;

  * use the clipboard to create macro variable;
  %if "&return" ^= "" %then %do;
    data _null_;
     set "&prq.\clipboard.parquet"; /*--- created from the sql script ---*/
     input;
     putlog "*******  " macvar "  ********";
     call symputx("&return",macvar,"G");
    run;quit;
  %end;

%mend jnr_duckendx;
;;;;
run;

/******************************************************************************************************************/
/* 1. MACRO SANDWICH PROCESS                                                                                      */
/******************************************************************************************************************/

/*--- CREATE CLASS PARQUET FILE ---*/
%let prq=d:/parquet;
libname prq parquet "&prq";

%utlfkil(d:/parquet\avgAge.parquet);

proc datasets lib=prq kill;
run;

data  prq.class;
    set sashelp.class(obs=3);
    keep name age;
run;

%jnr_duckdeginxrresolve=Y);
cards4;
drop table if exists class;
drop table if exists avgAge;
select * from read_parquet('d:/parquet\class.parquet');
create table class as select * from read_parquet('d:/parquet/class.parquet');
Create table avgAge as select 'avgAge' as name, avg(age) as age from class;
SHOW TABLES;
COPY (select count(*) as macvar from class) TO 'd:/parquet\clipboard.parquet' (FORMAT PARQUET);
COPY avgAge TO 'd:/parquet\avgAge.parquet' (FORMAT PARQUET);
;;;;
%jnr_duckendx(
    duckdb=&prq./mydb.duckdb
   ,prq=&prq
   ,return=numobs
   );

proc print data=prq.avgAge;
run;

/******************************************************************************************************************/
/* 1. LIST:  8:30:56                                                                                              */
/*    Obs    name  age                                                                                            */
/*                                                                                                                */
/*      1  avgAge   13                                                                                            */
/******************************************************************************************************************/

/******************************************************************************************************************/
/* 1. LOG MACRO SANDWICH                                                                                          */
/******************************************************************************************************************/

%let prq=d:/parquet;
libname prq parquet "&prq";

%utlfkil(d:/parquet\avgAge.parquet);

proc datasets lib=prq kill;
run;

data  prq.class;
    set sashelp.class(obs=3);
    keep name age;
run;

%jnr_duckdeginxrresolve=Y);
cards4;
drop table if exists class;
drop table if exists avgAge;
select * from read_parquet('d:/parquet\class.parquet');
create table class as select * from read_parquet('d:/parquet/class.parquet');
Create table avgAge as select 'avgAge' as name, avg(age) as age from class;
SHOW TABLES;
COPY (select count(*) as macvar from class) TO 'd:/parquet\clipboard.parquet' (FORMAT PARQUET);
COPY avgAge TO 'd:/parquet\avgAge.parquet' (FORMAT PARQUET);
;;;;
%jnr_duckendx(
    duckdb=&prq./mydb.duckdb
   ,prq=&prq
   ,return=numobs
   );

proc print data=prq.avgAge;
run;

/******************************************************************************************************************/
/* 2. MACRO WRAPPER INTERFACE - COMPLUTE SUM OF  AGE, HEIGHT AND WEIGHT BY SEX                                    */
/* SAVES MACRO IN YOUR AUTOCALL LIBRARY                                                                           */
/******************************************************************************************************************/

filename ft15f001 "c:/otojnr/jnr_submit_duckx.sas";
parmcards4;
%macro jnr_submit_duckx(
       pgm                            /*--- quoted sql script                                    ---*/
      ,duckdb=c:/temp/dbase.duckdb    /*--- duckdb database will be created if it does not exist ---*/
      ,resolve=N                      /*--- resolve any macro variables in the sql script        ---*/
      ,return=sqlObs                  /*--- name for the macro variable returned from duckdb     ---*/
      ,prq=d:/parquet                 /*--- where to store the inteface parquet files            ---*/
      )/des="drop down to duckdb sql";

   %local pth;

   %let pth = %sysfunc(pathname(work));

   %utlfkil(&pth/pgm.sql);
   %utlfkil(&pth/duck1.log);

   * write the program to a temporary file;
   filename py_pgm "&pth/pgm.sql" lrecl=32756 recfm=v;
   data _null_;
     length pgm  $32755 ;
     file py_pgm ;
     pgm=compbl(&pgm);
     if upcase("&resolve")=:"Y" then pgm=resolve(pgm);
     if index(pgm,"`") then
        pgm=translate(pgm,"27"x,"`");
     put pgm;
     putlog pgm;
   run;quit;

   filename rut pipe "duckdb &duckdb -f &pth/pgm.sql";

   data _null_;
     file print;
     infile rut;
     input;
     put _infile_;
     putlog _infile_;
   run;

   filename rut clear;
   filename py_pgm clear;

   * use the clipboard to create macro variable;
   %if "&return" ^= "" %then %do;
     data _null_;
      set '&prq\clipboard.parquet';
      input;
      putlog "*******  " macvar "  ********";
      call symputx("&return",macvar,"G");
     run;quit;
   %end;
%mend jnr_submit_duckx;
;;;;
run;

/******************************************************************************************************************/
/* 2. CREATE INPUT PARQUET FILE AND  GLOBAL MACRO VARIABLES AND CALL DROP DOWN TO DUCKDB                          */
/******************************************************************************************************************/

%let prq=d:/parquet;      /*--- path to parquet files ---*/

%let inptable=class;      /*--- to parquet file class    ---*/
%let outtable=avgclass;   /*--- to parquet file avgclass ---*/

%utlfkil(&prq./&inptable..parquet)
%utlfkil(&prq./&outtable..parquet)

libname prq parquet "&prq";

proc datasets lib=prq kill;
run;

 /*--- create class parquet file ---*/
data prq.class;
    set sashelp.class(obs=3);
run;

/******************************************************************************************************************/
/* 2. PROCESS DROP DOWN TO DUCKDB AND SUMMARIZE CLASS                                                             */
/******************************************************************************************************************/

%jnr_submit_duckx("
    drop table if exists &inptable;
    drop table if exists &outtable;
    select * from read_parquet('&prq./&inptable..parquet');
    create table &inptable as select * from read_parquet('&prq./&inptable..parquet');
    Create table &outtable as select sex, avg(age) as avgage, avg(weight) as avgwgt, avg(height) as avghgt from &inptable group by sex;
    SHOW TABLES;
    COPY (select count(*) as macvar from &inptable) TO '&prq.\clipboard.parquet' (FORMAT PARQUET);
    COPY &outtable TO '&prq.\avgclass.parquet' (FORMAT PARQUET);
    "
    ,duckdb=c:/temp/mydb.duckdb /*--- duckdb database will be created if it does not exist ---*/
    ,prq=&prq                   /*--- where to store the inteface parquet files            ---*/
    ,resolve=Y                  /*--- resolve macro variable induckdb sql                  ---*/
    ,return=numobs              /*--- return macro varable from duckdb                     ---*/
    );

%put &=numobs; /*--- number of obs in duckdb table class ---*/

%let prq=d:/parquet;
libname prq parquet "&prq";
proc print data=prq.avgclass;
run;

/*******************************************************************************************************************/
/* LIST: 14:08:35                                                                                                  */
/*  DUCKDB CLASS TABLE                                                                                             */
/* ┌─────────┬─────────┬───────┬────────┬────────┐                                                                 */
/* │  Name   │   Sex   │  Age  │ Height │ Weight │                                                                 */
/* │ varchar │ varchar │ int64 │ double │ int64  │                                                                 */
/* ├─────────┼─────────┼───────┼────────┼────────┤                                                                 */
/* │ Amir    │ M       │    13 │   61.2 │     95 │                                                                 */
/* │ Bethany │ F       │    14 │   63.8 │    105 │                                                                 */
/* │ Carlos  │ M       │    12 │   58.5 │     88 │                                                                 */
/* └─────────┴─────────┴───────┴────────┴────────┘                                                                 */
/* DUCKDB TABLES                                                                                                   */
/* ┌──────────┐                                                                                                    */
/* │   name   │                                                                                                    */
/* │ varchar  │                                                                                                    */
/* ├──────────┤                                                                                                    */
/* │ avgclass │                                                                                                    */
/* │ class    │                                                                                                    */
/* └──────────┘                                                                                                    */
/*                                                                                                                 */
/*  PARQUET TABLE BACK TO JENNER                                                                                   */
/*   Obs  Sex  avgage  avgwgt  avghgt                                                                              */
/*                                                                                                                 */
/*     1  F        14     105    63.8                                                                              */
/*     2  M      12.5    91.5   59.85                                                                              */
/*                                                                                                                 */
/*  NUMOBS=3                                                                                                       */
/*******************************************************************************************************************/

/*******************************************************************************************************************/
/* 2. LOG                                                                                                          */
/*******************************************************************************************************************/

NOTE: Copyright (c) 2026 Jenner Analytics Ltd., London, England.
NOTE: Jenner v1.5.86 (build v1.5.86+7f146e44cc.20260928T095324Z.x86_64-pc-windows-msvc)
      Licensed to Roger DeAngelis, Serial 3BF7B3E6.
NOTE: DATA _null_

autexec started.

NOTE: DATA elapsed:
  wall  0.00 seconds
  cpu   0.00 seconds
NOTE: DATA _null_

LOG:  10:35:15
NOTE: DATA _null_ completed. Output written to FILE PRINT
NOTE: Option SASAUTOS changed to c:/otojnr.
NOTE: Library WORKX assigned path=d:\wpswrkx.
NOTE: DATA _null_

NOTE: Reading from fileref c:/jnr/runsas_selection.sas (c:/jnr/runsas_selection.sas)
    1 %let prq=d:/parquet;      /*--- path to parquet files ---*/
    2
    3 %let inptable=class;      /*--- to parquet file class    ---*/
    4 %let outtable=avgclass;   /*--- to parquet file avgclass ---*/
    5
    6 %utlfkil(&prq./&inptable..parquet)
    7 %utlfkil(&prq./&outtable..parquet)
    8
    9 libname prq parquet "&prq";
   10
   11 proc datasets lib=prq kill;
   12 run;
   13
   14  /*--- create class parquet file ---*/
   15 data prq.class;
   16     set sashelp.class(obs=3);
   17 run;
   18
   19 /******************************************************************************************************************/
   20 /* DROP DOWN TO DUCKDB AND SUMMARIZE CLASS                                                                        */
   21 /******************************************************************************************************************/
   22
   23 %jnr_submit_duckx("
   24     drop table if exists &inptable;
   25     drop table if exists &outtable;
   26     select * from read_parquet('&prq./&inptable..parquet');
   27     create table &inptable as select * from read_parquet('&prq./&inptable..parquet');
   28     Create table &outtable as select sex, avg(age) as avgage, avg(weight) as avgwgt, avg(height) as avghgt from &inptable group by sex;
   29     SHOW TABLES;
   30     COPY (select count(*) as macvar from &inptable) TO '&prq.\clipboard.parquet' (FORMAT PARQUET);
   31     COPY &outtable TO '&prq.\avgclass.parquet' (FORMAT PARQUET);
   32     "
   33     ,duckdb=c:/temp/mydb.duckdb /*--- duckdb database will be created if it does not exist ---*/
   34     ,prq=&prq                   /*--- where to store the inteface parquet files            ---*/
   35     ,resolve=Y                  /*--- resolve macro variable induckdb sql                  ---*/
   36     ,return=numobs              /*--- return macro varable from duckdb                     ---*/
   37     );
   38
   39 %put &=numobs; /*--- number of obs in duckdb table class ---*/
   40
   41 %let prq=d:/parquet;
   42 libname prq parquet "&prq";
   43 proc print data=prq.avgclass;
   44 run;

NOTE: Read 44 rows from c:/jnr/runsas_selection.sas.
NOTE: DATA elapsed:
  wall  0.00 seconds
  cpu   0.00 seconds
NOTE: DATA _null_

autoexec completed  10:35:15

NOTE: DATA elapsed:
  wall  0.00 seconds
  cpu   0.00 seconds
The file d:/parquet/avgclass.parquet does not exist
NOTE: Library PRQ assigned path=d:/parquet.
NOTE: PROC DATASETS library=PRQ

NOTE:
                       Directory

       Libref             PRQ
       Engine             PARQUET
       Physical Name      d:/parquet

       (no members)

NOTE: KILL option deleted 0 member(s) from library PRQ.
NOTE: DATA prq.class


NOTE: Read 3 rows from sashelp.class.
NOTE: The data set PRQ.CLASS has 3 observations and 5 variables.
NOTE: DATA elapsed:
  wall  0.00 seconds
  cpu   0.00 seconds
The file D:\wpswrk/duck1.log does not exist
NOTE: Fileref PY_PGM assigned to D:\wpswrk/pgm.sql.
NOTE: DATA _null_

NOTE: Writing to fileref py_pgm (D:\wpswrk/pgm.sql)
 drop table if exists class; drop table if exists avgclass; select * from read_parquet('d:/parquet/class.parquet'); create table class as select * from read_parquet('d:/parquet/class.parquet'); Create table avgclass as select sex, avg(age) as avgage, avg(weight) as avgwgt, avg(height) as avghgt from class group by sex; SHOW TABLES; COPY (select count(*) as macvar from class) TO 'd:/parquet\clipboard.parquet' (FORMAT PARQUET); COPY avgclass TO 'd:/parquet\avgclass.parquet' (FORMAT PARQUET);
NOTE: DATA _null_ completed. Output written to fileref py_pgm (D:\wpswrk/pgm.sql)
NOTE: Fileref RUT assigned to device PIPE (payload: duckdb c:/temp/mydb.duckdb -f D:\wpswrk/pgm.sql).
NOTE: DATA _null_

NOTE: Reading from fileref rut (D:\wpswrk\jenner_pipe_RUT_b3274c28826e446c877ca91a84d662cb.tmp)
┌─────────┬─────────┬───────┬────────┬────────┐
│  Name   │   Sex   │  Age  │ Height │ Weight │
│ varchar │ varchar │ int64 │ double │ int64  │
├─────────┼─────────┼───────┼────────┼────────┤
│ Amir    │ M       │    13 │   61.2 │     95 │
│ Bethany │ F       │    14 │   63.8 │    105 │
│ Carlos  │ M       │    12 │   58.5 │     88 │
└─────────┴─────────┴───────┴────────┴────────┘
┌──────────┐
│   name   │
│ varchar  │
├──────────┤
│ avgclass │
│ class    │
└──────────┘

NOTE: Read 15 rows from rut.
NOTE: DATA elapsed:
  wall  0.01 seconds
  cpu   0.00 seconds
NOTE: Fileref RUT cleared.
NOTE: Fileref PY_PGM cleared.
NOTE: DATA _null_

*******  3   ********

NOTE: Read 1 rows from d:/parquet\clipboard.parquet.
NOTE: DATA elapsed:
  wall  0.00 seconds
  cpu   0.02 seconds
NUMOBS=3
NOTE: Library PRQ assigned path=d:/parquet.
NOTE: PROC PRINT data=prq.avgclass

NOTE: PROC PRINT completed: 2 observations printed, 4 variables


/******************************************************************************************************************/
/* 3. CALL DUCKDB INSIDE A DATSTEP                                                                                */
/******************************************************************************************************************/

/*--- create class parquet file ---*/
%let prq=d:/parquet;
libname prq parquet "&prq";

%utlfkil(&prq./class.parquet);
%utlfkil(&prq./clipboard.parquet);
%utlfkil(&prq./avgAge.parquet);

proc datasets lib=prq kill;
run;

data  prq.class;
    set sashelp.class(obs=3);
    keep name age;
run;

data workx.meta;

  set prq.class(in=a) prq.avgAge /* only needed for sas open=defer */ ;

     rc=dosubl("
      %jnr_submit_duckx(
         '
          drop table if exists class;
          drop table if exists avgAge;
          select * from read_parquet(`&prq./class.parquet`);
          create table class as select * from read_parquet(`&prq./class.parquet`);
          Create table avgAge as select `avgAge` as name, avg(age) as age from class;
          SHOW TABLES;
          COPY (select count(*) as macvar from class) TO `&prq./clipboard.parquet` (FORMAT PARQUET);
          COPY avgAge TO `&prq./avgAge.parquet` (FORMAT PARQUET);
         '
         ,duckdb=&prq./mydb.duckdb
         ,prq=&prq
         ,resolve=Y
         ,return=numobs
         );
    ");

    drop rc;

run;

%put Number of obs in CLASS Input Table = &numobs;

proc print data=workx.meta;
run;

/******************************************************************************************************************/
/* 3.  LIST: 11:20:19                                                                                             */
/*   ┌─────────┬───────┐                                                                                          */
/*   │  Name   │  Age  │                                                                                          */
/*   │ varchar │ int64 │                                                                                          */
/*   ├─────────┼───────┤                                                                                          */
/*   │ Amir    │    13 │                                                                                          */
/*   │ Bethany │    14 │                                                                                          */
/*   │ Carlos  │    12 │                                                                                          */
/*   └─────────┴───────┘                                                                                          */
/* TABLES IN DUCKDB                                                                                               */
/*   ┌─────────┐                                                                                                  */
/*   │  name   │                                                                                                  */
/*   │ varchar │                                                                                                  */
/*   ├─────────┤                                                                                                  */
/*   │ avgAge  │                                                                                                  */
/*   │ class   │                                                                                                  */
/*   └─────────┘                                                                                                  */
/*                                                                                                                */
/* NUMBER OF OBS IN CLASS INPUT TABLE = 3                                                                         */
/*                                                                                                                */
/*     Obs     Name  Age                                                                                          */
/*                                                                                                                */
/*       1  Amir      13                                                                                          */
/*       2  Bethany   14                                                                                          */
/*       3  Carlos    12                                                                                          */
/*       4  avgAge    13  > from DUCKDB <                                                                         */
/******************************************************************************************************************/

/*******************************************************************************************************************/
/* 3. LOG FOR CALLING MACRO INSIDE A DATASTEP                                                                      */
/*******************************************************************************************************************/

NOTE: Copyright (c) 2026 Jenner Analytics Ltd., London, England.
NOTE: Jenner v1.5.86 (build v1.5.86+7f146e44cc.20260928T095324Z.x86_64-pc-windows-msvc)
      Licensed to Roger DeAngelis, Serial 3BF7B3E6.
NOTE: DATA _null_

autexec started.

NOTE: DATA elapsed:
  wall  0.00 seconds
  cpu   0.00 seconds
NOTE: DATA _null_

LOG:  11:20:19
NOTE: DATA _null_ completed. Output written to FILE PRINT
NOTE: Option SASAUTOS changed to c:/otojnr.
NOTE: Library WORKX assigned path=d:\wpswrkx.
NOTE: DATA _null_

NOTE: Reading from fileref c:/jnr/runsas_selection.sas (c:/jnr/runsas_selection.sas)
    1 %let prq=d:/parquet;
    2 libname prq parquet "&prq";
    3
    4 proc datasets lib=prq kill;
    5 run;
    6
    7 data  prq.class;
    8     set sashelp.class(obs=3);
    9     keep name age;
   10 run;
   11
   12 data meta;
   13
   14   set prq.class(in=a) prq.avgAge /* only needed for sas open=defer */ ;
   15
   16      rc=dosubl("
   17       %jnr_submit_duckx(
   18          '
   19           drop table if exists class;
   20           drop table if exists avgAge;
   21           select * from read_parquet(`&prq./class.parquet`);
   22           create table class as select * from read_parquet(`&prq./class.parquet`);
   23           Create table avgAge as select `avgAge` as name, avg(age) as age from class;
   24           SHOW TABLES;
   25           COPY (select count(*) as macvar from class) TO `&prq./clipboard.parquet` (FORMAT PARQUET);
   26           COPY avgAge TO `&prq./avgAge.parquet` (FORMAT PARQUET);
   27          '
   28          ,duckdb=&prq./mydb.duckdb
   29          ,prq=&prq
   30          ,resolve=Y
   31          ,return=numobs
   32          );
   33     ");
   34
   35     put name= age=;
   36
   37 run;
   38
   39 proc print data=meta;
   40 run;

NOTE: Read 40 rows from c:/jnr/runsas_selection.sas.
NOTE: DATA elapsed:
  wall  0.00 seconds
  cpu   0.00 seconds
NOTE: DATA _null_

autoexec completed  11:20:19

NOTE: DATA elapsed:
  wall  0.00 seconds
  cpu   0.00 seconds
NOTE: Library PRQ assigned path=d:/parquet.
NOTE: PROC DATASETS library=PRQ

NOTE:
                       Directory

       Libref             PRQ
       Engine             PARQUET
       Physical Name      d:/parquet

       #    Name                             Member Type
       ----------------------------------------------------
       1    AVGAGE                           DATA
       2    CLASS                            DATA
       3    CLIPBOARD                        DATA

NOTE: KILL option deleted 3 member(s) from library PRQ.
NOTE: DATA prq.class


NOTE: Read 3 rows from sashelp.class.
NOTE: The data set PRQ.CLASS has 3 observations and 2 variables.
NOTE: DATA elapsed:
  wall  0.00 seconds
  cpu   0.00 seconds
The file D:\wpswrk/duck1.log does not exist
NOTE: Fileref PY_PGM assigned to D:\wpswrk/pgm.sql.
NOTE: DATA _null_

NOTE: Writing to fileref py_pgm (D:\wpswrk/pgm.sql)
 drop table if exists class; drop table if exists avgAge; select * from read_parquet('d:/parquet/class.parquet'); create table class as select * from read_parquet('d:/parquet/class.parquet'); Create table avgAge as select 'avgAge' as name, avg(age) as age from class; SHOW TABLES; COPY (select count(*) as macvar from class) TO 'd:/parquet/clipboard.parquet' (FORMAT PARQUET); COPY avgAge TO 'd:/parquet/avgAge.parquet' (FORMAT PARQUET);
NOTE: DATA _null_ completed. Output written to fileref py_pgm (D:\wpswrk/pgm.sql)
NOTE: Fileref RUT assigned to device PIPE (payload: duckdb d:/parquet/mydb.duckdb -f D:\wpswrk/pgm.sql).
NOTE: DATA _null_

NOTE: Reading from fileref rut (D:\wpswrk\jenner_pipe_RUT_ef19f2037cb6440ca1ec6e02132c9704.tmp)
┌─────────┬───────┐
│  Name   │  Age  │
│ varchar │ int64 │
├─────────┼───────┤
│ Amir    │    13 │
│ Bethany │    14 │
│ Carlos  │    12 │
└─────────┴───────┘
┌─────────┐
│  name   │
│ varchar │
├─────────┤
│ avgAge  │
│ class   │
└─────────┘

NOTE: Read 15 rows from rut.
NOTE: DATA elapsed:
  wall  0.00 seconds
  cpu   0.00 seconds
NOTE: Fileref RUT cleared.
NOTE: Fileref PY_PGM cleared.
NOTE: DATA _null_

*******  3   ********

NOTE: Read 1 rows from d:/parquet\clipboard.parquet.
NOTE: DATA elapsed:
  wall  0.00 seconds
  cpu   0.00 seconds
NOTE: DATA work.meta

name=Amir age=13
name=Bethany age=14
name=Carlos age=12
name=avgAge age=13

NOTE: Read 3 rows from prq.class.
NOTE: Read 1 rows from prq.avgAge.
NOTE: The data set WORK.META has 4 observations and 3 variables.
NOTE: DATA elapsed:
  wall  0.11 seconds
  cpu   0.11 seconds
NOTE: PROC PRINT data=meta

NOTE: PROC PRINT completed: 4 observations printed, 3 variables

/******************************************************************************************************************/
/* 3. END                                                                                                         */
/******************************************************************************************************************/

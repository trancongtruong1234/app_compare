@echo off

call MM_DMS\source.bat
call MM_DMS\result.bat

cd MM_DMS\demo_dbt-master
call  .venv\Scripts\activate
call start  dbt run

pause
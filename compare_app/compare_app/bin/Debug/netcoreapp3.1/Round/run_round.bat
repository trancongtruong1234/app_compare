@echo off
call Round\source.bat
call Round\result.bat
cd Round\demo_dbt-master
call venv\Scripts\activate
call start dbt run -s COMPARE_ROUND2 -s COMPARE_ROUND6 
pause
DECLARE
  runid NUMBER;
BEGIN
  runid := DBMS_HPROF.analyze(LOCATION=>'DATA_PUMP_DIR', FILENAME=>'unblockme.trc');
  DBMS_OUTPUT.PUT_LINE('runid = ' || runid);
END;
/

select * from DBMSHP_FUNCTION_INFO order by FUNCTION_ELAPSED_TIME;
select subtree_elapsed_time - function_elapsed_time pure_function_time,function,subtree_elapsed_time,function_elapsed_time,calls from dbmshp_function_info order by function_elapsed_time;

create or replace PROCEDURE                 BS_DISPOSITIVO_CISCO
IS
--v_authName author.author_last_name%type;
--Use the %TYPE attribute to anchor the datatype of a scalar
--variable to either another variable or to a column in a database
--table or view.
--Anchor to a local variable
--Use %ROWTYPE to anchor a record’s declaration
--to a cursor or table
v_serie         EDUARDO.BS_CISCO.SERIE%type;
v_max_dist      NUMBER;
today           DATE DEFAULT SYSDATE;
mytime_default  TIMESTAMP;
CURSOR c_dispo IS 
SELECT DISTINCT MODELO FROM EDUARDO.BS_COMPONENTE 
WHERE TIPO_COMP='DISPOSITIVO'     AND 
      MODELO IS NOT NULL          AND
      MODELO <> '<No SNMP>'       AND
      MODELO <> '0'               AND
      UPPER(MODELO) LIKE 'CISCO%'
      ;  --ELIMINAR ESTA CONDICION..
      
BEGIN
-- Display the date.
--ESTRUCTURAS DE CONTROL IF:
--IF caller_type = 'VIP' THEN
--generate_response('GOLD');
--ELSE
--generate_response('BRONZE');
--END IF;
--
--IF caller_type = 'VIP' THEN
--generate_response('GOLD');
--ELSIF priority_client THEN
--generate_response('SILVER');
--ELSE
--generate_response('BRONZE');
--END IF;
--
--CASE region_id
--WHEN 'NE' THEN
--mgr_name := 'MINER';
--WHEN 'SE' THEN
--mgr_name := 'KOOI';
--ELSE
--mgr_name := 'LANE';
--END CASE;
--
--FUNCION CASE:
--FUNCTION b2vc (flag IN BOOLEAN)
--RETURN VARCHAR2 IS
--BEGIN
--  RETURN
--    CASE flag
--      WHEN TRUE THEN 'True'
--      WHEN FALSE THEN 'False'
--      ELSE 'Null'
--  END;
--END;
--
--LOOPS:
--LOOP
--  FETCH company_cur INTO company_rec;
--  EXIT WHEN company_cur%ROWCOUNT > 5 OR
--  company_cur%NOTFOUND;
--  process_company(company_cur);
--END LOOP;
--
--FOR:
--FOR counter IN 1 .. 4
--  LOOP
--  DBMS_OUTPUT.PUT(counter);
--END LOOP;
--
-- FOR CURSOR:
--
--FOR emp_rec IN emp_cur
--  LOOP
--  IF emp_rec.title = 'Oracle Programmer'
--  THEN
--    give_raise(emp_rec.emp_id,30)
--  END IF;
--END LOOP;
--
--WHILE LOOP
--
--WHILE NOT end_of_analysis
--  LOOP
--  perform_analysis;
--  get_next_record;
--  IF analysis_cursor%NOTFOUND
--  AND next_step IS NULL
--  THEN
--    end_of_analysis := TRUE;
--  END IF;
--END LOOP;
--
--EXIT Statement
--EXIT [WHEN condition];
--
--CONTINUE Statement
--CONTINUE [label_name][WHEN boolean_expression];
--
--The optional label_name identifies which loop to terminate. If
--no label_name is specified, the innermost loop’s current iteration
--is terminated.
--
--BEGIN
--  <<day_loop>>
--  FOR counter IN 2 .. 6 LOOP
--    Skip Wednesdays
--    CONTINUE day_loop
--      WHEN dow_tab(counter)='Wednesday';
--    DBMS_OUTPUT.PUT_LINE (dow_tab(counter));
--  END LOOP;
--END;
--
--Sequences in PL/SQL
--my_variable := my_sequence.NEXTVAL;
--
--COMMIT
--COMMIT [WORK] [comment_text];
--
--ROLLBACK
--  ROLLBACK [WORK] [TO [SAVEPOINT] savepoint_name];
--
--SAVEPOINT
--  SAVEPOINT savepoint_name;
--
--CURSOR
--  CURSOR company_cur (id_in IN NUMBER) IS
--  SELECT * FROM company WHERE id = id_in;
--
--
--
FOR dispo IN c_dispo
  LOOP
     
      SELECT SERIE,MAX_PCT_COINCIDENCIA INTO   v_serie, v_max_dist 
      FROM 
      --INICIO DEL QUERY
       (SELECT  
          BS_CISCO.SERIE SERIE, 
        MAX(
          UTL_MATCH.JARO_WINKLER_SIMILARITY(REPLACE(UPPER(dispo.MODELO),'SERIE',''),'%CISCO%'||UPPER(BS_CISCO.SERIE))*0.5
          +
          CASE WHEN 
            EXP(-ABS(CAST(
            SUBSTR(REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(dispo.MODELO,'[a-z|A-Z]', '' ),'[-|+|/|.|()]',''),' ',''),1,4)
            AS INTEGER) 
            -
            CAST(
            SUBSTR(REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(BS_CISCO.SERIE,'[a-z|A-Z]', '' ),'[-|+|/|.|()]',''),' ',''),1,4)
            AS INTEGER
            )      
            )/1000
            )*50
          IS NOT NULL
          THEN
            EXP(-ABS(CAST(
            SUBSTR(REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(dispo.MODELO,'[a-z|A-Z]', '' ),'[-|+|/|.|()]',''),' ',''),1,4)
            AS INTEGER) 
            -
            CAST(
            SUBSTR(REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(BS_CISCO.SERIE,'[a-z|A-Z]', '' ),'[-|+|/|.|()]',''),' ',''),1,4)
            AS INTEGER
            )      
            )/1000
            )*50
          ELSE
            0
          END
          )  MAX_PCT_COINCIDENCIA
        FROM EDUARDO.BS_CISCO
        WHERE BS_CISCO.SERIE IS NOT NULL
        GROUP BY BS_CISCO.SERIE
        ORDER BY 
        MAX(
          UTL_MATCH.JARO_WINKLER_SIMILARITY(REPLACE(UPPER(dispo.MODELO),'SERIE',''),'%CISCO%'||UPPER(BS_CISCO.SERIE))*0.5
          +
          CASE WHEN 
            EXP(-ABS(CAST(
            SUBSTR(REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(dispo.MODELO,'[a-z|A-Z]', '' ),'[-|+|/|.|()]',''),' ',''),1,4)
            AS INTEGER) 
            -
            CAST(
            SUBSTR(REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(BS_CISCO.SERIE,'[a-z|A-Z]', '' ),'[-|+|/|.|()]',''),' ',''),1,4)
            AS INTEGER
            )      
            )/1000
            )*50
          IS NOT NULL
          THEN
            EXP(-ABS(CAST(
            SUBSTR(REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(dispo.MODELO,'[a-z|A-Z]', '' ),'[-|+|/|.|()]',''),' ',''),1,4)
            AS INTEGER) 
            -
            CAST(
            SUBSTR(REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(BS_CISCO.SERIE,'[a-z|A-Z]', '' ),'[-|+|/|.|()]',''),' ',''),1,4)
            AS INTEGER
            )      
            )/1000
            )*50
          ELSE
            0
          END
          )
      DESC)
      
      --FIN DEL QUERY
      WHERE ROWNUM =1;
      --WHERE MAX_PCT_COINCIDENCIA IS NOT NULL AND ROWNUM =1;
      --FETCH FIRST 1 ROWS ONLY;
      DBMS_OUTPUT.PUT_LINE (dispo.MODELO||'#'||v_serie||'#'||v_max_dist);
  END LOOP;
END BS_DISPOSITIVO_CISCO;
create or replace PROCEDURE         BS_DISPOSITIVO_CISCO( v_in_id_servicio    EDUARDO.BS_SERVICIO.ID_SERVICIO%type,
                                                          v_in_id_disciplina  EDUARDO.BS_DISCIPLINA.ID_DISCIP%type,
                                                          v_in_id_capa        EDUARDO.BS_CAPA.ID_CAPA%type,
                                                          v_in_fecha_ind      DATE)
IS
--PARA EJECUTAR EL PROCEDIMIETO ALMACENADO:
--EXEC EDUARDO.SHOW_THE_DATE('HOLA');
--v_authName author.author_last_name%type;
--Use the %TYPE attribute to anchor the datatype of a scalar
--variable to either another variable or to a column in a database
--table or view.
--Anchor to a local variable
--Use %ROWTYPE to anchor a record’s declaration
--to a cursor or table
v_id_ind_servicio               EDUARDO.BS_IND_SERVICIO.ID_IND_SERVICIO%type  ;
v_id_ind_discip                 EDUARDO.BS_IND_DISCIPLINA.ID_IND_DISCIP%type  ;
v_id_ind_capa                   EDUARDO.BS_IND_CAPA.ID_IND_CAPA%type          ;
v_serie                         EDUARDO.BS_CISCO.SERIE%type                   ;
v_fin_soporte                   EDUARDO.BS_CISCO.FIN_SOPORTE%type             ;
v_pct_ind_servicio              EDUARDO.BS_IND_SERVICIO.PCT_IND_SERVICIO%type ;
v_pct_ind_discip                EDUARDO.BS_IND_DISCIPLINA.PCT_IND_DISCIP%type ;
v_pct_ind_capa                  EDUARDO.BS_IND_CAPA.PCT_IND_CAPA%type         ;
v_max_dist                      NUMBER;
v_indice                        NUMBER;
today                           DATE DEFAULT SYSDATE;
mytime_default                  TIMESTAMP;
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
--v_indice :=1; --ASIGNACION ES CON :=
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
--EXCEPTIONS
--
-- BEGIN
--   SELECT ...
--   SELECT ...
--   SELECT ...
--   ...
-- EXCEPTION
--   WHEN NO_DATA_FOUND THEN 
--
--
--LIMPIEZA DE LA TABLA TEMPORAL..
--
DELETE FROM EDUARDO.BS_TEMP_MODELO_SERIE;

--v_fech_ind:= TRUNC(SYSDATE, 'mm');

FOR dispo IN c_dispo
  LOOP
     
      SELECT SERIE,MAX_PCT_COINCIDENCIA INTO   v_serie, v_max_dist 
      FROM 
      --INICIO DEL QUERY
       (SELECT  
          BS_CISCO.SERIE SERIE, 
        MAX(
          UTL_MATCH.JARO_WINKLER_SIMILARITY(REPLACE(REGEXP_REPLACE(UPPER(dispo.MODELO),'[0-9]',''),'SERIE',''),'%CISCO%'||UPPER(BS_CISCO.SERIE))*0.5
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
          UTL_MATCH.JARO_WINKLER_SIMILARITY(REPLACE(REGEXP_REPLACE(UPPER(dispo.MODELO),'[0-9]',''),'SERIE',''),'%CISCO%'||UPPER(BS_CISCO.SERIE))*0.5
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
      SELECT FIN_SOPORTE INTO v_fin_soporte FROM EDUARDO.BS_CISCO WHERE SERIE=v_serie;
      --CALCULO DEL INDICADOR
      --LAST_DAY(SYSDATE)     ULTIMO DIA DEL MES
      --TRUNC(SYSDATE, 'mm')  PRIMER DIA DEL MES
      IF v_fin_soporte='None Announced' THEN
        v_indice :=1.0; --ASIGNACION ES CON :=
      ELSIF TO_DATE(v_fin_soporte,'DD-MM-YYYY')< TRUNC(SYSDATE, 'mm')  THEN
         v_indice :=0.0;
      ELSE
         v_indice :=1.0;
      END IF;
      --ACTUALIZACION DE LA TABLA TEMPORAL DONDE SE ALMACENA LA FECHA FIN SOPORTE Y EL INDICE POR TIPO DE MODELO DEL COMPONENTE..
      INSERT INTO EDUARDO.BS_TEMP_MODELO_SERIE VALUES(dispo.MODELO,v_serie,v_fin_soporte,v_indice);
      
      DBMS_OUTPUT.PUT_LINE (dispo.MODELO||'#'||v_serie||'#'||v_max_dist||'#'||v_fin_soporte||'#'||v_indice);
  END LOOP;
  --
  --INSERTAR EN LA TABLA BS_ID_IND_SALUD_COMPONENTE:
  --
  INSERT INTO EDUARDO.BS_IND_SALUD_COMPONENTE 
         (FE_IND,PCT_VALOR,BS_METRICA_ID_METRICA,BS_COMPONENTE_ID_COMP,BS_DESTINO_BCO_ID_DESTINO_BCO)
  SELECT  v_in_fecha_ind,BSTMS.PCT_VALOR,36,BSC.ID_COMP,916
  FROM    EDUARDO.BS_COMPONENTE        BSC
  JOIN    EDUARDO.BS_TEMP_MODELO_SERIE BSTMS
  ON      BSC.MODELO=BSTMS.MODELO ;
  --
  --BLOQUE PARA UPDATE O INSERT EL CALCULO DE LOS INDICADORES EN 
  --BS_IND_SERVICIO, BS_IND_DISCIPLICA, BS_IND_CAPA
  --
  --CALCULAR EL INDICADOR POR SERVICIO.
  --
  SELECT 
    AVG(PCT_VALOR)
    INTO
    v_pct_ind_servicio
  FROM
    EDUARDO.BS_IND_SALUD_COMPONENTE
  WHERE 
    BS_COMPONENTE_ID_COMP IN (SELECT ID_COMP FROM EDUARDO.BS_COMPONENTE 
                              WHERE BS_SERVICIO_ID_SERVICIO=v_in_id_servicio);
                              
  BEGIN
  --UPDATE EN LA TABLA BS_IND_SERVICIO
  --SE RECUPERA EL SERVICIO DEL COMPONENTE: BS_SERVICIO_ID_SERVICIO
    UPDATE EDUARDO.BS_IND_SERVICIO 
    SET    PCT_IND_SERVICIO            = v_pct_ind_servicio
    WHERE  FE_IND                      = v_in_fecha_ind      AND 
           BS_SERVICIO_ID_SERVICIO     = v_in_id_servicio;
    --
    DBMS_OUTPUT.PUT_LINE('Data encontada en BS_IND_SERVICIO:');
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    --INSERT EN LA TABLA EN CASO QUE NO EXISTA.
    INSERT INTO EDUARDO.BS_IND_SERVICIO 
    (PCT_IND_SERVICIO,FE_IND,BS_SERVICIO_ID_SERVICIO)
    VALUES
    (v_pct_ind_servicio,v_in_fecha_ind,v_in_id_servicio);
    --
    DBMS_OUTPUT.PUT_LINE('Data no encontada');
  END;
  --
  --CALCULAR EL INDICADOR DE LA DISCIPLINA PARA EL SERVICIO
  --
  SELECT 
    AVG(PCT_VALOR)
    INTO
    v_pct_ind_discip
  FROM
    EDUARDO.BS_IND_SALUD_COMPONENTE
  WHERE 
    BS_COMPONENTE_ID_COMP IN (SELECT ID_COMP FROM EDUARDO.BS_COMPONENTE 
                              WHERE BS_SERVICIO_ID_SERVICIO=v_in_id_servicio) AND
    BS_METRICA_ID_METRICA IN (SELECT ID_METRICA FROM EDUARDO.BS_METRICA
                              WHERE BS_DISCIPLINA_ID_DISCIP = v_in_id_disciplina );
                              
  BEGIN
  --UPDATE EN LA TABLA BS_IND_DISCIPLINA
    SELECT ID_IND_SERVICIO
    INTO   v_id_ind_servicio
    FROM   EDUARDO.BS_IND_SERVICIO
    WHERE  BS_SERVICIO_ID_SERVICIO= v_in_id_servicio AND
           FE_IND                 = v_in_fecha_ind   ;
    
    UPDATE EDUARDO.BS_IND_DISCIPLINA 
    SET    PCT_IND_DISCIP              = v_pct_ind_discip
    WHERE  FE_IND                      = v_in_fecha_ind      AND 
           BS_DISCIPLINA_ID_DISCIP     = v_in_id_disciplina  AND
           BS_IND_SERV_ID_IND_SERV     = v_id_ind_servicio;
    DBMS_OUTPUT.PUT_LINE('Data encontada');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    --INSERT EN LA TABLA EN CASO QUE NO EXISTA.
    INSERT INTO EDUARDO.BS_IND_DISCIPLINA 
    (PCT_IND_DISCIP,FE_IND,BS_DISCIPLINA_ID_DISCIP,BS_IND_SERV_ID_IND_SERV)
    VALUES
    (v_pct_ind_discip,v_in_fecha_ind,v_in_id_disciplina,v_id_ind_servicio);
    DBMS_OUTPUT.PUT_LINE('Data no encontada');
  END;
  --
  --CALCULAR EL INDICADOR DE LA CAPA PARA LA DISCIPLINA Y EL SERVICIO
  --
  SELECT 
    AVG(PCT_VALOR)
    INTO
    v_pct_ind_capa
  FROM
    EDUARDO.BS_IND_SALUD_COMPONENTE
  WHERE 
    BS_COMPONENTE_ID_COMP IN (SELECT ID_COMP FROM EDUARDO.BS_COMPONENTE 
                              WHERE  BS_SERVICIO_ID_SERVICIO = v_in_id_servicio)       AND
    BS_METRICA_ID_METRICA IN (SELECT ID_METRICA FROM EDUARDO.BS_METRICA
                              WHERE  BS_DISCIPLINA_ID_DISCIP = v_in_id_disciplina    AND
                                     BS_CAPA_ID_CAPA         = v_in_id_capa
                              )  ;
  BEGIN
  --UPDATE EN LA TABLA BS_IND_CAPA
    SELECT ID_IND_DISCIP
    INTO   v_id_ind_discip
    FROM   EDUARDO.BS_IND_DISCIPLINA
    WHERE  BS_DISCIPLINA_ID_DISCIP = v_in_id_disciplina AND
           FE_IND                  = v_in_fecha_ind     AND
           BS_IND_SERV_ID_IND_SERV = v_id_ind_servicio  ;
    --       
    UPDATE EDUARDO.BS_IND_CAPA 
    SET    PCT_IND_CAPA                = v_pct_ind_capa
    WHERE  FE_IND                      = v_in_fecha_ind      AND 
           BS_CAPA_ID_CAPA             = v_in_id_capa        AND
           BS_IND_DIS_ID_IND_DISCIP    = v_id_ind_discip;
    DBMS_OUTPUT.PUT_LINE('Data encontada');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    --INSERT EN LA TABLA EN CASO QUE NO EXISTA.
    INSERT INTO EDUARDO.BS_IND_CAPA 
    (PCT_IND_CAPA,FE_IND,BS_CAPA_ID_CAPA,BS_IND_DIS_ID_IND_DISCIP)
    VALUES
    (v_pct_ind_capa,v_in_fecha_ind,v_in_id_capa,v_id_ind_discip);
    DBMS_OUTPUT.PUT_LINE('Data no encontada');
  END;
END BS_DISPOSITIVO_CISCO;
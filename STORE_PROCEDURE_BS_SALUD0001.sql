--STORE PROCEDURE SALUD
create or replace PROCEDURE                                 BS_DISPOSITIVO_CISCO( 
                                                v_in_id_servicio    EDUARDO.BS_SERVICIO.ID_SERVICIO%type,
                                                v_in_id_disciplina  EDUARDO.BS_DISCIPLINA.ID_DISCIP%type,
                                                v_in_id_capa        EDUARDO.BS_CAPA.ID_CAPA%type,
                                                v_in_id_dest_bco    EDUARDO.BS_DESTINO_BCO.ID_DESTINO_BCO%type,
                                                v_in_fecha_ind      VARCHAR2
                                                )
    IS
    v_count                         NUMBER                                        ;
    v_id_ind_servicio               EDUARDO.BS_IND_SERVICIO.ID_IND_SERVICIO%type  ;
    v_id_ind_discip                 EDUARDO.BS_IND_DISCIPLINA.ID_IND_DISCIP%type  ;
    v_id_ind_capa                   EDUARDO.BS_IND_CAPA.ID_IND_CAPA%type          ;
    v_serie                         EDUARDO.BS_CISCO.SERIE%type                   ;
    v_id_metrica                    EDUARDO.BS_METRICA.ID_METRICA%type            ;
    v_fin_soporte                   EDUARDO.BS_CISCO.FIN_SOPORTE%type             ;
    v_pct_ind_servicio              EDUARDO.BS_IND_SERVICIO.PCT_IND_SERVICIO%type ;
    v_pct_ind_discip                EDUARDO.BS_IND_DISCIPLINA.PCT_IND_DISCIP%type ;
    v_pct_ind_capa                  EDUARDO.BS_IND_CAPA.PCT_IND_CAPA%type         ;
    v_pct_peso                      EDUARDO.BS_DISCIPLINA.PCT_DISCP%type          ;
    v_max_dist                      NUMBER                                        ;
    v_indice                        NUMBER                                        ;
    today                           DATE DEFAULT SYSDATE                          ;
    mytime_default                  TIMESTAMP                                     ;
    CURSOR c_dispo IS 
    SELECT DISTINCT MODELO FROM EDUARDO.BS_COMPONENTE 
    WHERE TIPO_COMP='DISPOSITIVO'     AND 
          MODELO IS NOT NULL          AND
          MODELO <> '<No SNMP>'       AND
          MODELO <> '0'               AND
          UPPER(MODELO) LIKE 'CISCO%'
          ;  --ELIMINAR ESTA CONDICION..
          
    BEGIN
      SELECT ID_METRICA INTO v_id_metrica FROM EDUARDO.BS_METRICA 
      WHERE BS_CAPA_ID_CAPA=v_in_id_capa AND BS_DISCIPLINA_ID_DISCIP=v_in_id_disciplina;
      --
      SELECT PCT_DISCP INTO v_pct_peso FROM EDUARDO.BS_DISCIPLINA
      WHERE ID_DISCIP=v_in_id_disciplina;
   
      --ACTUALIZA LA TABLA DE MODELOS - SERIE - FECHA FIN DE SOPORTE..
      BS_SP_TAB_TEMP_MOD_SERIE(v_in_fecha_ind);
      --
      --ELIMINAR LA TABLA BS_ID_IND_SALUD_COMPONENTE:
      --TO_CHAR(FE_IND,'DD-MM-YYYY')='01-08-2017'
      --
      DELETE FROM EDUARDO.BS_IND_SALUD_COMPONENTE 
      WHERE  TO_CHAR(FE_IND,'DD-MM-YYYY')  = v_in_fecha_ind AND
             BS_METRICA_ID_METRICA         = v_id_metrica   AND
             BS_COMPONENTE_ID_COMP  IN (
                                        SELECT  ID_COMP
                                        FROM    EDUARDO.BS_COMPONENTE
                                        WHERE   BS_SERVICIO_ID_SERVICIO = v_in_id_servicio
                                        );
      COMMIT;
      --
      --INSERTAR EN LA TABLA BS_ID_IND_SALUD_COMPONENTE:
      --
      INSERT INTO EDUARDO.BS_IND_SALUD_COMPONENTE 
             (FE_IND,PCT_VALOR,BS_METRICA_ID_METRICA,BS_COMPONENTE_ID_COMP,BS_DESTINO_BCO_ID_DESTINO_BCO)
      SELECT  
        TO_DATE(v_in_fecha_ind,'DD-MM-YYYY'),
        CASE WHEN BSTMS.FIN_SOPORTE='None Announced' 
        THEN 1.0
        ELSE CASE WHEN TO_DATE(BSTMS.FIN_SOPORTE,'DD-MM-YYYY')<= TO_DATE(v_in_fecha_ind,'DD-MM-YYYY')            
             THEN 0.0
             ELSE 1.0
             END
        END   ,
        v_id_metrica,
        BSC.ID_COMP,
        v_in_id_dest_bco
        FROM    EDUARDO.BS_COMPONENTE        BSC
        JOIN    EDUARDO.BS_TEMP_MODELO_SERIE BSTMS
        ON      BSC.MODELO=BSTMS.MODELO 
        WHERE   BS_SERVICIO_ID_SERVICIO = v_in_id_servicio;
      COMMIT;
      --
      --CALCULAR EL INDICADOR POR SERVICIO.
      --
      SELECT 
        v_pct_peso*AVG(PCT_VALOR)
        INTO
        v_pct_ind_servicio
      FROM
        EDUARDO.BS_IND_SALUD_COMPONENTE
      WHERE 
        BS_COMPONENTE_ID_COMP IN (SELECT ID_COMP FROM EDUARDO.BS_COMPONENTE 
                                  WHERE BS_SERVICIO_ID_SERVICIO=v_in_id_servicio);
                                  
      BEGIN
      --UPDATE EN LA TABLA BS_IND_SERVICIO
        UPDATE EDUARDO.BS_IND_SERVICIO 
        SET    PCT_IND_SERVICIO               = v_pct_ind_servicio
        WHERE  TO_CHAR(FE_IND,'DD-MM-YYYY')   = v_in_fecha_ind      AND 
               BS_SERVICIO_ID_SERVICIO        = v_in_id_servicio;
        IF SQL%ROWCOUNT=0 THEN
        --SI NO EXISTE EL REGISTRO SE CREA EN LA TABLA BS_IND_SERVICIO
            INSERT INTO EDUARDO.BS_IND_SERVICIO 
            (PCT_IND_SERVICIO,FE_IND,BS_SERVICIO_ID_SERVICIO)
            VALUES
            (v_pct_ind_servicio,TO_DATE(v_in_fecha_ind,'DD-MM-YYYY'),v_in_id_servicio);
            --
            DBMS_OUTPUT.PUT_LINE('Insertado en BS_IND_SERVICIO');
        END IF;
        COMMIT;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Registreo no Encontrado');
        
      END;
      --PORCENTAJES POR DISCIPLINAS
      --•	25% Capacidad
      --•	25% Rendimiento
      --•	25% Obsolescencia 
      --•	15% Comportamiento
      --•	10% Cumplimiento

      --CALCULAR EL INDICADOR DE LA DISCIPLINA PARA EL SERVICIO
      --
      SELECT 
        v_pct_peso*AVG(PCT_VALOR)
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
          SELECT ID_IND_SERVICIO
          INTO   v_id_ind_servicio
          FROM   EDUARDO.BS_IND_SERVICIO
          WHERE  BS_SERVICIO_ID_SERVICIO= v_in_id_servicio AND
                 FE_IND                 = v_in_fecha_ind   ;
          --UPDATE EN LA TABLA BS_IND_DISCIPLINA
          UPDATE EDUARDO.BS_IND_DISCIPLINA 
          SET    PCT_IND_DISCIP              = v_pct_ind_discip
          WHERE  FE_IND                      = v_in_fecha_ind      AND 
                 BS_DISCIPLINA_ID_DISCIP     = v_in_id_disciplina  AND
                 BS_IND_SERV_ID_IND_SERV     = v_id_ind_servicio;
          --SI NO EXISTE EL REGISREO SE CREA EN LA TABLA BS_IND_DISCIPLINA       
          IF SQL%ROWCOUNT=0 THEN
            INSERT INTO EDUARDO.BS_IND_DISCIPLINA 
            (PCT_IND_DISCIP,FE_IND,BS_DISCIPLINA_ID_DISCIP,BS_IND_SERV_ID_IND_SERV)
            VALUES
            (v_pct_ind_discip,TO_DATE(v_in_fecha_ind,'DD-MM-YYYY'),v_in_id_disciplina,v_id_ind_servicio);
            DBMS_OUTPUT.PUT_LINE('Data no encontada'); 
          END IF;
          COMMIT;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
          DBMS_OUTPUT.PUT_LINE('Error: Registreo no Encontrado');
      END;
      --
      --CALCULAR EL INDICADOR DE LA CAPA PARA LA DISCIPLINA Y EL SERVICIO
      --
      SELECT 
        v_pct_peso*AVG(PCT_VALOR)
        INTO
        v_pct_ind_capa
      FROM
        EDUARDO.BS_IND_SALUD_COMPONENTE
      WHERE 
        BS_COMPONENTE_ID_COMP IN (SELECT ID_COMP FROM EDUARDO.BS_COMPONENTE 
                                  WHERE  BS_SERVICIO_ID_SERVICIO = v_in_id_servicio)     AND
        BS_METRICA_ID_METRICA IN (SELECT ID_METRICA FROM EDUARDO.BS_METRICA
                                  WHERE  BS_DISCIPLINA_ID_DISCIP = v_in_id_disciplina    AND
                                         BS_CAPA_ID_CAPA         = v_in_id_capa
                                  )  ;
      BEGIN
        SELECT ID_IND_DISCIP
        INTO   v_id_ind_discip
        FROM   EDUARDO.BS_IND_DISCIPLINA
        WHERE  BS_DISCIPLINA_ID_DISCIP = v_in_id_disciplina AND
               FE_IND                  = v_in_fecha_ind     AND
               BS_IND_SERV_ID_IND_SERV = v_id_ind_servicio  ;
       --UPDATE EN LA TABLA BS_IND_CAPA     
        UPDATE EDUARDO.BS_IND_CAPA 
        SET    PCT_IND_CAPA                = v_pct_ind_capa
        WHERE  FE_IND                      = v_in_fecha_ind      AND 
               BS_CAPA_ID_CAPA             = v_in_id_capa        AND
               BS_IND_DIS_ID_IND_DISCIP    = v_id_ind_discip;
        IF SQL%ROWCOUNT=0 THEN
        --NO ENCONTRO EL REGISTRO, SE INSERTA EN IND_CAPA
          INSERT INTO EDUARDO.BS_IND_CAPA 
          (PCT_IND_CAPA,FE_IND,BS_CAPA_ID_CAPA,BS_IND_DIS_ID_IND_DISCIP)
          VALUES
          (v_pct_ind_capa,TO_DATE(v_in_fecha_ind,'DD-MM-YYYY'),v_in_id_capa,v_id_ind_discip);
          DBMS_OUTPUT.PUT_LINE('Data no encontada');    
        END IF;
        COMMIT;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Registreo no Encontrado');
      END;
    END BS_DISPOSITIVO_CISCO;
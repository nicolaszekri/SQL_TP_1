-- Triggers
    --Question 1 : ALL_WORKERS_ELAPSED
CREATE OR REPLACE TRIGGER insert_worker_all_workers_elapsed
INSTEAD OF INSERT ON ALL_WORKERS_ELAPSED
FOR EACH ROW
BEGIN
    IF :NEW.start_date IS NOT NULL THEN
        -- Insertion dans WORKERS_FACTORY_2
        INSERT INTO WORKERS_FACTORY_2 (first_name, last_name, start_date)
        VALUES (:NEW.first_name, :NEW.last_name, :NEW.start_date);
    ELSE
        -- Insertion dans WORKERS_FACTORY_1
        INSERT INTO WORKERS_FACTORY_1 (first_name, last_name, age, first_day, last_day)
        VALUES (:NEW.first_name, :NEW.last_name, :NEW.age, SYSDATE, NULL);
    END IF;
END;
/
    --Question 2 : AUDIT_ROBOT
CREATE OR REPLACE TRIGGER TRG_INSERT_AUDIT_ROBOT
AFTER INSERT ON ROBOTS
FOR EACH ROW
BEGIN
    -- Insérer la nouvelle entrée dans la table AUDIT_ROBOT avec la date d'ajout actuelle
    INSERT INTO AUDIT_ROBOT (robot_id, created_at) VALUES (:NEW.id, SYSDATE);
END;
/
    --Question 3 :
CREATE OR REPLACE TRIGGER TRG_PREVENT_MODIFICATION_ROBOTS_FACTORIES
BEFORE INSERT OR UPDATE OR DELETE ON ROBOTS_FACTORIES
FOR EACH ROW
DECLARE
    v_num_factories NUMBER;
    v_num_workers_tables NUMBER;
BEGIN
    -- Compter le nombre d'usines dans la table FACTORIES
    SELECT COUNT(*) INTO v_num_factories FROM FACTORIES;

    -- Compter le nombre de tables de travailleurs respectant le format WORKERS_FACTORY_<N>
    SELECT COUNT(*) INTO v_num_workers_tables
    FROM user_tables
    WHERE table_name LIKE 'WORKERS_FACTORY\_%' ESCAPE '\';
    --Question 4 : 
CREATE OR REPLACE TRIGGER TRG_CALCULATE_WORKER_DURATION
BEFORE INSERT OR UPDATE OF last_day ON WORKERS_FACTORY_1
FOR EACH ROW
DECLARE
    v_duration NUMBER;
BEGIN
    -- Calculer la durée du temps passé dans l'usine
    IF :NEW.last_day IS NOT NULL AND :OLD.last_day IS NULL THEN
        v_duration := ROUND((:NEW.last_day - :NEW.first_day), 2);
    ELSE
        v_duration := NULL;
    END IF;
    
    -- Vérifier si la colonne pour stocker la durée du temps passé existe
    BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE WORKERS_FACTORY_1 ADD (time_spent NUMBER(10,2))';
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- Ignorer l'erreur si la colonne existe déjà
    END;
    
    -- Assigner la valeur de la durée du temps passé à la nouvelle colonne time_spent
    EXECUTE IMMEDIATE 'UPDATE WORKERS_FACTORY_1 SET time_spent = :1 WHERE id = :2'
        USING v_duration, :NEW.id;
END;
/
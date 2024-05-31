-- Fonctions
    -- Question 1 : GET_NB_WORKERS
CREATE OR REPLACE FUNCTION GET_NB_WORKERS( 
    FACTOR NUMBER 
) 
RETURN NUMBER 
IS 
    -- Déclare une variable pour stocker le nombre de travailleurs
    NUM_WORKERS NUMBER; 
BEGIN 
    -- Sélectionne le nombre de travailleurs dans les deux usines
    SELECT COUNT(*) INTO NUM_WORKERS 
    FROM ( 
        -- Sélectionne les travailleurs de la première usine
        SELECT 1  
        FROM WORKERS_FACTORY_1  
        WHERE last_day IS NULL  -- Seuls les travailleurs actifs (ceux dont la date de fin est NULL)
        AND FACTOR = 1          -- Vérifie que le paramètre FACTOR est égal à 1 pour la première usine
        AND EXISTS (            -- Vérifie l'existence de l'usine avec id 1 dans la table FACTORIES
            SELECT 1 
            FROM FACTORIES 
            WHERE id = 1 
        ) 
        UNION ALL 
        -- Sélectionne les travailleurs de la deuxième usine
        SELECT 1  
        FROM WORKERS_FACTORY_2  
        WHERE end_date IS NULL  -- Seuls les travailleurs actifs (ceux dont la date de fin est NULL)
        AND FACTOR = 2          -- Vérifie que le paramètre FACTOR est égal à 2 pour la deuxième usine
        AND EXISTS (            -- Vérifie l'existence de l'usine avec id 2 dans la table FACTORIES
            SELECT 1 
            FROM FACTORIES 
            WHERE id = 2 
        ) 
    ); 
     
    -- Retourne le nombre de travailleurs trouvés
    RETURN NUM_WORKERS; 
EXCEPTION 
    WHEN NO_DATA_FOUND THEN 
        -- Si aucune donnée n'est trouvée, retourne 0
        RETURN 0; 
    WHEN OTHERS THEN
        -- Gère toutes les autres exceptions en les levant avec un message d'erreur
        RAISE_APPLICATION_ERROR(-20001, 'An error occurred: ' || SQLERRM);
END GET_NB_WORKERS;
/ 

    -- Question 2 : GET_NB_BIG_ROBOTS
CREATE OR REPLACE FUNCTION GET_NB_BIG_ROBOTS RETURN NUMBER IS
    NUM_BIG_ROBOTS NUMBER;
BEGIN
    -- Compter le nombre de robots ayant plus de 3 pièces détachées
    SELECT COUNT(*)
    INTO NUM_BIG_ROBOTS
    FROM (
        SELECT robot_id
        FROM ROBOTS_HAS_SPARE_PARTS
        GROUP BY robot_id
        HAVING COUNT(spare_part_id) > 3
    );

    RETURN NUM_BIG_ROBOTS;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'An error occurred: ' || SQLERRM);
END GET_NB_BIG_ROBOTS;
/

    --Question 3 : GET_BEST_SUPPLIER
CREATE OR REPLACE FUNCTION GET_BEST_SUPPLIER RETURN VARCHAR2(100) IS
    BEST_SUPPLIER_NAME VARCHAR2(100);
BEGIN
    -- Sélectionne le nom du meilleur fournisseur depuis la vue BEST_SUPPLIERS
    SELECT supplier_name INTO BEST_SUPPLIER_NAME
    FROM BEST_SUPPLIERS;

    RETURN BEST_SUPPLIER_NAME;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL; -- Si aucune donnée n'est trouvée, retourne NULL
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'An error occurred: ' || SQLERRM);
END GET_BEST_SUPPLIER;
/

    --Question 4 : GET_OLDEST_WORKER
CREATE OR REPLACE FUNCTION GET_OLDEST_WORKER RETURN NUMBER IS
    OLDEST_WORKER_ID NUMBER;
BEGIN
    -- Sélectionne l'identifiant du travailleur le plus ancien parmi tous les travailleurs de toutes les usines
    SELECT worker_id INTO OLDEST_WORKER_ID
    FROM (
        SELECT worker_id, MIN(start_date) AS min_start_date
        FROM (
            SELECT id AS worker_id, first_day AS start_date
            FROM WORKERS_FACTORY_1
            UNION ALL
            SELECT worker_id, start_date
            FROM WORKERS_FACTORY_2
        )
        GROUP BY worker_id
        ORDER BY min_start_date ASC
    )
    WHERE ROWNUM = 1;

    RETURN OLDEST_WORKER_ID;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL; -- Si aucune donnée n'est trouvée, retourne NULL
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'An error occurred: ' || SQLERRM);
END GET_OLDEST_WORKER;
/

-- Procédures
    -- Question 1 : SEED_DATA_WORKERS
CREATE OR REPLACE PROCEDURE SEED_DATA_WORKERS(
    NB_WORKERS NUMBER,
    FACTORY_ID NUMBER
) AS
    v_first_name VARCHAR2(100);
    v_last_name VARCHAR2(100);
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    FOR i IN 1..NB_WORKERS LOOP
        v_first_name := 'worker_f_' || i;
        v_last_name := 'worker_l_' || i;
        v_start_date := TO_DATE('01-JAN-2065', 'DD-MON-YYYY') + DBMS_RANDOM.VALUE(0, 1826); -- 1826 days is approximately 5 years
        
        IF FACTORY_ID = 1 THEN
            INSERT INTO WORKERS_FACTORY_1 (first_name, last_name, age, first_day, last_day)
            VALUES (v_first_name, v_last_name, ROUND(DBMS_RANDOM.VALUE(20, 60)), v_start_date, NULL);
        ELSIF FACTORY_ID = 2 THEN
            INSERT INTO WORKERS_FACTORY_2 (first_name, last_name, start_date, end_date)
            VALUES (v_first_name, v_last_name, v_start_date, NULL);
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'Invalid FACTORY_ID. Must be 1 or 2.');
        END IF;
    END LOOP;
END;
/

    -- Question 2 : ADD_NEW_ROBOT
CREATE OR REPLACE PROCEDURE ADD_NEW_ROBOT(MODEL_NAME VARCHAR2) AS
    v_robot_id NUMBER;
    v_factory_id NUMBER;
BEGIN
    -- Étape 1: Insérer le nouveau robot dans la table ROBOTS et obtenir l'ID généré
    INSERT INTO ROBOTS (model)
    VALUES (MODEL_NAME)
    RETURNING id INTO v_robot_id;

    -- Étape 2: Sélectionner l'usine avec le moins de robots
    BEGIN
        SELECT factory_id
        INTO v_factory_id
        FROM (
            SELECT factory_id, COUNT(*) AS num_robots
            FROM ROBOTS_FROM_FACTORY
            GROUP BY factory_id
            ORDER BY num_robots ASC
        )
        WHERE ROWNUM = 1;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Si aucune usine n'est trouvée (cas rare), affecter une usine par défaut (par exemple, 1)
            v_factory_id := 1;
    END;

    -- Étape 3: Insérer l'ID du robot et l'ID de l'usine dans la table ROBOTS_FROM_FACTORY
    INSERT INTO ROBOTS_FROM_FACTORY (robot_id, factory_id)
    VALUES (v_robot_id, v_factory_id);

    -- Étape 4: Afficher un message de confirmation
    DBMS_OUTPUT.PUT_LINE('New robot with model ' || MODEL_NAME || ' added with ID ' || v_robot_id || ' to factory ' || v_factory_id);

EXCEPTION
    WHEN OTHERS THEN
        -- Gestion des erreurs générales
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
        ROLLBACK;
END;
/

    -- Question 3 : SEED_DATA_SPARE_PARTS
CREATE OR REPLACE PROCEDURE SEED_DATA_SPARE_PARTS(NB_SPARE_PARTS NUMBER) AS
    v_color VARCHAR2(10);
    v_name VARCHAR2(100);
    v_colors SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('red', 'gray', 'black', 'blue', 'silver');
BEGIN
    FOR i IN 1..NB_SPARE_PARTS LOOP
        -- Sélection d'une couleur aléatoire parmi les options disponibles
        v_color := v_colors(TRUNC(DBMS_RANDOM.VALUE(1, 6)));
        -- Génération du nom de la pièce détachée
        v_name := 'SparePart_' || i;
        -- Insertion de la pièce détachée dans la table SPARE_PARTS
        INSERT INTO SPARE_PARTS (color, name) VALUES (v_color, v_name);
    END LOOP;

    -- Message de confirmation
    DBMS_OUTPUT.PUT_LINE(NB_SPARE_PARTS || ' spare parts inserted.');
END;
/
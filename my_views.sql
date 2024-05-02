-- Question 1 ALL_WORKERS
CREATE OR REPLACE VIEW ALL_WORKERS AS
SELECT 
    first_name, 
    last_name, 
    age,
    first_day AS start_date
FROM 
    WORKERS_FACTORY_1
WHERE 
    last_day IS NULL
UNION ALL
SELECT 
    first_name, 
    last_name, 
    NULL AS age,
    start_date
FROM 
    WORKERS_FACTORY_2
WHERE 
    end_date IS NULL
ORDER BY 
    start_date DESC;

-- Question 2 ALL_WORKERS_ELAPSED

CREATE OR REPLACE VIEW ALL_WORKERS_ELAPSED AS
SELECT
first_name,
last_name,
age,
start_date,
TRUNC(CURRENT_DATE - start_date) AS days_elapsed
FROM
ALL_WORKERS;

-- Question 3 BEST_SUPPLIERS

CREATE OR REPLACE VIEW BEST_SUPPLIERS AS
SELECT 
    s.supplier_id,
    s.name AS supplier_name,
    SUM(quantity) AS total_pieces_delivered
FROM 
    SUPPLIERS_BRING_TO_FACTORY_1 sf1
JOIN 
    SUPPLIERS s ON sf1.supplier_id = s.supplier_id
GROUP BY 
    s.supplier_id, s.name
HAVING 
    SUM(quantity) > 1000
UNION ALL
SELECT 
    s.supplier_id,
    s.name AS supplier_name,
    SUM(quantity) AS total_pieces_delivered
FROM 
    SUPPLIERS_BRING_TO_FACTORY_2 sf2
JOIN 
    SUPPLIERS s ON sf2.supplier_id = s.supplier_id
GROUP BY 
    s.supplier_id, s.name
HAVING 
    SUM(quantity) > 1000
ORDER BY 
    total_pieces_delivered DESC;

-- Question 4 ROBOTS_FACTORIES

CREATE OR REPLACE VIEW ROBOTS_FACTORIES AS
SELECT 
    r.id AS robot_id,
    r.model AS robot_model,
    f.main_location AS factory_location
FROM 
    ROBOTS r
JOIN                                                                               
    ROBOTS_FROM_FACTORY rf ON r.id = rf.robot_id
JOIN 
    FACTORIES f ON rf.factory_id = f.id;
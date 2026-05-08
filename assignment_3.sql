--hacksaw ridge, Fury, platform
--TASK 1
INSERT INTO film (title, rental_rate, rental_duration, language_id, last_update)

SELECT 'Hacksaw Ridge', 4.99, 7,
    (SELECT language_id FROM language WHERE name = 'English'),
    CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'Hacksaw Ridge')

UNION ALL

SELECT 'Fury', 9.99, 14,
    (SELECT language_id FROM language WHERE name = 'English'),
    CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'Fury')

UNION ALL

SELECT 'Platform', 19.99, 21,
    (SELECT language_id FROM language WHERE name = 'English'),
    CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'Platform');


SELECT film_id, title, rental_rate FROM film WHERE title IN ('Hacksaw Ridge', 'Fury', 'Platform');

--TASK 2
INSERT INTO actor (first_name, last_name, last_update)
SELECT first_name, last_name, CURRENT_DATE
FROM (VALUES
    ('Andrew',  'Garfield'),      -- Hacksaw Ridge
    ('Sam',     'Worthington'),   -- Hacksaw Ridge
    ('Brad',    'Pitt'),          -- Fury
    ('Logan',   'Lerman'),        -- Fury
    ('Ivan',    'Massague'),      -- Platform
    ('Zorion',  'Eguileor')       -- Platform
) AS v(first_name, last_name)
WHERE NOT EXISTS (
    SELECT 1 FROM actor a
    WHERE a.first_name = v.first_name
      AND a.last_name  = v.last_name
);

--TASK 3

INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id,
       (SELECT store_id FROM store LIMIT 1),
       CURRENT_DATE
FROM film f
WHERE f.title IN ('Hacksaw Ridge', 'Fury', 'Platform')
  AND NOT EXISTS (
      SELECT 1 FROM inventory i
      WHERE i.film_id  = f.film_id
        AND i.store_id = (SELECT store_id FROM store LIMIT 1)
  );

SELECT i.inventory_id,
       f.title,
       i.store_id,
       i.last_update
FROM inventory i
JOIN film f ON i.film_id = f.film_id
WHERE f.title IN ('Hacksaw Ridge', 'Fury', 'Platform')
ORDER BY f.title;

--TASK 4

--Find someone with more than 43 rentals, records
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       COUNT(DISTINCT r.rental_id)  AS rental_count,
       COUNT(DISTINCT p.payment_id) AS payment_count
FROM customer c
JOIN rental  r ON c.customer_id = r.customer_id
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT r.rental_id)  >= 43
   AND COUNT(DISTINCT p.payment_id) >= 43
ORDER BY rental_count DESC
LIMIT 5;

UPDATE customer
SET first_name  = 'Practitioner',
    last_name   = 'Test',
    email       = 'test.practitioner@example.com',
    address_id  = (SELECT address_id FROM address LIMIT 1),
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE (first_name = 'Bayazet' AND last_name = 'Kazgali') or 
    (first_name = 'ELEANOR' AND last_name = 'HUNT')
);

UPDATE customer
SET first_name  = 'Bayazet',
    last_name   = 'Kazgali',
    email       = 'bayazet.kazgali@example.com',
    address_id  = (SELECT address_id FROM address LIMIT 1),
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Eleanor' AND last_name = 'Hunt'
);

-- Verify Task 4
SELECT customer_id, first_name, last_name, email, address_id, last_update
FROM customer
WHERE first_name = 'Bayazet' AND last_name = 'Kazgali';

--TASK 5


-- Check first — how many rows will be affected?
SELECT COUNT(*) AS payments_to_delete
FROM payment
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Bayazet' AND last_name = 'Kazgali'
);

SELECT COUNT(*) AS rentals_to_delete
FROM rental
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Bayazet' AND last_name = 'Kazgali'
);

DELETE FROM payment
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Bayazet' AND last_name = 'Kazgali'
);

DELETE FROM rental
WHERE customer_id = (
    SELECT customer_id FROM customer
    WHERE first_name = 'Bayazet' AND last_name = 'Kazgali'
);

--TASK 6

-- Hacksaw Ridge rental (7-day)
INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, return_date, last_update)
SELECT
    '2017-01-10',
    (SELECT i.inventory_id FROM inventory i
     JOIN film f ON i.film_id = f.film_id
     WHERE f.title = 'Hacksaw Ridge'
       AND i.store_id = (SELECT store_id FROM store LIMIT 1)
     LIMIT 1),
    (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali'),
    (SELECT staff_id FROM staff WHERE store_id = (SELECT store_id FROM store LIMIT 1) LIMIT 1),
    '2017-01-10'::DATE + 7 * INTERVAL '1 day',
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM rental
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali')
      AND rental_date = '2017-01-10'
)
RETURNING rental_id, rental_date;

-- Fury rental (14-day)
INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, return_date, last_update)
SELECT
    '2017-02-10',
    (SELECT i.inventory_id FROM inventory i
     JOIN film f ON i.film_id = f.film_id
     WHERE f.title = 'Fury'
       AND i.store_id = (SELECT store_id FROM store LIMIT 1)
     LIMIT 1),
    (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali'),
    (SELECT staff_id FROM staff WHERE store_id = (SELECT store_id FROM store LIMIT 1) LIMIT 1),
    '2017-02-10'::DATE + 14 * INTERVAL '1 day',
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM rental
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali')
      AND rental_date = '2017-02-10'
);

-- Platform rental (21-day)
INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, return_date, last_update)
SELECT
    '2017-03-10',
    (SELECT i.inventory_id FROM inventory i
     JOIN film f ON i.film_id = f.film_id
     WHERE f.title = 'Platform'
       AND i.store_id = (SELECT store_id FROM store LIMIT 1)
     LIMIT 1),
    (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali'),
    (SELECT staff_id FROM staff WHERE store_id = (SELECT store_id FROM store LIMIT 1) LIMIT 1),
    '2017-03-10'::DATE + 21 * INTERVAL '1 day',
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM rental
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali')
      AND rental_date = '2017-03-10'
);

-- Payment for Hacksaw Ridge (4.99)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali'),
    (SELECT staff_id FROM staff WHERE store_id = (SELECT store_id FROM store LIMIT 1) LIMIT 1),
    (SELECT r.rental_id FROM rental r JOIN customer c ON r.customer_id = c.customer_id
     WHERE c.first_name = 'Bayazet' AND c.last_name = 'Kazgali'
       AND r.rental_date = '2017-01-10' LIMIT 1),
    4.99, '2017-01-10 12:00:00'
WHERE NOT EXISTS (
    SELECT 1 FROM payment
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali')
      AND payment_date = '2017-01-10 12:00:00'
);

-- Payment for Fury (9.99)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali'),
    (SELECT staff_id FROM staff WHERE store_id = (SELECT store_id FROM store LIMIT 1) LIMIT 1),
    (SELECT r.rental_id FROM rental r JOIN customer c ON r.customer_id = c.customer_id
     WHERE c.first_name = 'Bayazet' AND c.last_name = 'Kazgali'
       AND r.rental_date = '2017-02-10' LIMIT 1),
    9.99, '2017-02-10 12:00:00'
WHERE NOT EXISTS (
    SELECT 1 FROM payment
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali')
      AND payment_date = '2017-02-10 12:00:00'
);

-- Payment for Platform (19.99)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali'),
    (SELECT staff_id FROM staff WHERE store_id = (SELECT store_id FROM store LIMIT 1) LIMIT 1),
    (SELECT r.rental_id FROM rental r JOIN customer c ON r.customer_id = c.customer_id
     WHERE c.first_name = 'Bayazet' AND c.last_name = 'Kazgali'
       AND r.rental_date = '2017-03-10' LIMIT 1),
    19.99, '2017-03-10 12:00:00'
WHERE NOT EXISTS (
    SELECT 1 FROM payment
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali')
      AND payment_date = '2017-03-10 12:00:00'
);

-- Verify Task 6 — rentals and payments side by side
SELECT r.rental_id, f.title, r.rental_date, r.return_date,
       p.amount, p.payment_date
FROM rental r
JOIN customer c  ON r.customer_id  = c.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f      ON i.film_id      = f.film_id
JOIN payment p   ON r.rental_id    = p.rental_id
WHERE c.first_name = 'Bayazet' AND c.last_name = 'Kazgali'
ORDER BY r.rental_date;


--TASK 2
INSERT INTO actor (first_name, last_name, last_update)
VALUES (('Andrew','Richard'), ('Garfield','Pyros'),
CURRENT_DATE)
ON CONFLICT DO nothing;

select * from actor where first_name = 'Andrew';

SELECT a.first_name, a.last_name, f.title
FROM film_actor fa
JOIN actor a ON fa.actor_id = a.actor_id
JOIN film  f ON fa.film_id  = f.film_id
WHERE f.title = 'Hacksaw Ridge';

-- Insert actors — WHERE NOT EXISTS because no UNIQUE on (first_name, last_name)
INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Keanu', 'Reeves', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Keanu' AND last_name = 'Reeves'
);

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Laurence', 'Fishburne', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Laurence' AND last_name = 'Fishburne'
);

-- Link actors to film — ON CONFLICT DO NOTHING because film_actor has composite PK
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Keanu'    AND last_name = 'Reeves'),
    (SELECT film_id  FROM film  WHERE title = 'The Matrix'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = 'Laurence' AND last_name = 'Fishburne'),
    (SELECT film_id  FROM film  WHERE title = 'The Matrix'),
    CURRENT_DATE
ON CONFLICT DO NOTHING;
SELECT a.first_name, a.last_name, f.title
FROM film_actor fa
JOIN actor a ON fa.actor_id = a.actor_id
JOIN film  f ON fa.film_id  = f.film_id
WHERE f.title = 'The Matrix';


INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, return_date, last_update)
SELECT
    '2017-01-10',
    (
        SELECT i.inventory_id FROM inventory i
        JOIN film f ON i.film_id = f.film_id
        WHERE f.title = 'The Matrix'
          AND i.store_id = (SELECT store_id FROM store LIMIT 1)
        LIMIT 1
    ),
    (SELECT customer_id FROM customer WHERE first_name = 'Practitioner' AND last_name = 'Test'),
    (SELECT staff_id FROM staff WHERE store_id = (SELECT store_id FROM store LIMIT 1) LIMIT 1),
    '2017-01-10'::DATE + 7 * INTERVAL '1 day',
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM rental
    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Practitioner' AND last_name = 'Test')
      AND inventory_id = (
          SELECT i.inventory_id FROM inventory i
          JOIN film f ON i.film_id = f.film_id
          WHERE f.title = 'The Matrix'
            AND i.store_id = (SELECT store_id FROM store LIMIT 1)
          LIMIT 1
      )
      AND rental_date = '2017-01-10'
)
RETURNING rental_id, rental_date;

--STEP 5
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
select
    (SELECT customer_id FROM customer WHERE first_name = 'Practitioner' AND last_name = 'Test'),
    (SELECT staff_id FROM staff WHERE store_id = (SELECT store_id FROM store LIMIT 1) LIMIT 1),
    (
    	SELECT r.rental_id FROM rental r 
    	join customer c on r.customer_id = c.customer_id
        WHERE c.first_name = 'Practitioner' AND c.last_name = 'Test' AND r.rental_date = '2017-01-10'
        LIMIT 1

    ),
    4.99,
    '2017-01-10 12:00:00';
--WHERE NOT EXISTS (
--    SELECT 1 FROM payment
--    WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Practitioner' AND last_name = 'Test')    
--    and payment_date = '2017-01-10 12:00:00';
    
SELECT * FROM customer 
WHERE first_name = 'Practitioner' AND last_name = 'Test';


    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    











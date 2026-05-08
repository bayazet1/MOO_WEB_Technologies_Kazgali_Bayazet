-- ============================================================
-- Assignment 3: dvdrental Data Manipulation
-- Student: Bayazet Kazgali
-- Films: Hacksaw Ridge, Fury, Platform
-- ============================================================

BEGIN;

-- ============================================================
-- TASK 1: Insert Favorite Films
-- Using UNION ALL with individual WHERE NOT EXISTS per film
-- because film has no UNIQUE constraint on title.
-- language_id resolved dynamically — no hardcoded IDs.
-- ============================================================

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

-- Verify Task 1
SELECT film_id, title, rental_rate, rental_duration, last_update
FROM film
WHERE title IN ('Hacksaw Ridge', 'Fury', 'Platform')
ORDER BY title;


-- ============================================================
-- TASK 2: Insert Actors and Link to Films
-- Using WHERE NOT EXISTS for actor inserts because the actor
-- table has no UNIQUE constraint on (first_name, last_name).
-- Using ON CONFLICT DO NOTHING for film_actor because it has
-- a composite primary key (actor_id, film_id) which acts as
-- a natural unique constraint — perfect for ON CONFLICT.
-- ============================================================

INSERT INTO actor (first_name, last_name, last_update)
SELECT first_name, last_name, CURRENT_DATE
FROM (VALUES
    ('Andrew',  'Garfield'),
    ('Sam',     'Worthington'),
    ('Brad',    'Pitt'),
    ('Logan',   'Lerman'),
    ('Ivan',    'Massague'),
    ('Zorion',  'Eguileor')
) AS v(first_name, last_name)
WHERE NOT EXISTS (
    SELECT 1 FROM actor a
    WHERE a.first_name = v.first_name
      AND a.last_name  = v.last_name
);

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM (VALUES
    ('Andrew',  'Garfield',    'Hacksaw Ridge'),
    ('Sam',     'Worthington', 'Hacksaw Ridge'),
    ('Brad',    'Pitt',        'Fury'),
    ('Logan',   'Lerman',      'Fury'),
    ('Ivan',    'Massague',    'Platform'),
    ('Zorion',  'Eguileor',    'Platform')
) AS v(first_name, last_name, title)
JOIN actor a ON a.first_name = v.first_name AND a.last_name = v.last_name
JOIN film  f ON f.title = v.title
ON CONFLICT DO NOTHING;

-- Verify Task 2
SELECT a.first_name, a.last_name, f.title
FROM film_actor fa
JOIN actor a ON fa.actor_id = a.actor_id
JOIN film  f ON fa.film_id  = f.film_id
WHERE f.title IN ('Hacksaw Ridge', 'Fury', 'Platform')
ORDER BY f.title, a.last_name;


-- ============================================================
-- TASK 3: Add Films to Inventory
-- film_id resolved dynamically by title, store_id resolved
-- dynamically via subquery — no hardcoded IDs.
-- WHERE NOT EXISTS prevents duplicate inventory rows on re-run
-- since inventory has no unique constraint on (film_id, store_id).
-- ============================================================

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

-- Verify Task 3
SELECT i.inventory_id, f.title, i.store_id, i.last_update
FROM inventory i
JOIN film f ON i.film_id = f.film_id
WHERE f.title IN ('Hacksaw Ridge', 'Fury', 'Platform')
ORDER BY f.title;


-- ============================================================
-- TASK 4: Become a Customer
-- Found Eleanor Hunt via the warm-up query (46 rentals, 46
-- payments). Updating by original name makes this naturally
-- idempotent — on re-run the name no longer matches so the
-- UPDATE affects 0 rows without error.
-- address_id resolved dynamically — address table not modified.
-- ============================================================

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


-- ============================================================
-- TASK 5: Clean Up Prior Records
-- payment deleted before rental because payment has a FK
-- dependency on rental — reversing the order would cause a
-- FK violation error.
-- SELECT before DELETE confirms affected rows (discipline check).
-- On re-run both DELETEs affect 0 rows — naturally idempotent.
-- ============================================================

-- Preview before deleting
SELECT COUNT(*) AS payments_to_delete FROM payment
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali');

SELECT COUNT(*) AS rentals_to_delete FROM rental
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali');

DELETE FROM payment
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali');

DELETE FROM rental
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali');

-- Verify Task 5 — both should return 0
SELECT COUNT(*) AS remaining_payments FROM payment
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali');

SELECT COUNT(*) AS remaining_rentals FROM rental
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Bayazet' AND last_name = 'Kazgali');


-- ============================================================
-- TASK 6: Rent Films and Pay
-- inventory_id resolved by film title + store — no hardcoded IDs.
-- customer_id and staff_id resolved dynamically via subquery.
-- return_date = rental_date + rental_duration per film.
-- Dates spread across 2017 H1 to match the payment table's
-- existing partition range (2017-01-01 to 2017-07-01).
-- WHERE NOT EXISTS prevents duplicate rows on re-run.
-- RETURNING used on first rental INSERT as required by grading.
-- ============================================================

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

COMMIT;
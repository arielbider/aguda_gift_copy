-- Request 57. A student with several campuses picks the one to collect the gift at.

-- The campus the student picked, one of `campuses`. Null until they pick, and for a student
-- with one campus.
ALTER TABLE students ADD COLUMN IF NOT EXISTS chosen_campus text;

-- Where the student collects: the picked campus, or else the first. The desk of this
-- campus serves the student.
ALTER TABLE students ADD COLUMN IF NOT EXISTS pickup_campus text
  GENERATED ALWAYS AS (coalesce(chosen_campus, campuses[1])) STORED;

-- The stock a selection takes from: the עין כרם sub-campus when the student collects at
-- עין כרם (every sub-campus belongs to עין כרם, src/campus.ts), else the pickup campus.
ALTER TABLE students ALTER COLUMN stock_campus SET EXPRESSION AS (
  CASE WHEN sub_campus IS NOT NULL AND coalesce(chosen_campus, campuses[1]) = 'עין כרם'
       THEN sub_campus ELSE coalesce(chosen_campus, campuses[1]) END);

-- The report a ceo downloads: every student with several campuses who selected a gift,
-- with the campuses, where they collect, the gift, and when they received it.
CREATE OR REPLACE VIEW multi_campus_gifts AS
  SELECT s.national_id, s.first_name, s.last_name,
         array_to_string(s.campuses, ' + ') AS campuses,
         s.pickup_campus, s.stock_campus, g.name AS gift, s.gift_taken_at AS received_at
    FROM students s JOIN gifts g ON g.id = s.gift_id
   WHERE cardinality(s.campuses) > 1;

-- Queries.
-- 1. Show the average salary for all employees per year.

USE employees;
SELECT YEAR(from_date) as year_sal, FORMAT(AVG(salary),2) as avg_sal FROM salaries
GROUP BY YEAR(from_date);

--  2.Show the average salary per employee for each department. You should show only current slaaries and current employees.

SELECT dept_name, FORMAT(AVG(salary),2) as avg_sal FROM salaries
	INNER JOIN dept_emp USING(emp_no)
    INNER JOIN departments USING(dept_no)
		WHERE now() BETWEEN dept_emp.from_date and dept_emp.to_date
        AND now() BETWEEN salaries.from_date and salaries.to_date
		GROUP BY dept_name;

--  3. Show the average salary per year for each department. 
--  For the average salary for department X in year Y you should take the average amount of salaries per year Y.

SELECT dept_name, YEAR(s.from_date) as year_sal, FORMAT(AVG(salary),2) as avg_sal FROM salaries as s
	INNER JOIN dept_emp as d ON d.emp_no = s.emp_no AND (s.from_date BETWEEN d.from_date AND d.to_date)
		INNER JOIN departments USING(dept_no)
		GROUP BY dept_name, YEAR(s.from_date);
        
--  4.Show the biggest department per yeach year and its average salary.

SELECT year_1, query_2.dept_no, query_2.count_emp, query_3.avg_sal 
FROM(
	SELECT year_1, dept_no, count_emp, 
	DENSE_RANK() OVER(PARTITION BY year_1 ORDER BY year_1, count_emp DESC) as max_sal 
    FROM(SELECT YEAR(from_date) as year_1, dept_no, COUNT(emp_no) as count_emp FROM dept_emp
GROUP BY YEAR(from_date), dept_no
ORDER BY year_1, count_emp DESC) as query_1) as query_2
INNER JOIN (SELECT YEAR(s.from_date) as year_2, dept_no, AVG(s.salary) as avg_sal FROM salaries as s
INNER JOIN dept_emp as d ON d.emp_no = s.emp_no AND (s.from_date BETWEEN d.from_date AND d.to_date)
GROUP BY YEAR(from_date), dept_no) as query_3 ON year_1 = query_3.year_2 AND query_2.dept_no = query_3.dept_no
WHERE max_sal = 1;

    
--  5.Show the detailed information about the dept head who is currently managing their department.

SELECT * FROM employees
	INNER JOIN (SELECT emp_no, TIMESTAMPDIFF(DAY, from_date, now()) as date_diff FROM dept_manager
	WHERE now() BETWEEN from_date AND to_date
		ORDER BY date_diff DESC
        LIMIT 1) as t1 USING(emp_no)
			INNER JOIN dept_manager USING(emp_no)
            INNER JOIN salaries USING(emp_no)
			INNER JOIN departments USING(dept_no)
				WHERE now() between salaries.from_date AND salaries.to_date;

--  6. Show the TOP-10 current employees with the biggest difference between their salary and current average salary in their department.

SELECT dept_no, emp_no, rank_sal FROM(
SELECT dept_no, emp_no, sal_avg_diff, DENSE_RANK() OVER(PARTITION BY dept_no ORDER BY sal_avg_diff DESC) as rank_sal
FROM(SELECT dept_no, emp_no, ABS(salary - (avg_sal)) as sal_avg_diff FROM dept_emp
	INNER JOIN salaries USING(emp_no)
	INNER JOIN (SELECT dept_no, AVG(salary) as avg_sal FROM salaries
	INNER JOIN dept_emp USING(emp_no)
		WHERE now() BETWEEN dept_emp.from_date and dept_emp.to_date
        AND now() BETWEEN salaries.from_date and salaries.to_date
		GROUP BY dept_no) as t1 USING(dept_no)
			WHERE now() BETWEEN salaries.from_date AND salaries.to_date
				ORDER BY dept_no ASC, sal_avg_diff DESC) as query_1) as query_2
					WHERE rank_sal BETWEEN 1 AND 10;

--  7. One department can afford only $500 000 for salaries.
--  Administration decided that employees with the lowest salaried will get paid off in the first place.
--  Show the list of all employees who will get paid off in time. 

SELECT dept_no, emp_no, mon_sal, sum_sal FROM(SELECT dept_no, emp_no, mon_sal, 
SUM(mon_sal) OVER(PARTITION BY dept_no ORDER BY mon_sal) as sum_sal 
FROM (SELECT dept_no, emp_no, salary/12 as mon_sal FROM salaries
INNER JOIN dept_emp USING(emp_no)
WHERE now() BETWEEN salaries.from_date AND salaries.to_date
ORDER BY dept_no, mon_sal) as query_1) as quesry_2
	WHERE sum_sal < 500000;

--  Database design:
--  1.Create a databse for managing courses
--  It should contain:
--  a.students: student_no, teacher_no, course_no, student_name, email, birth_date.
--  b.teachers: teacher_no, teacher_name, phone_noc.
--  courses: course_no, course_name, start_date, end_date.
--  ● Separate by years, table students by birth_date using range function.
--  ● In table students create a primary key that includes two cells: student_no and birth_date.


DROP DATABASE IF EXISTS course_manager;
CREATE DATABASE course_manager;

USE course_manager;

CREATE TABLE IF NOT EXISTS students(
student_no INT NOT NULL,
teacher_no INT NOT NULL,
course_no INT NOT NULL,
student_name VARCHAR(30),
email VARCHAR(30),
birth_date DATE,
PRIMARY KEY(student_no, birth_date))
PARTITION BY RANGE (YEAR(birth_date)) (
PARTITION y0 VALUES LESS THAN (1986),
    PARTITION y1 VALUES LESS THAN (1987),
    PARTITION y2 VALUES LESS THAN (1988),
    PARTITION y3 VALUES LESS THAN (1989),
    PARTITION y4 VALUES LESS THAN (1990),
    PARTITION y5 VALUES LESS THAN (1991),
    PARTITION y6 VALUES LESS THAN (1992),
    PARTITION y7 VALUES LESS THAN (1993),
    PARTITION y8 VALUES LESS THAN (1994),
    PARTITION y9 VALUES LESS THAN (1995),
    PARTITION y10 VALUES LESS THAN (1996),
    PARTITION y11 VALUES LESS THAN (1998),
    PARTITION y12 VALUES LESS THAN (1999),
    PARTITION y13 VALUES LESS THAN (2000),
    PARTITION y14 VALUES LESS THAN (2001),
    PARTITION y15 VALUES LESS THAN MAXVALUE);

CREATE TABLE IF NOT EXISTS teachers(
teacher_no INT NOT NULL,
teacher_name VARCHAR(30),
phone_no INT);


CREATE TABLE IF NOT EXISTS courses(
course_no INT NOT NULL,
course_name VARCHAR(30),
start_date DATE DEFAULT NULL,
end_date DATE DEFAULT NULL);

--  ● Create index on students.email.

CREATE INDEX un_email ON students(email);

--  ● Create a unique index on teachers.phone_no.

CREATE UNIQUE INDEX un_phone_no ON teachers(phone_no);

--  2. Insert test data (7-10 rows) in our three tables.

INSERT INTO students(student_no, teacher_no, course_no, student_name, email, birth_date)
VALUES(1, 1, 1, 'Taras', 'tarastest@mail.ua','2000-05-25'), (2, 3, 2, 'Vova', 'vovatest@mail.ua', '1992-3-29'), (3, 2, 3, 'Anna', 'anntest@mail.ua', '1999-02-12');

INSERT INTO teachers(teacher_no, teacher_name, phone_no)
VALUES(1, 'Vlad', '0956789876'), (2, 'Yevhen', '0664567112'), (3, 'Denis', '0934567622');

INSERT INTO courses(course_no, course_name, start_date, end_date)
VALUES (1, 'BI-online', '2022-03-12', '2022-09-12'), (2, 'Frontend-online', '2022-02-22','2022-10-12'), (3, 'Python-online', '2022-01-05', '2023-01-05');

--  3. Show data for any year from students table and comment it with the plan of executing the query 
-- which shows that this query will be executed with mentioned in task 1 separation.

EXPLAIN SELECT * FROM students
WHERE birth_date = '1990-03-01';

-- '1', 'SIMPLE', 'students', 'y5', 'ALL', NULL, NULL, NULL, NULL, '1', '100.00', 'Using where'

--  4. Represnt the teachers data using their phone number and comment it with the plan of executing the query 
-- which shows that the selection will be done with idex type but not the ALL method.

EXPLAIN SELECT * FROM teachers
WHERE phone_no = 0934567622;

-- '1', 'SIMPLE', 'teachers', NULL, 'const', 'un_phone_no', 'un_phone_no', '5', 'const', '1', '100.00', NULL

--  Then the index teachers.phone_no should become invisible and you should comment it with the plan of executing the query, 
--  where the result should be the ALL method. After the experiment make the index visible. 

ALTER TABLE teachers ALTER INDEX un_phone_no INVISIBLE;

EXPLAIN SELECT * FROM teachers
WHERE phone_no = 0934567622;

-- '1', 'SIMPLE', 'teachers', NULL, 'ALL', NULL, NULL, NULL, NULL, '2', '50.00', 'Using where'

ALTER TABLE teachers ALTER INDEX un_phone_no VISIBLE;

--  5. Insert three identical data rows in the students table.

INSERT INTO students(student_no, teacher_no, course_no, student_name, email, birth_date)
VALUES(5, 1, 1, 'John', 'johntest@mail.ua','1989-03-03'), 
(6, 1, 1, 'John', 'johntest@mail.ua','1990-03-03'), 
(7, 1, 1, 'John', 'johntest@mail.ua','1991-03-03');


--  6. Write a query that shows these duplicates.

SELECT list1.student_name, 
   list1.teacher_no, 
   list1.email, 
   list1.course_no
FROM students as list1
   INNER JOIN (SELECT email
               FROM students
               GROUP BY email
               HAVING COUNT(email) > 1) as dup
           ON list1.email = dup.email;
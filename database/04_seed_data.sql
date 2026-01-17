-- Prison Management Database Seed Data
-- Realistic sample data for demonstration

-- Wrap in transaction to ensure triggers are always re-enabled
BEGIN;

-- Temporarily disable triggers for bulk insert
ALTER TABLE prisoners DISABLE TRIGGER trg_check_cell_capacity;
ALTER TABLE visits DISABLE TRIGGER trg_check_visitor_blacklist;

-- ============================================
-- ENUMERATION DATA
-- ============================================

-- Crime types (10 types)
INSERT INTO crime_types (name, description, severity_level) VALUES
('Theft', 'Property theft including burglary and robbery', 2),
('Assault', 'Physical assault causing bodily harm', 3),
('Fraud', 'Financial fraud, forgery, and embezzlement', 2),
('Drug Possession', 'Possession of controlled substances', 2),
('Drug Trafficking', 'Distribution and sale of controlled substances', 4),
('Murder', 'Unlawful killing of another person', 5),
('Manslaughter', 'Unintentional killing due to negligence', 4),
('Armed Robbery', 'Robbery with use of weapons', 4),
('Sexual Assault', 'Sexual crimes and offenses', 5),
('Organized Crime', 'Participation in criminal organization', 4);

-- Staff roles (5 roles)
INSERT INTO staff_roles (name, description, access_level) VALUES
('Guard', 'Security officer responsible for inmate supervision', 3),
('Senior Guard', 'Experienced guard with supervisory duties', 5),
('Medical Staff', 'Doctors, nurses, and medical personnel', 4),
('Administrative', 'Office and administrative personnel', 2),
('Warden', 'Prison management and leadership', 10);

-- Program types (4 types)
INSERT INTO program_types (name, description) VALUES
('Education', 'Academic education and GED programs'),
('Vocational', 'Job skills and trade training'),
('Therapy', 'Psychological and behavioral therapy'),
('Rehabilitation', 'Drug rehabilitation and counseling');

-- ============================================
-- CELL BLOCKS (3 blocks)
-- ============================================

INSERT INTO cell_blocks (name, security_level, capacity, floor_count, description) VALUES
('Block A - East Wing', 'minimum', 50, 2, 'Low-security inmates, good behavior'),
('Block B - West Wing', 'medium', 80, 3, 'Standard security inmates'),
('Block C - North Wing', 'maximum', 40, 2, 'High-security and violent offenders');

-- ============================================
-- CELLS (20 cells)
-- ============================================

-- Block A cells (7 cells)
INSERT INTO cells (cell_code, cell_block_id, floor_number, capacity, cell_type, has_window) VALUES
('A-101', 1, 1, 2, 'standard', true),
('A-102', 1, 1, 2, 'standard', true),
('A-103', 1, 1, 2, 'standard', true),
('A-104', 1, 1, 1, 'protective', true),
('A-201', 1, 2, 2, 'standard', true),
('A-202', 1, 2, 2, 'standard', true),
('A-203', 1, 2, 2, 'standard', true);

-- Block B cells (8 cells)
INSERT INTO cells (cell_code, cell_block_id, floor_number, capacity, cell_type, has_window) VALUES
('B-101', 2, 1, 2, 'standard', true),
('B-102', 2, 1, 2, 'standard', true),
('B-103', 2, 1, 1, 'medical', true),
('B-201', 2, 2, 2, 'standard', true),
('B-202', 2, 2, 2, 'standard', false),
('B-203', 2, 2, 2, 'standard', true),
('B-301', 2, 3, 2, 'standard', true),
('B-302', 2, 3, 1, 'solitary', false);

-- Block C cells (5 cells)
INSERT INTO cells (cell_code, cell_block_id, floor_number, capacity, cell_type, has_window) VALUES
('C-101', 3, 1, 1, 'solitary', false),
('C-102', 3, 1, 1, 'solitary', false),
('C-103', 3, 1, 2, 'standard', false),
('C-201', 3, 2, 1, 'solitary', false),
('C-202', 3, 2, 2, 'standard', false);

-- ============================================
-- STAFF (15 members)
-- ============================================

INSERT INTO staff (employee_id, first_name, last_name, role_id, date_of_birth, gender, hire_date, email, phone, assigned_block_id, salary, is_active) VALUES
('EMP001', 'Tomasz', 'Kowalski', 5, '1970-03-15', 'male', '2005-01-10', 'tkowalski@prison.gov.pl', '+48501234567', NULL, 15000.00, true),
('EMP002', 'Anna', 'Nowak', 2, '1982-07-22', 'female', '2010-06-01', 'anowak@prison.gov.pl', '+48502345678', 1, 7500.00, true),
('EMP003', 'Piotr', 'Wisniewski', 1, '1988-11-30', 'male', '2015-03-15', 'pwisniewski@prison.gov.pl', '+48503456789', 1, 5500.00, true),
('EMP004', 'Maria', 'Wojcik', 3, '1975-05-08', 'female', '2008-09-01', 'mwojcik@prison.gov.pl', '+48504567890', NULL, 9000.00, true),
('EMP005', 'Jan', 'Kaminski', 1, '1990-02-14', 'male', '2018-01-20', 'jkaminski@prison.gov.pl', '+48505678901', 2, 5200.00, true),
('EMP006', 'Ewa', 'Lewandowska', 4, '1985-09-25', 'female', '2012-04-10', 'elewandowska@prison.gov.pl', '+48506789012', NULL, 4500.00, true),
('EMP007', 'Krzysztof', 'Zielinski', 2, '1978-12-03', 'male', '2007-08-15', 'kzielinski@prison.gov.pl', '+48507890123', 2, 7800.00, true),
('EMP008', 'Magdalena', 'Szymanska', 1, '1992-06-17', 'female', '2019-05-01', 'mszymanska@prison.gov.pl', '+48508901234', 3, 5000.00, true),
('EMP009', 'Andrzej', 'Wozniak', 1, '1986-04-28', 'male', '2014-11-11', 'awozniak@prison.gov.pl', '+48509012345', 2, 5800.00, true),
('EMP010', 'Katarzyna', 'Dabrowski', 3, '1980-01-19', 'female', '2009-02-28', 'kdabrowski@prison.gov.pl', '+48510123456', NULL, 8500.00, true),
('EMP011', 'Marek', 'Kozlowski', 2, '1976-08-11', 'male', '2006-07-01', 'mkozlowski@prison.gov.pl', '+48511234567', 3, 8000.00, true),
('EMP012', 'Agnieszka', 'Jankowska', 4, '1989-10-05', 'female', '2016-09-15', 'ajankowska@prison.gov.pl', '+48512345678', NULL, 4200.00, true),
('EMP013', 'Robert', 'Mazur', 1, '1993-03-22', 'male', '2020-02-01', 'rmazur@prison.gov.pl', '+48513456789', 1, 4800.00, true),
('EMP014', 'Joanna', 'Krawczyk', 1, '1991-07-14', 'female', '2017-06-20', 'jkrawczyk@prison.gov.pl', '+48514567890', 3, 5300.00, true),
('EMP015', 'Pawel', 'Piotrowski', 1, '1987-12-08', 'male', '2013-10-01', 'ppiotrowski@prison.gov.pl', '+48515678901', 2, 5600.00, false);

-- ============================================
-- PRISONERS (50 prisoners)
-- ============================================

INSERT INTO prisoners (prisoner_number, first_name, last_name, date_of_birth, gender, nationality, cell_id, admission_date, status, blood_type, emergency_contact_name, emergency_contact_phone) VALUES
('P2020-0001', 'Adam', 'Kowalczyk', '1985-03-12', 'male', 'Polish', 1, '2020-01-15', 'incarcerated', 'A+', 'Maria Kowalczyk', '+48601234567'),
('P2020-0002', 'Bartosz', 'Nowakowski', '1978-07-28', 'male', 'Polish', 1, '2020-02-20', 'incarcerated', 'O+', 'Anna Nowakowska', '+48602345678'),
('P2020-0003', 'Cezary', 'Mazurek', '1990-11-05', 'male', 'Polish', 2, '2020-03-10', 'incarcerated', 'B+', 'Teresa Mazurek', '+48603456789'),
('P2020-0004', 'Damian', 'Kaczmarek', '1982-05-17', 'male', 'Polish', 2, '2020-04-05', 'incarcerated', 'AB-', 'Ewa Kaczmarek', '+48604567890'),
('P2020-0005', 'Emil', 'Grabowski', '1995-09-23', 'male', 'Polish', 3, '2020-05-12', 'incarcerated', 'O-', 'Jan Grabowski', '+48605678901'),
('P2020-0006', 'Filip', 'Pawlowski', '1988-01-30', 'male', 'Polish', 3, '2020-06-18', 'incarcerated', 'A-', 'Zofia Pawlowska', '+48606789012'),
('P2020-0007', 'Grzegorz', 'Michalski', '1975-12-08', 'male', 'Polish', 4, '2020-07-22', 'incarcerated', 'B-', 'Helena Michalska', '+48607890123'),
('P2020-0008', 'Henryk', 'Zajac', '1992-04-14', 'male', 'Polish', 5, '2020-08-30', 'incarcerated', 'A+', 'Krystyna Zajac', '+48608901234'),
('P2020-0009', 'Igor', 'Krol', '1986-08-02', 'male', 'Ukrainian', 5, '2020-09-15', 'incarcerated', 'O+', 'Olga Krol', '+380501234567'),
('P2020-0010', 'Jakub', 'Wrobel', '1979-06-25', 'male', 'Polish', 6, '2020-10-08', 'incarcerated', 'AB+', 'Barbara Wrobel', '+48610123456'),
('P2021-0011', 'Kamil', 'Dudek', '1993-02-11', 'male', 'Polish', 6, '2021-01-20', 'incarcerated', 'B+', 'Danuta Dudek', '+48611234567'),
('P2021-0012', 'Lukasz', 'Adamczyk', '1981-10-19', 'male', 'Polish', 7, '2021-02-14', 'incarcerated', 'A-', 'Malgorzata Adamczyk', '+48612345678'),
('P2021-0013', 'Maciej', 'Stepien', '1997-07-03', 'male', 'Polish', 7, '2021-03-28', 'incarcerated', 'O+', 'Jadwiga Stepien', '+48613456789'),
('P2021-0014', 'Norbert', 'Gorski', '1984-09-16', 'male', 'Polish', 8, '2021-04-11', 'incarcerated', 'A+', 'Elzbieta Gorska', '+48614567890'),
('P2021-0015', 'Oskar', 'Rutkowski', '1991-03-27', 'male', 'Polish', 8, '2021-05-06', 'incarcerated', 'B-', 'Irena Rutkowska', '+48615678901'),
('P2021-0016', 'Patryk', 'Sikora', '1976-11-22', 'male', 'Polish', 9, '2021-06-19', 'incarcerated', 'O-', 'Stanislawa Sikora', '+48616789012'),
('P2021-0017', 'Radoslaw', 'Ostrowski', '1989-05-08', 'male', 'Polish', 9, '2021-07-24', 'incarcerated', 'AB-', 'Grazyna Ostrowska', '+48617890123'),
('P2021-0018', 'Szymon', 'Baran', '1994-01-14', 'male', 'Polish', 10, '2021-08-15', 'incarcerated', 'A+', 'Halina Baran', '+48618901234'),
('P2021-0019', 'Tomasz', 'Duda', '1987-08-29', 'male', 'Polish', 11, '2021-09-03', 'incarcerated', 'B+', 'Renata Duda', '+48619012345'),
('P2021-0020', 'Wiktor', 'Szewczyk', '1980-04-06', 'male', 'Polish', 11, '2021-10-12', 'incarcerated', 'O+', 'Wanda Szewczyk', '+48620123456'),
('P2022-0021', 'Aleksander', 'Blaszczyk', '1996-12-01', 'male', 'Polish', 12, '2022-01-08', 'incarcerated', 'A-', 'Bozena Blaszczyk', '+48621234567'),
('P2022-0022', 'Bogdan', 'Mroz', '1983-06-18', 'male', 'Polish', 12, '2022-02-22', 'incarcerated', 'AB+', 'Cecylia Mroz', '+48622345678'),
('P2022-0023', 'Czeslaw', 'Sawicki', '1972-10-30', 'male', 'Polish', 13, '2022-03-15', 'incarcerated', 'B-', 'Dorota Sawicka', '+48623456789'),
('P2022-0024', 'Dominik', 'Chmielewski', '1998-02-25', 'male', 'Polish', 14, '2022-04-01', 'incarcerated', 'O+', 'Franciszka Chmielewska', '+48624567890'),
('P2022-0025', 'Edward', 'Borkowski', '1977-07-12', 'male', 'Polish', 15, '2022-05-20', 'incarcerated', 'A+', 'Genowefa Borkowska', '+48625678901'),
('P2022-0026', 'Franciszek', 'Pietrzak', '1990-03-08', 'male', 'Polish', 16, '2022-06-14', 'incarcerated', 'B+', 'Hanna Pietrzak', '+48626789012'),
('P2022-0027', 'Gustaw', 'Walczak', '1985-09-21', 'male', 'Polish', 17, '2022-07-28', 'incarcerated', 'O-', 'Iwona Walczak', '+48627890123'),
('P2022-0028', 'Hubert', 'Kubiak', '1992-01-04', 'male', 'Polish', 18, '2022-08-09', 'incarcerated', 'A-', 'Jolanta Kubiak', '+48628901234'),
('P2022-0029', 'Ireneusz', 'Kazmierczak', '1974-05-16', 'male', 'Polish', 19, '2022-09-17', 'incarcerated', 'AB-', 'Kazimiera Kazmierczak', '+48629012345'),
('P2022-0030', 'Janusz', 'Urbanski', '1988-11-28', 'male', 'Polish', 20, '2022-10-25', 'incarcerated', 'B+', 'Lidia Urbanska', '+48630123456'),
('P2023-0031', 'Konrad', 'Witkowski', '1995-04-09', 'male', 'Polish', 20, '2023-01-12', 'incarcerated', 'O+', 'Lucyna Witkowska', '+48631234567'),
('P2023-0032', 'Leon', 'Glowacki', '1981-08-22', 'male', 'Polish', 10, '2023-02-28', 'incarcerated', 'A+', 'Miroslawa Glowacka', '+48632345678'),
('P2023-0033', 'Marcel', 'Kucharski', '1999-12-14', 'male', 'Polish', 14, '2023-03-18', 'incarcerated', 'B-', 'Natalia Kucharska', '+48633456789'),
('P2023-0034', 'Nikodem', 'Wisniewski', '1986-06-30', 'male', 'Polish', 13, '2023-04-05', 'incarcerated', 'AB+', 'Oliwia Wisniewska', '+48634567890'),
('P2023-0035', 'Olgierd', 'Wieczorek', '1973-02-17', 'male', 'Polish', NULL, '2023-05-22', 'released', 'O-', 'Paulina Wieczorek', '+48635678901'),
('P2023-0036', 'Przemyslaw', 'Jaworski', '1991-10-03', 'male', 'Polish', 1, '2023-06-09', 'incarcerated', 'A-', 'Roksana Jaworska', '+48636789012'),
('P2023-0037', 'Rafal', 'Malinowski', '1984-04-26', 'male', 'Polish', 2, '2023-07-14', 'incarcerated', 'B+', 'Sabina Malinowska', '+48637890123'),
('P2023-0038', 'Sebastian', 'Sadowski', '1997-08-11', 'male', 'Polish', 3, '2023-08-21', 'incarcerated', 'O+', 'Teresa Sadowska', '+48638901234'),
('P2023-0039', 'Tadeusz', 'Bak', '1970-01-29', 'male', 'Polish', 4, '2023-09-03', 'incarcerated', 'A+', 'Urszula Bak', '+48639012345'),
('P2023-0040', 'Wojciech', 'Zawadzki', '1993-05-18', 'male', 'Polish', 5, '2023-10-17', 'incarcerated', 'AB-', 'Weronika Zawadzka', '+48640123456'),
('P2024-0041', 'Zbigniew', 'Jakubowski', '1982-09-07', 'male', 'Polish', 6, '2024-01-05', 'incarcerated', 'B-', 'Zuzanna Jakubowska', '+48641234567'),
('P2024-0042', 'Artur', 'Jasinski', '1996-03-24', 'male', 'Polish', 7, '2024-02-19', 'incarcerated', 'O+', 'Alicja Jasinska', '+48642345678'),
('P2024-0043', 'Blazej', 'Sobczak', '1979-07-15', 'male', 'Polish', 8, '2024-03-08', 'incarcerated', 'A+', 'Beata Sobczak', '+48643456789'),
('P2024-0044', 'Cyprian', 'Kaczor', '1994-11-02', 'male', 'Polish', 9, '2024-04-12', 'incarcerated', 'B+', 'Celina Kaczor', '+48644567890'),
('P2024-0045', 'Dorian', 'Czarnecki', '1987-02-08', 'male', 'Polish', 10, '2024-05-25', 'incarcerated', 'O-', 'Diana Czarnecka', '+48645678901'),
('P2024-0046', 'Eryk', 'Kolodziej', '1990-06-19', 'male', 'Polish', 11, '2024-06-14', 'incarcerated', 'A-', 'Emilia Kolodziej', '+48646789012'),
('P2024-0047', 'Fryderyk', 'Szczepanski', '1976-10-31', 'male', 'Polish', 12, '2024-07-22', 'incarcerated', 'AB+', 'Felicja Szczepanska', '+48647890123'),
('P2024-0048', 'Gabriel', 'Kopczynski', '1998-04-13', 'male', 'Polish', 13, '2024-08-30', 'incarcerated', 'B-', 'Gabriela Kopczynska', '+48648901234'),
('P2024-0049', 'Herbert', 'Marciniak', '1983-12-25', 'male', 'Polish', 17, '2024-09-15', 'incarcerated', 'O+', 'Helena Marciniak', '+48649012345'),
('P2024-0050', 'Ivan', 'Petrov', '1989-08-06', 'male', 'Bulgarian', 18, '2024-10-01', 'incarcerated', 'A+', 'Ivana Petrova', '+359888123456');

-- ============================================
-- SENTENCES (60 sentences - some prisoners have multiple)
-- ============================================

INSERT INTO sentences (prisoner_id, crime_type_id, sentence_start_date, sentence_years, sentence_months, is_life_sentence, parole_eligible, parole_date, court_name, case_number, judge_name) VALUES
(1, 1, '2020-01-15', 3, 0, false, true, '2022-01-15', 'Sad Rejonowy Warszawa', 'II K 123/20', 'Jan Kowalski'),
(2, 3, '2020-02-20', 5, 6, false, true, '2023-08-20', 'Sad Okregowy Krakow', 'III K 456/20', 'Anna Nowak'),
(3, 4, '2020-03-10', 2, 0, false, true, NULL, 'Sad Rejonowy Gdansk', 'I K 789/20', 'Piotr Wisniewski'),
(4, 2, '2020-04-05', 4, 0, false, true, '2023-04-05', 'Sad Rejonowy Poznan', 'II K 012/20', 'Maria Kowalska'),
(5, 5, '2020-05-12', 8, 0, false, true, '2025-05-12', 'Sad Okregowy Wroclaw', 'III K 345/20', 'Tomasz Nowicki'),
(6, 1, '2020-06-18', 2, 6, false, true, NULL, 'Sad Rejonowy Lodz', 'I K 678/20', 'Ewa Kaminska'),
(7, 6, '2020-07-22', 25, 0, false, false, NULL, 'Sad Okregowy Warszawa', 'IV K 901/20', 'Krzysztof Mazur'),
(8, 4, '2020-08-30', 1, 6, false, true, NULL, 'Sad Rejonowy Szczecin', 'II K 234/20', 'Joanna Lewandowska'),
(9, 8, '2020-09-15', 10, 0, false, true, '2027-09-15', 'Sad Okregowy Lublin', 'III K 567/20', 'Andrzej Wojcik'),
(10, 3, '2020-10-08', 4, 6, false, true, '2023-10-08', 'Sad Rejonowy Katowice', 'I K 890/20', 'Magdalena Zielinska'),
(11, 2, '2021-01-20', 3, 0, false, true, NULL, 'Sad Rejonowy Bydgoszcz', 'II K 123/21', 'Robert Szymanski'),
(12, 5, '2021-02-14', 7, 0, false, true, '2025-08-14', 'Sad Okregowy Bialystok', 'III K 456/21', 'Agnieszka Wojtowicz'),
(13, 1, '2021-03-28', 1, 6, false, true, NULL, 'Sad Rejonowy Gdynia', 'I K 789/21', 'Marcin Dabrowski'),
(14, 4, '2021-04-11', 2, 0, false, true, NULL, 'Sad Rejonowy Czestochowa', 'II K 012/21', 'Karolina Kozlowska'),
(15, 10, '2021-05-06', 12, 0, false, true, '2029-05-06', 'Sad Okregowy Radom', 'III K 345/21', 'Pawel Jankowski'),
(16, 7, '2021-06-19', 8, 0, false, true, '2026-06-19', 'Sad Okregowy Torun', 'IV K 678/21', 'Dorota Krawczyk'),
(17, 2, '2021-07-24', 2, 6, false, true, NULL, 'Sad Rejonowy Kielce', 'I K 901/21', 'Grzegorz Pawlak'),
(18, 3, '2021-08-15', 3, 0, false, true, '2023-08-15', 'Sad Rejonowy Rzeszow', 'II K 234/21', 'Monika Walczak'),
(19, 8, '2021-09-03', 9, 0, false, true, '2027-09-03', 'Sad Okregowy Opole', 'III K 567/21', 'Lukasz Kubiak'),
(20, 5, '2021-10-12', 6, 0, false, true, '2025-10-12', 'Sad Okregowy Olsztyn', 'IV K 890/21', 'Natalia Adamska'),
(21, 1, '2022-01-08', 2, 0, false, true, NULL, 'Sad Rejonowy Gorzow', 'I K 123/22', 'Sebastian Piotrowski'),
(22, 4, '2022-02-22', 1, 6, false, true, NULL, 'Sad Rejonowy Zielona Gora', 'II K 456/22', 'Aleksandra Grabowska'),
(23, 6, '2022-03-15', 99, 0, true, false, NULL, 'Sad Okregowy Warszawa', 'III K 789/22', 'Stanislaw Nowakowski'),
(24, 2, '2022-04-01', 1, 0, false, true, NULL, 'Sad Rejonowy Sopot', 'I K 012/22', 'Wioletta Mazurek'),
(25, 9, '2022-05-20', 15, 0, false, false, NULL, 'Sad Okregowy Krakow', 'IV K 345/22', 'Artur Kaczmarek'),
(26, 3, '2022-06-14', 2, 6, false, true, NULL, 'Sad Rejonowy Elblag', 'II K 678/22', 'Beata Grabowska'),
(27, 10, '2022-07-28', 10, 0, false, true, '2029-07-28', 'Sad Okregowy Plock', 'III K 901/22', 'Cezary Pawlowski'),
(28, 5, '2022-08-09', 6, 0, false, true, '2026-08-09', 'Sad Okregowy Walbrzych', 'IV K 234/22', 'Diana Michalska'),
(29, 7, '2022-09-17', 7, 0, false, true, '2027-03-17', 'Sad Okregowy Legnica', 'I K 567/22', 'Emil Zajac'),
(30, 4, '2022-10-25', 2, 0, false, true, NULL, 'Sad Rejonowy Tarnow', 'II K 890/22', 'Felicja Krol'),
(31, 1, '2023-01-12', 1, 6, false, true, NULL, 'Sad Rejonowy Nowy Sacz', 'III K 123/23', 'Gustaw Wrobel'),
(32, 2, '2023-02-28', 2, 0, false, true, NULL, 'Sad Rejonowy Przemysl', 'I K 456/23', 'Halina Dudek'),
(33, 8, '2023-03-18', 5, 0, false, true, '2026-09-18', 'Sad Okregowy Zamosc', 'IV K 789/23', 'Igor Adamczyk'),
(34, 3, '2023-04-05', 2, 6, false, true, NULL, 'Sad Rejonowy Pila', 'II K 012/23', 'Justyna Stepien'),
(35, 1, '2023-05-22', 0, 6, false, true, NULL, 'Sad Rejonowy Konin', 'III K 345/23', 'Kamil Gorski'),
(36, 4, '2023-06-09', 1, 6, false, true, NULL, 'Sad Rejonowy Leszno', 'I K 678/23', 'Lidia Rutkowska'),
(37, 5, '2023-07-14', 4, 0, false, true, '2026-01-14', 'Sad Okregowy Kalisz', 'IV K 901/23', 'Marek Sikora'),
(38, 2, '2023-08-21', 1, 0, false, true, NULL, 'Sad Rejonowy Sieradz', 'II K 234/23', 'Nina Ostrowska'),
(39, 6, '2023-09-03', 20, 0, false, false, NULL, 'Sad Okregowy Krakow', 'III K 567/23', 'Oskar Baran'),
(40, 1, '2023-10-17', 1, 0, false, true, NULL, 'Sad Rejonowy Skierniewice', 'I K 890/23', 'Patrycja Duda'),
(41, 10, '2024-01-05', 8, 0, false, true, '2029-01-05', 'Sad Okregowy Piotrkow', 'IV K 123/24', 'Rafal Szewczyk'),
(42, 4, '2024-02-19', 1, 0, false, true, NULL, 'Sad Rejonowy Radomsko', 'II K 456/24', 'Sandra Blaszczyk'),
(43, 2, '2024-03-08', 2, 0, false, true, NULL, 'Sad Rejonowy Ostrow', 'III K 789/24', 'Tadeusz Mroz'),
(44, 3, '2024-04-12', 1, 6, false, true, NULL, 'Sad Rejonowy Gniezno', 'I K 012/24', 'Urszula Sawicka'),
(45, 5, '2024-05-25', 3, 0, false, true, '2026-05-25', 'Sad Okregowy Inowroclaw', 'IV K 345/24', 'Wiktor Chmielewski'),
(46, 8, '2024-06-14', 6, 0, false, true, '2028-06-14', 'Sad Okregowy Wloclawek', 'II K 678/24', 'Zygmunt Borkowski'),
(47, 7, '2024-07-22', 5, 0, false, true, '2027-07-22', 'Sad Okregowy Grudziadz', 'III K 901/24', 'Adam Pietrzak'),
(48, 1, '2024-08-30', 1, 0, false, true, NULL, 'Sad Rejonowy Swiecie', 'I K 234/24', 'Barbara Walczak'),
(49, 9, '2024-09-15', 12, 0, false, false, NULL, 'Sad Okregowy Chojnice', 'IV K 567/24', 'Czeslaw Kubiak'),
(50, 4, '2024-10-01', 2, 0, false, true, NULL, 'Sad Rejonowy Starogard', 'II K 890/24', 'Danuta Kazmierczak');

-- Additional sentences for some prisoners (repeat offenders)
INSERT INTO sentences (prisoner_id, crime_type_id, sentence_start_date, sentence_years, sentence_months, is_life_sentence, parole_eligible, court_name, case_number, judge_name) VALUES
(1, 4, '2023-01-15', 2, 0, false, true, 'Sad Rejonowy Warszawa', 'II K 999/23', 'Jan Kowalski'),
(5, 2, '2024-05-12', 3, 0, false, true, 'Sad Rejonowy Wroclaw', 'I K 888/24', 'Tomasz Nowicki'),
(9, 4, '2024-09-15', 2, 0, false, true, 'Sad Rejonowy Lublin', 'II K 777/24', 'Andrzej Wojcik'),
(15, 2, '2024-05-06', 2, 0, false, true, 'Sad Rejonowy Radom', 'III K 666/24', 'Pawel Jankowski'),
(20, 1, '2024-10-12', 1, 6, false, true, 'Sad Rejonowy Olsztyn', 'I K 555/24', 'Natalia Adamska');

-- ============================================
-- VISITORS (30 visitors)
-- ============================================

INSERT INTO visitors (first_name, last_name, date_of_birth, id_document_type, id_document_number, relationship_type, phone, email, is_blacklisted, blacklist_reason) VALUES
('Maria', 'Kowalczyk', '1988-05-20', 'national_id', 'ABC123456', 'spouse', '+48701234567', 'maria.k@email.pl', false, NULL),
('Anna', 'Nowakowska', '1980-09-15', 'passport', 'AB1234567', 'spouse', '+48702345678', 'anna.n@email.pl', false, NULL),
('Teresa', 'Mazurek', '1965-03-08', 'national_id', 'DEF234567', 'parent', '+48703456789', 'teresa.m@email.pl', false, NULL),
('Ewa', 'Kaczmarek', '1985-11-22', 'national_id', 'GHI345678', 'spouse', '+48704567890', 'ewa.k@email.pl', false, NULL),
('Jan', 'Grabowski', '1960-07-14', 'passport', 'CD2345678', 'parent', '+48705678901', 'jan.g@email.pl', false, NULL),
('Zofia', 'Pawlowska', '1990-01-30', 'drivers_license', 'JKL456789', 'sibling', '+48706789012', 'zofia.p@email.pl', false, NULL),
('Helena', 'Michalska', '1950-12-05', 'national_id', 'MNO567890', 'parent', '+48707890123', NULL, false, NULL),
('Krystyna', 'Zajac', '1970-04-18', 'national_id', 'PQR678901', 'parent', '+48708901234', 'krystyna.z@email.pl', false, NULL),
('Olga', 'Krol', '1990-08-25', 'passport', 'EF3456789', 'spouse', '+380509876543', 'olga.k@email.ua', false, NULL),
('Barbara', 'Wrobel', '1955-06-12', 'national_id', 'STU789012', 'parent', '+48710123456', NULL, false, NULL),
('Mateusz', 'Kowalski', '1995-02-28', 'national_id', 'VWX890123', 'friend', '+48711234567', 'mateusz.k@email.pl', false, NULL),
('Michal', 'Lewandowski', '2000-10-10', 'national_id', 'YZA901234', 'lawyer', '+48712345678', 'michal.l@kancelaria.pl', false, NULL),
('Katarzyna', 'Wojcik', '1978-03-17', 'passport', 'GH4567890', 'sibling', '+48713456789', 'kasia.w@email.pl', false, NULL),
('Piotr', 'Kowalski', '1982-07-23', 'national_id', 'BCD012345', 'sibling', '+48714567890', 'piotr.k@email.pl', true, 'Attempted to smuggle contraband'),
('Alicja', 'Nowak', '1992-09-05', 'drivers_license', 'EFG123456', 'friend', '+48715678901', 'alicja.n@email.pl', false, NULL),
('Tomasz', 'Wisniewski', '1985-11-14', 'national_id', 'HIJ234567', 'friend', '+48716789012', 'tomasz.w@email.pl', false, NULL),
('Jadwiga', 'Stepien', '1968-04-29', 'national_id', 'KLM345678', 'parent', '+48717890123', NULL, false, NULL),
('Elzbieta', 'Gorska', '1960-08-07', 'passport', 'IJ5678901', 'parent', '+48718901234', 'ela.g@email.pl', false, NULL),
('Irena', 'Rutkowska', '1972-01-19', 'national_id', 'NOP456789', 'parent', '+48719012345', NULL, false, NULL),
('Stanislawa', 'Sikora', '1948-05-30', 'national_id', 'QRS567890', 'parent', '+48720123456', NULL, false, NULL),
('Grazyna', 'Ostrowska', '1965-10-11', 'national_id', 'TUV678901', 'parent', '+48721234567', 'grazyna.o@email.pl', false, NULL),
('Halina', 'Baran', '1970-02-24', 'drivers_license', 'WXY789012', 'parent', '+48722345678', NULL, false, NULL),
('Renata', 'Duda', '1975-06-16', 'national_id', 'ZAB890123', 'spouse', '+48723456789', 'renata.d@email.pl', false, NULL),
('Wanda', 'Szewczyk', '1955-09-03', 'national_id', 'CDE901234', 'parent', '+48724567890', NULL, false, NULL),
('Agata', 'Malinowska', '1988-12-20', 'passport', 'KL6789012', 'spouse', '+48725678901', 'agata.m@email.pl', false, NULL),
('Joanna', 'Olejnik', '1993-03-08', 'national_id', 'FGH012345', 'friend', '+48726789012', 'joanna.o@email.pl', true, 'Verbal abuse to staff'),
('Robert', 'Mazur', '1987-07-25', 'national_id', 'IJK123456', 'lawyer', '+48727890123', 'robert.m@kancelaria.pl', false, NULL),
('Sylwia', 'Kowalska', '1990-04-12', 'drivers_license', 'LMN234567', 'spouse', '+48728901234', 'sylwia.k@email.pl', false, NULL),
('Kamila', 'Jankowska', '1998-08-01', 'national_id', 'OPQ345678', 'child', '+48729012345', 'kamila.j@email.pl', false, NULL),
('Marek', 'Wisniewicz', '1975-11-28', 'passport', 'MN7890123', 'lawyer', '+48730123456', 'marek.w@adwokat.pl', false, NULL);

-- ============================================
-- VISITS (100 visits)
-- ============================================

INSERT INTO visits (prisoner_id, visitor_id, visit_date, scheduled_start_time, scheduled_end_time, actual_start_time, actual_end_time, status, visit_type, approved_by_staff_id, notes) VALUES
(1, 1, '2020-02-15', '10:00', '11:00', '10:05', '10:55', 'completed', 'family', 2, NULL),
(1, 1, '2020-04-10', '14:00', '15:00', '14:00', '14:50', 'completed', 'family', 3, NULL),
(2, 2, '2020-03-20', '09:00', '10:00', '09:10', '10:00', 'completed', 'family', 2, NULL),
(3, 3, '2020-04-15', '11:00', '12:00', '11:00', '11:45', 'completed', 'family', 5, NULL),
(4, 4, '2020-05-08', '10:00', '11:00', NULL, NULL, 'cancelled', 'family', 7, 'Visitor cancelled'),
(5, 5, '2020-06-12', '14:00', '15:00', '14:05', '15:00', 'completed', 'family', 9, NULL),
(6, 6, '2020-07-18', '09:00', '10:00', '09:00', '09:50', 'completed', 'family', 3, NULL),
(7, 7, '2020-08-22', '11:00', '12:00', '11:10', '12:00', 'completed', 'family', 11, NULL),
(8, 8, '2020-09-30', '10:00', '11:00', '10:00', '10:55', 'completed', 'family', 5, NULL),
(9, 9, '2020-10-15', '14:00', '15:00', '14:15', '15:00', 'completed', 'family', 7, NULL),
(10, 10, '2020-11-08', '09:00', '10:00', NULL, NULL, 'no_show', 'family', 9, 'Visitor did not appear'),
(1, 11, '2021-01-20', '10:00', '11:00', '10:00', '10:50', 'completed', 'regular', 2, NULL),
(2, 12, '2021-02-14', '14:00', '15:30', '14:00', '15:25', 'completed', 'legal', 3, 'Meeting with lawyer'),
(3, 13, '2021-03-28', '11:00', '12:00', '11:05', '11:55', 'completed', 'family', 5, NULL),
(5, 15, '2021-04-11', '09:00', '10:00', '09:00', '09:45', 'completed', 'regular', 7, NULL),
(6, 16, '2021-05-06', '10:00', '11:00', '10:10', '11:00', 'completed', 'regular', 9, NULL),
(8, 17, '2021-06-19', '14:00', '15:00', '14:00', '14:50', 'completed', 'family', 11, NULL),
(9, 18, '2021-07-24', '11:00', '12:00', '11:00', '11:55', 'completed', 'family', 2, NULL),
(10, 19, '2021-08-15', '09:00', '10:00', '09:05', '10:00', 'completed', 'family', 3, NULL),
(11, 20, '2021-09-03', '10:00', '11:00', NULL, NULL, 'cancelled', 'family', 5, 'Prisoner in solitary'),
(12, 21, '2021-10-12', '14:00', '15:00', '14:00', '14:45', 'completed', 'family', 7, NULL),
(1, 1, '2021-11-20', '10:00', '11:00', '10:00', '10:55', 'completed', 'family', 9, NULL),
(2, 2, '2022-01-08', '09:00', '10:00', '09:10', '10:00', 'completed', 'family', 11, NULL),
(3, 3, '2022-02-22', '11:00', '12:00', '11:00', '11:50', 'completed', 'family', 2, NULL),
(5, 5, '2022-03-15', '14:00', '15:00', '14:05', '15:00', 'completed', 'family', 3, NULL),
(7, 7, '2022-04-01', '10:00', '11:00', '10:00', '10:50', 'completed', 'family', 5, NULL),
(9, 9, '2022-05-20', '09:00', '10:00', '09:00', '09:55', 'completed', 'family', 7, NULL),
(10, 22, '2022-06-14', '11:00', '12:00', '11:10', '12:00', 'completed', 'family', 9, NULL),
(11, 23, '2022-07-28', '14:00', '15:00', '14:00', '14:50', 'completed', 'family', 11, NULL),
(12, 24, '2022-08-09', '10:00', '11:00', '10:05', '11:00', 'completed', 'family', 2, NULL),
(15, 25, '2022-09-17', '09:00', '10:00', '09:00', '09:45', 'completed', 'family', 3, NULL),
(1, 27, '2022-10-25', '14:00', '15:30', '14:00', '15:20', 'completed', 'legal', 5, 'Appeal discussion'),
(18, 28, '2022-11-12', '11:00', '12:00', '11:00', '11:55', 'completed', 'family', 7, NULL),
(19, 29, '2022-12-03', '10:00', '11:00', '10:10', '11:00', 'completed', 'family', 9, NULL),
(20, 30, '2023-01-12', '09:00', '10:30', '09:00', '10:25', 'completed', 'legal', 11, 'Parole hearing prep'),
(1, 1, '2023-02-28', '14:00', '15:00', '14:00', '14:50', 'completed', 'family', 2, NULL),
(3, 3, '2023-03-18', '11:00', '12:00', '11:05', '12:00', 'completed', 'family', 3, NULL),
(5, 5, '2023-04-05', '10:00', '11:00', '10:00', '10:55', 'completed', 'family', 5, NULL),
(7, 7, '2023-05-22', '09:00', '10:00', '09:00', '09:50', 'completed', 'family', 7, NULL),
(9, 9, '2023-06-09', '14:00', '15:00', '14:10', '15:00', 'completed', 'family', 9, NULL),
(10, 10, '2023-07-14', '11:00', '12:00', '11:00', '11:45', 'completed', 'family', 11, NULL),
(12, 12, '2023-08-21', '10:00', '11:30', '10:00', '11:25', 'completed', 'legal', 2, NULL),
(15, 15, '2023-09-03', '09:00', '10:00', '09:05', '10:00', 'completed', 'regular', 3, NULL),
(18, 17, '2023-10-17', '14:00', '15:00', '14:00', '14:50', 'completed', 'family', 5, NULL),
(20, 20, '2023-11-05', '11:00', '12:00', '11:00', '11:55', 'completed', 'family', 7, NULL),
(22, 21, '2023-12-14', '10:00', '11:00', '10:10', '11:00', 'completed', 'family', 9, NULL),
(25, 27, '2024-01-08', '09:00', '10:30', '09:00', '10:20', 'completed', 'legal', 11, 'Appeal hearing'),
(27, 30, '2024-02-22', '14:00', '15:30', '14:00', '15:25', 'completed', 'legal', 2, NULL),
(30, 22, '2024-03-15', '11:00', '12:00', '11:05', '12:00', 'completed', 'family', 3, NULL),
(32, 23, '2024-04-01', '10:00', '11:00', '10:00', '10:50', 'completed', 'family', 5, NULL),
(35, 24, '2024-05-20', '09:00', '10:00', '09:00', '09:55', 'completed', 'family', 7, NULL),
(37, 25, '2024-06-14', '14:00', '15:00', '14:10', '15:00', 'completed', 'family', 9, NULL),
(40, 28, '2024-07-28', '11:00', '12:00', '11:00', '11:45', 'completed', 'family', 11, NULL),
(42, 29, '2024-08-09', '10:00', '11:00', '10:05', '11:00', 'completed', 'family', 2, NULL),
(45, 30, '2024-09-17', '09:00', '10:30', '09:00', '10:20', 'completed', 'legal', 3, 'Sentence review'),
(1, 1, '2024-10-25', '14:00', '15:00', '14:00', '14:55', 'completed', 'family', 5, NULL),
(3, 3, '2024-11-12', '11:00', '12:00', '11:00', '11:50', 'completed', 'family', 7, NULL),
(5, 5, '2024-12-03', '10:00', '11:00', '10:05', '11:00', 'completed', 'family', 9, NULL),
(7, 7, '2024-12-20', '09:00', '10:00', '09:00', '09:55', 'completed', 'family', 11, NULL),
(10, 10, '2025-01-10', '14:00', '15:00', NULL, NULL, 'scheduled', 'family', 2, NULL),
(12, 12, '2025-01-15', '11:00', '12:30', NULL, NULL, 'scheduled', 'legal', 3, NULL),
(15, 15, '2025-01-18', '10:00', '11:00', NULL, NULL, 'scheduled', 'regular', 5, NULL),
(18, 17, '2025-01-20', '09:00', '10:00', NULL, NULL, 'scheduled', 'family', 7, NULL),
(20, 20, '2025-01-22', '14:00', '15:00', NULL, NULL, 'scheduled', 'family', 9, NULL),
(25, 27, '2025-01-25', '11:00', '12:30', NULL, NULL, 'scheduled', 'legal', 11, 'Appeal preparation'),
(30, 22, '2025-01-28', '10:00', '11:00', NULL, NULL, 'scheduled', 'family', 2, NULL),
(35, 24, '2025-02-01', '09:00', '10:00', NULL, NULL, 'scheduled', 'family', 3, NULL),
(40, 28, '2025-02-05', '14:00', '15:00', NULL, NULL, 'scheduled', 'family', 5, NULL),
(45, 30, '2025-02-10', '11:00', '12:30', NULL, NULL, 'scheduled', 'legal', 7, NULL);

-- More historical visits to reach 100
INSERT INTO visits (prisoner_id, visitor_id, visit_date, scheduled_start_time, scheduled_end_time, actual_start_time, actual_end_time, status, visit_type, approved_by_staff_id) VALUES
(2, 2, '2020-05-15', '10:00', '11:00', '10:00', '10:50', 'completed', 'family', 2),
(4, 4, '2020-07-20', '14:00', '15:00', '14:05', '15:00', 'completed', 'family', 3),
(6, 6, '2020-09-25', '09:00', '10:00', '09:00', '09:55', 'completed', 'family', 5),
(8, 8, '2020-11-30', '11:00', '12:00', '11:10', '12:00', 'completed', 'family', 7),
(1, 11, '2021-03-05', '10:00', '11:00', '10:00', '10:45', 'completed', 'regular', 9),
(3, 13, '2021-05-18', '14:00', '15:00', '14:00', '14:50', 'completed', 'family', 11),
(5, 15, '2021-07-22', '09:00', '10:00', '09:05', '10:00', 'completed', 'regular', 2),
(7, 16, '2021-09-28', '11:00', '12:00', '11:00', '11:55', 'completed', 'regular', 3),
(9, 18, '2021-11-15', '10:00', '11:00', '10:00', '10:50', 'completed', 'family', 5),
(11, 20, '2022-01-20', '14:00', '15:00', '14:10', '15:00', 'completed', 'family', 7),
(13, 21, '2022-03-25', '09:00', '10:00', '09:00', '09:45', 'completed', 'family', 9),
(15, 23, '2022-05-30', '11:00', '12:00', '11:05', '12:00', 'completed', 'family', 11),
(17, 24, '2022-08-05', '10:00', '11:00', '10:00', '10:55', 'completed', 'family', 2),
(19, 28, '2022-10-10', '14:00', '15:00', '14:00', '14:50', 'completed', 'family', 3),
(21, 29, '2022-12-15', '09:00', '10:00', '09:00', '09:55', 'completed', 'family', 5),
(23, 30, '2023-02-20', '11:00', '12:30', '11:00', '12:20', 'completed', 'legal', 7),
(25, 27, '2023-04-25', '10:00', '11:30', '10:05', '11:25', 'completed', 'legal', 9),
(27, 12, '2023-06-30', '14:00', '15:30', '14:00', '15:20', 'completed', 'legal', 11),
(29, 30, '2023-09-05', '09:00', '10:30', '09:00', '10:25', 'completed', 'legal', 2),
(31, 22, '2023-11-10', '11:00', '12:00', '11:10', '12:00', 'completed', 'family', 3),
(33, 23, '2024-01-15', '10:00', '11:00', '10:00', '10:50', 'completed', 'family', 5),
(36, 25, '2024-03-20', '14:00', '15:00', '14:05', '15:00', 'completed', 'family', 7),
(38, 28, '2024-05-25', '09:00', '10:00', '09:00', '09:55', 'completed', 'family', 9),
(41, 29, '2024-07-30', '11:00', '12:00', '11:00', '11:45', 'completed', 'family', 11),
(43, 21, '2024-10-05', '10:00', '11:00', '10:00', '10:50', 'completed', 'family', 2),
(46, 24, '2024-11-20', '14:00', '15:00', '14:10', '15:00', 'completed', 'family', 3),
(48, 28, '2024-12-10', '09:00', '10:00', '09:00', '09:55', 'completed', 'family', 5),
(50, 9, '2024-12-28', '11:00', '12:00', '11:05', '12:00', 'completed', 'family', 7),
(2, 12, '2024-11-05', '14:00', '15:30', '14:00', '15:20', 'completed', 'legal', 9),
(4, 4, '2024-12-15', '10:00', '11:00', '10:00', '10:50', 'completed', 'family', 11);

-- ============================================
-- PROGRAMS (8 programs)
-- ============================================

INSERT INTO programs (name, program_type_id, description, duration_weeks, max_participants, instructor_staff_id, is_active) VALUES
('GED Preparation', 1, 'High school equivalency diploma preparation course', 24, 20, 6, true),
('Anger Management', 3, 'Cognitive behavioral therapy for anger issues', 12, 15, 4, true),
('Carpentry Skills', 2, 'Basic woodworking and carpentry training', 16, 10, NULL, true),
('Drug Rehabilitation', 4, 'Substance abuse treatment program', 20, 12, 10, true),
('Computer Literacy', 2, 'Basic computer skills and office applications', 8, 15, 6, true),
('Art Therapy', 3, 'Expressive arts therapy for emotional healing', 10, 12, 4, true),
('Culinary Training', 2, 'Food preparation and kitchen skills', 14, 8, NULL, true),
('Literacy Program', 1, 'Basic reading and writing skills', 16, 20, 12, true);

-- ============================================
-- PRISONER PROGRAMS (60 enrollments)
-- ============================================

INSERT INTO prisoner_programs (prisoner_id, program_id, enrollment_date, completion_date, status, grade, notes) VALUES
(1, 1, '2020-03-01', '2020-08-15', 'completed', 'B', 'Good progress'),
(1, 5, '2020-09-01', '2020-10-25', 'completed', 'A', 'Excellent computer skills'),
(2, 2, '2020-04-01', '2020-06-24', 'completed', 'B', NULL),
(3, 4, '2020-05-01', '2020-09-18', 'completed', 'C', 'Struggled initially'),
(4, 2, '2020-06-01', '2020-08-24', 'completed', 'A', 'Great improvement'),
(5, 3, '2020-07-01', NULL, 'enrolled', NULL, 'Currently enrolled'),
(6, 1, '2020-08-01', '2021-01-15', 'completed', 'B', NULL),
(7, 6, '2020-09-01', '2020-11-10', 'completed', 'A', 'Talented artist'),
(8, 4, '2020-10-01', '2021-02-17', 'completed', 'B', NULL),
(9, 2, '2020-11-01', '2021-01-24', 'completed', 'C', NULL),
(10, 7, '2020-12-01', '2021-03-08', 'completed', 'A', 'Showed great enthusiasm'),
(11, 1, '2021-02-01', '2021-07-15', 'completed', 'B', NULL),
(12, 3, '2021-03-01', '2021-06-21', 'completed', 'B', NULL),
(13, 5, '2021-04-01', '2021-05-27', 'completed', 'A', NULL),
(14, 4, '2021-05-01', '2021-09-17', 'completed', 'B', NULL),
(15, 2, '2021-06-01', '2021-08-24', 'completed', 'D', 'Minimal participation'),
(16, 6, '2021-07-01', '2021-09-09', 'completed', 'B', NULL),
(17, 8, '2021-08-01', '2021-11-22', 'completed', 'A', 'Learned to read'),
(18, 1, '2021-09-01', '2022-02-15', 'completed', 'C', NULL),
(19, 7, '2021-10-01', '2022-01-07', 'completed', 'B', NULL),
(20, 3, '2021-11-01', '2022-02-21', 'completed', 'A', 'Skilled craftsman'),
(21, 5, '2022-02-01', '2022-03-29', 'completed', 'B', NULL),
(22, 4, '2022-03-01', '2022-07-18', 'completed', 'B', NULL),
(23, 6, '2022-04-01', NULL, 'dropped', NULL, 'Health issues'),
(24, 2, '2022-05-01', '2022-07-24', 'completed', 'A', NULL),
(25, 1, '2022-06-01', '2022-11-15', 'completed', 'B', NULL),
(26, 8, '2022-07-01', '2022-10-22', 'completed', 'B', NULL),
(27, 3, '2022-08-01', NULL, 'enrolled', NULL, NULL),
(28, 4, '2022-09-01', '2023-01-18', 'completed', 'C', NULL),
(29, 7, '2022-10-01', '2023-01-07', 'completed', 'B', NULL),
(30, 2, '2022-11-01', '2023-01-24', 'completed', 'A', NULL),
(31, 5, '2023-02-01', '2023-03-29', 'completed', 'B', NULL),
(32, 6, '2023-03-01', '2023-05-10', 'completed', 'A', NULL),
(33, 1, '2023-04-01', '2023-09-15', 'completed', 'B', NULL),
(34, 4, '2023-05-01', '2023-09-17', 'completed', 'B', NULL),
(36, 3, '2023-07-01', '2023-10-21', 'completed', 'C', NULL),
(37, 2, '2023-08-01', '2023-10-24', 'completed', 'B', NULL),
(38, 8, '2023-09-01', '2023-12-22', 'completed', 'A', NULL),
(39, 6, '2023-10-01', NULL, 'enrolled', NULL, NULL),
(40, 5, '2023-11-01', '2023-12-27', 'completed', 'B', NULL),
(41, 1, '2024-01-15', NULL, 'enrolled', NULL, NULL),
(42, 4, '2024-02-20', NULL, 'enrolled', NULL, NULL),
(43, 2, '2024-03-25', NULL, 'enrolled', NULL, NULL),
(44, 7, '2024-04-10', NULL, 'enrolled', NULL, NULL),
(45, 3, '2024-05-15', NULL, 'enrolled', NULL, NULL),
(46, 6, '2024-06-20', NULL, 'enrolled', NULL, NULL),
(47, 8, '2024-07-25', NULL, 'enrolled', NULL, NULL),
(48, 5, '2024-08-10', '2024-10-05', 'completed', 'B', NULL),
(49, 2, '2024-09-15', NULL, 'enrolled', NULL, NULL),
(50, 4, '2024-10-20', NULL, 'enrolled', NULL, NULL),
(1, 2, '2023-01-15', '2023-04-08', 'completed', 'A', 'Second program'),
(5, 4, '2024-01-10', NULL, 'enrolled', NULL, 'Rehabilitation'),
(10, 1, '2024-02-01', NULL, 'enrolled', NULL, 'GED prep'),
(15, 6, '2024-03-01', NULL, 'expelled', NULL, 'Disciplinary issue'),
(20, 7, '2024-04-01', NULL, 'enrolled', NULL, NULL),
(25, 8, '2024-05-01', NULL, 'enrolled', NULL, NULL),
(30, 5, '2024-06-01', '2024-07-27', 'completed', 'A', NULL),
(35, 1, '2024-07-01', NULL, 'dropped', NULL, 'Released early'),
(40, 3, '2024-08-01', NULL, 'enrolled', NULL, NULL),
(45, 6, '2024-09-01', NULL, 'enrolled', NULL, NULL);

-- ============================================
-- INCIDENTS (25 incidents)
-- ============================================

INSERT INTO incidents (prisoner_id, reported_by_staff_id, incident_date, incident_type, severity, location, description, action_taken, solitary_days, is_resolved, resolved_date) VALUES
(5, 3, '2020-08-15 14:30:00', 'fight', 'moderate', 'Block A Yard', 'Physical altercation with another inmate over recreation time dispute.', 'Both inmates separated and given warnings', 3, true, '2020-08-18'),
(9, 5, '2020-10-22 09:15:00', 'contraband', 'minor', 'Cell B-101', 'Unauthorized phone charger found during cell inspection.', 'Item confiscated, verbal warning issued', 0, true, '2020-10-22'),
(7, 11, '2021-01-05 16:45:00', 'disobedience', 'minor', 'Cafeteria', 'Refused to follow mealtime procedures and verbal confrontation with staff.', 'Meal privileges suspended for 2 days', 0, true, '2021-01-07'),
(15, 7, '2021-03-12 11:00:00', 'fight', 'major', 'Block B Corridor', 'Violent fight resulting in minor injuries to both parties.', 'Medical treatment provided, solitary confinement', 7, true, '2021-03-19'),
(3, 9, '2021-05-28 20:30:00', 'contraband', 'moderate', 'Cell A-102', 'Homemade alcohol found hidden in cell.', 'Contraband destroyed, program privileges revoked', 5, true, '2021-06-02'),
(23, 8, '2022-04-10 08:00:00', 'assault_staff', 'critical', 'Block C Entrance', 'Attempted assault on guard during morning count.', 'Immediate solitary, disciplinary hearing scheduled', 14, true, '2022-04-24'),
(12, 3, '2022-06-15 13:20:00', 'property_damage', 'moderate', 'Workshop', 'Intentional damage to carpentry equipment during program.', 'Workshop access revoked, cost deducted from account', 3, true, '2022-06-18'),
(19, 5, '2022-08-22 17:45:00', 'contraband', 'major', 'Cell B-201', 'Small quantity of controlled substance found during random search.', 'Transfer to higher security, criminal charges filed', 10, true, '2022-09-01'),
(27, 11, '2022-11-03 10:30:00', 'escape_attempt', 'critical', 'Block C Yard', 'Attempted to scale perimeter fence during outdoor time.', 'Transfer to supermax, extended sentence recommended', 30, true, '2022-12-03'),
(8, 7, '2023-01-18 15:00:00', 'fight', 'minor', 'Recreation Room', 'Minor scuffle during card game, quickly resolved.', 'Verbal warning to both parties', 0, true, '2023-01-18'),
(25, 8, '2023-03-25 09:45:00', 'disobedience', 'moderate', 'Medical Wing', 'Refused to take prescribed medication and became verbally aggressive.', 'Mandatory medical evaluation scheduled', 2, true, '2023-03-27'),
(33, 9, '2023-06-08 14:15:00', 'contraband', 'minor', 'Visitor Area', 'Visitor attempted to pass unauthorized item, inmate reported incident.', 'Visitor privileges for that person revoked', 0, true, '2023-06-08'),
(16, 3, '2023-08-14 11:30:00', 'fight', 'moderate', 'Block B Yard', 'Gang-related confrontation between two groups.', 'Multiple inmates isolated, investigation ongoing', 5, true, '2023-08-19'),
(41, 5, '2024-02-20 08:30:00', 'disobedience', 'minor', 'Cafeteria', 'Disruptive behavior during breakfast, threw food tray.', 'Cleaning duty assigned for one week', 0, true, '2024-02-27'),
(29, 7, '2024-04-05 16:00:00', 'property_damage', 'minor', 'Cell C-103', 'Damaged cell door lock mechanism in frustration.', 'Repair costs deducted, counseling required', 2, true, '2024-04-07'),
(45, 9, '2024-06-12 10:00:00', 'contraband', 'moderate', 'Cell B-203', 'Improvised weapon found during routine inspection.', 'Weapon confiscated, transfer to higher security pending', 7, true, '2024-06-19'),
(38, 11, '2024-08-01 19:30:00', 'fight', 'minor', 'Block A Dormitory', 'Brief altercation over television channel selection.', 'TV privileges suspended for both inmates', 0, true, '2024-08-01'),
(50, 8, '2024-10-15 12:45:00', 'disobedience', 'minor', 'Work Assignment', 'Failed to report for assigned kitchen duty.', 'Work privileges suspended for one week', 0, true, '2024-10-22'),
(22, 3, '2024-11-08 14:00:00', 'other', 'minor', 'Library', 'Inappropriate behavior with another inmate in library.', 'Library access restricted', 0, true, '2024-11-08'),
(47, 5, '2024-12-01 09:00:00', 'contraband', 'moderate', 'Cell B-301', 'Unauthorized electronic device found.', 'Device confiscated, visiting hours reduced', 3, false, NULL),
(1, 7, '2024-12-10 11:15:00', 'fight', 'minor', 'Block A Yard', 'Pushed another inmate during basketball game.', 'Both inmates counseled', 0, true, '2024-12-10'),
(36, 9, '2024-12-15 16:30:00', 'disobedience', 'minor', 'Cell Block A', 'Refused cell inspection, verbal warning escalated.', 'Written warning issued', 0, false, NULL),
(44, 11, '2024-12-20 08:45:00', 'other', 'minor', 'Shower Area', 'Exceeded shower time limit repeatedly.', 'Shower schedule adjusted', 0, true, '2024-12-20'),
(18, 8, '2024-12-28 13:00:00', 'contraband', 'minor', 'Visitor Room', 'Attempted to receive unauthorized snacks from visitor.', 'Items confiscated, warning issued', 0, true, '2024-12-28'),
(31, 3, '2025-01-05 10:30:00', 'disobedience', 'minor', 'Cafeteria', 'Complained loudly about food quality, refused to move when asked.', 'Verbal warning', 0, false, NULL);


-- Re-enable triggers after bulk insert
ALTER TABLE prisoners ENABLE TRIGGER trg_check_cell_capacity;
ALTER TABLE visits ENABLE TRIGGER trg_check_visitor_blacklist;

-- Commit transaction (rollback on any error will restore trigger states)
COMMIT;

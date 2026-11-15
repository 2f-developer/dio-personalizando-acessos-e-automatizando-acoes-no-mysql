-- Parte 1: visões sobre o banco COMPANY.
USE company;

-- Número de empregados por departamento e localidade.
-- Um departamento com várias cidades aparece uma vez por cidade.
CREATE OR REPLACE VIEW vw_empregados_por_depto_local AS
SELECT d.dnumber, d.dname AS departamento, l.dlocation AS localidade, COUNT(e.ssn) AS empregados
FROM department d
JOIN dept_locations l ON l.dnumber = d.dnumber
LEFT JOIN employee e ON e.dno = d.dnumber
GROUP BY d.dnumber, d.dname, l.dlocation;

-- Departamentos e seus gerentes.
CREATE OR REPLACE VIEW vw_departamentos_gerentes AS
SELECT d.dnumber, d.dname AS departamento, CONCAT(m.fname, ' ', m.lname) AS gerente, d.mgr_start_date AS gerente_desde
FROM department d
LEFT JOIN employee m ON m.ssn = d.mgr_ssn;

-- Projetos com maior número de empregados.
-- A view guarda a contagem; a ordenação vai na consulta, porque ORDER BY dentro
-- de view não é garantido quando ela é usada em outra consulta.
CREATE OR REPLACE VIEW vw_projetos_empregados AS
SELECT p.pnumber, p.pname AS projeto, COUNT(w.essn) AS empregados, COALESCE(SUM(w.hours), 0) AS horas_semanais
FROM project p
LEFT JOIN works_on w ON w.pno = p.pnumber
GROUP BY p.pnumber, p.pname;

-- Projetos, departamentos e gerentes.
CREATE OR REPLACE VIEW vw_projetos_departamentos_gerentes AS
SELECT p.pname AS projeto, p.plocation AS local_projeto, d.dname AS departamento, CONCAT(m.fname, ' ', m.lname) AS gerente
FROM project p
JOIN department d ON d.dnumber = p.dnum
LEFT JOIN employee m ON m.ssn = d.mgr_ssn;

-- Empregados que têm dependentes, e se são gerentes.
CREATE OR REPLACE VIEW vw_empregados_com_dependentes AS
SELECT e.ssn, CONCAT(e.fname, ' ', e.lname) AS empregado,
       COUNT(dp.dependent_name) AS dependentes,
       EXISTS (SELECT 1 FROM department d WHERE d.mgr_ssn = e.ssn) AS gerente
FROM employee e
JOIN dependent dp ON dp.essn = e.ssn
GROUP BY e.ssn, e.fname, e.lname;

-- Visão pensada para o perfil de funcionário: dados de colegas sem salário,
-- endereço ou qualquer informação de departamento e gerência.
CREATE OR REPLACE VIEW vw_diretorio_empregados AS
SELECT CONCAT(fname, ' ', lname) AS nome, sex AS sexo
FROM employee;

-- Exemplos
SELECT * FROM vw_empregados_por_depto_local ORDER BY departamento, localidade;
SELECT * FROM vw_projetos_empregados ORDER BY empregados DESC, horas_semanais DESC;
SELECT * FROM vw_empregados_com_dependentes;

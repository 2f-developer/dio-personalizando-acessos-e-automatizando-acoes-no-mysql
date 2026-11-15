-- Parte 1: permissões por tipo de conta, usando roles do MySQL 8.
-- As senhas abaixo são de exemplo: troque antes de usar fora de um ambiente de estudo.

DROP USER IF EXISTS 'gerente'@'%', 'funcionario'@'%';
DROP ROLE IF EXISTS 'company_gerencia', 'company_funcionario';

CREATE ROLE 'company_gerencia', 'company_funcionario';

-- Gerência: vê as informações de empregados e de departamentos (e só pelas views).
GRANT SELECT ON company.vw_empregados_por_depto_local TO 'company_gerencia';
GRANT SELECT ON company.vw_departamentos_gerentes TO 'company_gerencia';
GRANT SELECT ON company.vw_projetos_empregados TO 'company_gerencia';
GRANT SELECT ON company.vw_projetos_departamentos_gerentes TO 'company_gerencia';
GRANT SELECT ON company.vw_empregados_com_dependentes TO 'company_gerencia';
GRANT SELECT ON company.vw_diretorio_empregados TO 'company_gerencia';

-- Funcionário: só o diretório e a alocação em projetos; nada de departamentos ou gerentes.
GRANT SELECT ON company.vw_diretorio_empregados TO 'company_funcionario';
GRANT SELECT ON company.vw_projetos_empregados TO 'company_funcionario';

CREATE USER 'gerente'@'%' IDENTIFIED BY 'Gerente#2026' DEFAULT ROLE 'company_gerencia';
CREATE USER 'funcionario'@'%' IDENTIFIED BY 'Funcionario#2026' DEFAULT ROLE 'company_funcionario';

SHOW GRANTS FOR 'gerente'@'%' USING 'company_gerencia';
SHOW GRANTS FOR 'funcionario'@'%' USING 'company_funcionario';

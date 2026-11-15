-- Verificações das duas partes. Qualquer falha interrompe com erro.
USE ecommerce_gatilhos;

DELIMITER $$

CREATE PROCEDURE espera_erro(IN descricao VARCHAR(200), IN comando TEXT)
BEGIN
  DECLARE falhou BOOLEAN DEFAULT FALSE;
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET falhou = TRUE;
    SET @comando = comando;
    PREPARE stmt FROM @comando;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END;
  IF NOT falhou THEN
    SET @msg = CONCAT('FALHOU (deveria ser recusado): ', descricao);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @msg;
  END IF;
  SELECT CONCAT('ok  ', descricao) AS resultado;
END$$

CREATE PROCEDURE espera_igual(IN descricao VARCHAR(200), IN obtido VARCHAR(100), IN esperado VARCHAR(100))
BEGIN
  IF NOT (obtido <=> esperado) THEN
    SET @msg = CONCAT('FALHOU: ', descricao, ' (obtido ', COALESCE(obtido, 'NULL'), ', esperado ', COALESCE(esperado, 'NULL'), ')');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @msg;
  END IF;
  SELECT CONCAT('ok  ', descricao) AS resultado;
END$$

DELIMITER ;

-- Views (parte 1)
CALL espera_igual('Research tem 5 empregados em cada uma das 3 cidades',
  (SELECT GROUP_CONCAT(empregados) FROM company.vw_empregados_por_depto_local WHERE departamento = 'Research'), '5,5,5');
CALL espera_igual('projeto com mais empregados',
  (SELECT projeto FROM company.vw_projetos_empregados ORDER BY empregados DESC, horas_semanais DESC LIMIT 1), 'Newbenefits');
CALL espera_igual('empregados com dependentes que são gerentes',
  (SELECT GROUP_CONCAT(empregado ORDER BY empregado) FROM company.vw_empregados_com_dependentes WHERE gerente), 'Franklin Wong,Jennifer Wallace');

-- Gatilho de remoção
CALL espera_igual('cliente excluído foi arquivado com o resumo de compras',
  (SELECT CONCAT(email, ' ', pedidos, ' ', total_gasto) FROM cliente_excluido WHERE id = 1), 'ana@email.com 2 369.70');
CALL espera_igual('os pedidos do cliente excluído continuam existindo',
  (SELECT COUNT(*) FROM pedido WHERE cliente_id IS NULL), '2');

-- Gatilhos de colaborador
CALL espera_igual('admissão sem salário usa o piso do cargo',
  (SELECT salario_novo FROM historico_salario WHERE motivo = 'admissao' AND colaborador_id = 1), '2100.00');
CALL espera_erro('admissão abaixo do piso é recusada',
  "INSERT INTO colaborador (nome, cargo_id, salario_base) VALUES ('X', 2, 1000)");
CALL espera_erro('redução de salário é recusada',
  "UPDATE colaborador SET salario_base = 2000 WHERE id = 1");
CALL espera_igual('promoção leva o salário ao piso do novo cargo',
  (SELECT salario_base FROM colaborador WHERE id = 2), '6500.00');
CALL espera_igual('cada mudança de salário gera histórico',
  (SELECT COUNT(*) FROM historico_salario), '4');
UPDATE colaborador SET nome = 'Carla N. Nunes' WHERE id = 1;
CALL espera_igual('mudança só de nome não gera histórico',
  (SELECT COUNT(*) FROM historico_salario), '4');

DROP PROCEDURE espera_erro;
DROP PROCEDURE espera_igual;
SELECT 'todas as verificações passaram' AS resultado;

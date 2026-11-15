USE ecommerce_gatilhos;

DELIMITER $$

-- Remoção: antes de apagar a conta, guarda os dados e um resumo das compras.
CREATE TRIGGER trg_cliente_before_delete BEFORE DELETE ON cliente
FOR EACH ROW
BEGIN
  INSERT INTO cliente_excluido (id, nome, email, cpf, criado_em, pedidos, total_gasto, excluido_por)
  SELECT OLD.id, OLD.nome, OLD.email, OLD.cpf, OLD.criado_em, COUNT(p.id), COALESCE(SUM(p.total), 0), CURRENT_USER()
  FROM pedido p
  WHERE p.cliente_id = OLD.id;
END$$

-- Inserção de colaborador: sem salário informado, entra com o piso do cargo;
-- com salário informado, ele não pode ficar abaixo do piso.
CREATE TRIGGER trg_colaborador_before_insert BEFORE INSERT ON colaborador
FOR EACH ROW
BEGIN
  DECLARE v_piso DECIMAL(10, 2);
  SELECT piso INTO v_piso FROM cargo WHERE id = NEW.cargo_id;
  IF NEW.salario_base IS NULL THEN
    SET NEW.salario_base = v_piso;
  ELSEIF NEW.salario_base < v_piso THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salário base abaixo do piso do cargo.';
  END IF;
END$$

CREATE TRIGGER trg_colaborador_after_insert AFTER INSERT ON colaborador
FOR EACH ROW
BEGIN
  INSERT INTO historico_salario (colaborador_id, salario_antigo, salario_novo, motivo, alterado_por)
  VALUES (NEW.id, NULL, NEW.salario_base, 'admissao', CURRENT_USER());
END$$

-- Atualização do salário base: valida contra o piso (do cargo novo, se mudou)
-- e registra o histórico. Redução salarial é bloqueada (irredutibilidade).
CREATE TRIGGER trg_colaborador_before_update BEFORE UPDATE ON colaborador
FOR EACH ROW
BEGIN
  DECLARE v_piso DECIMAL(10, 2);
  IF NEW.salario_base <> OLD.salario_base OR NEW.cargo_id <> OLD.cargo_id THEN
    SELECT piso INTO v_piso FROM cargo WHERE id = NEW.cargo_id;
    IF NEW.salario_base < OLD.salario_base THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O salário base não pode ser reduzido.';
    END IF;
    -- Promoção para um cargo de piso maior sobe o salário até o piso.
    IF NEW.salario_base < v_piso THEN
      SET NEW.salario_base = v_piso;
    END IF;
    INSERT INTO historico_salario (colaborador_id, salario_antigo, salario_novo, motivo, alterado_por)
    VALUES (OLD.id, OLD.salario_base, NEW.salario_base,
            IF(NEW.cargo_id <> OLD.cargo_id, 'troca_de_cargo', 'reajuste'), CURRENT_USER());
  END IF;
END$$

DELIMITER ;

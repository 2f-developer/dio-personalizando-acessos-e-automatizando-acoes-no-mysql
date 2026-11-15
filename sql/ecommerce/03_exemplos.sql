USE ecommerce_gatilhos;

INSERT INTO cliente (id, nome, email, cpf, criado_em) VALUES
  (1, 'Ana Souza', 'ana@email.com', '12345678909', '2025-03-10'),
  (2, 'Bruno Lima', 'bruno@email.com', '98765432100', '2025-07-22');
INSERT INTO pedido (cliente_id, total) VALUES (1, 249.90), (1, 119.80), (2, 389.00);

INSERT INTO cargo (id, nome, piso) VALUES (1, 'Atendente', 2100.00), (2, 'Analista de Logística', 3800.00), (3, 'Coordenador', 6500.00);

-- Entra com o piso do cargo, porque o salário não foi informado.
INSERT INTO colaborador (nome, cargo_id) VALUES ('Carla Nunes', 1);
-- Entra com salário acima do piso.
INSERT INTO colaborador (nome, cargo_id, salario_base) VALUES ('Diego Rocha', 2, 4200.00);

-- Reajuste de 8% para a Carla e promoção do Diego.
UPDATE colaborador SET salario_base = ROUND(salario_base * 1.08, 2) WHERE nome = 'Carla Nunes';
UPDATE colaborador SET cargo_id = 3 WHERE nome = 'Diego Rocha';

-- A Ana exclui a conta; os pedidos ficam, os dados vão para cliente_excluido.
DELETE FROM cliente WHERE id = 1;

SELECT * FROM cliente_excluido;
SELECT c.nome, h.salario_antigo, h.salario_novo, h.motivo FROM historico_salario h JOIN colaborador c ON c.id = h.colaborador_id ORDER BY h.id;

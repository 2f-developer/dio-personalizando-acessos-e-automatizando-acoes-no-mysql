-- Parte 2: e-commerce com as tabelas que os gatilhos precisam.
DROP DATABASE IF EXISTS ecommerce_gatilhos;
CREATE DATABASE ecommerce_gatilhos CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE ecommerce_gatilhos;

CREATE TABLE cliente (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome       VARCHAR(120) NOT NULL,
  email      VARCHAR(120) NOT NULL UNIQUE,
  cpf        CHAR(11) NOT NULL UNIQUE,
  criado_em  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pedido (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id  INT UNSIGNED,
  total       DECIMAL(10, 2) NOT NULL,
  criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- O pedido sobrevive à exclusão da conta (nota fiscal, contabilidade).
  FOREIGN KEY (cliente_id) REFERENCES cliente (id) ON DELETE SET NULL
);

-- Para onde vão os dados de quem exclui a conta.
CREATE TABLE cliente_excluido (
  id            INT UNSIGNED PRIMARY KEY,
  nome          VARCHAR(120) NOT NULL,
  email         VARCHAR(120) NOT NULL,
  cpf           CHAR(11) NOT NULL,
  criado_em     DATETIME NOT NULL,
  pedidos       INT UNSIGNED NOT NULL,
  total_gasto   DECIMAL(12, 2) NOT NULL,
  excluido_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  excluido_por  VARCHAR(100) NOT NULL
);

-- Colaboradores da loja e o piso salarial de cada cargo.
CREATE TABLE cargo (
  id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome   VARCHAR(60) NOT NULL UNIQUE,
  piso   DECIMAL(10, 2) NOT NULL,
  CONSTRAINT ck_cargo_piso CHECK (piso > 0)
);

CREATE TABLE colaborador (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome          VARCHAR(120) NOT NULL,
  cargo_id      INT UNSIGNED NOT NULL,
  salario_base  DECIMAL(10, 2),
  admitido_em   DATE NOT NULL DEFAULT (CURRENT_DATE),
  FOREIGN KEY (cargo_id) REFERENCES cargo (id)
);

CREATE TABLE historico_salario (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  colaborador_id  INT UNSIGNED NOT NULL,
  salario_antigo  DECIMAL(10, 2),
  salario_novo    DECIMAL(10, 2) NOT NULL,
  motivo          ENUM('admissao', 'reajuste', 'troca_de_cargo') NOT NULL,
  alterado_em     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  alterado_por    VARCHAR(100) NOT NULL,
  FOREIGN KEY (colaborador_id) REFERENCES colaborador (id) ON DELETE CASCADE
);

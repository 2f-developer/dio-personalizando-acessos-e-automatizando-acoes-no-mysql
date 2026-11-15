# Views, permissões e gatilhos no MySQL

Desafio "Personalizando Acessos e Automatizando Ações no MySQL", da formação SQL Database Specialist da DIO. São duas partes:

1. **Views e permissões** no banco COMPANY: cinco visões pedidas no enunciado e contas de usuário que enxergam só o que o perfil delas permite;
2. **Gatilhos** num e-commerce: guardar os dados de quem exclui a conta (`BEFORE DELETE`) e controlar a admissão e o salário base dos colaboradores (`BEFORE INSERT`/`BEFORE UPDATE`).

Tudo roda num MySQL 8 de verdade, inclusive o teste de permissões, que faz login com cada usuário.

## Parte 1: views

Em `sql/company/03_views.sql`:

| View | Responde |
| --- | --- |
| `vw_empregados_por_depto_local` | número de empregados por departamento e localidade |
| `vw_departamentos_gerentes` | departamentos e seus gerentes |
| `vw_projetos_empregados` | empregados e horas por projeto (ordene por `empregados DESC` para ver os maiores) |
| `vw_projetos_departamentos_gerentes` | projetos, departamentos e gerentes |
| `vw_empregados_com_dependentes` | quem tem dependentes, quantos e se é gerente |
| `vw_diretorio_empregados` | nome e sexo dos colegas, sem salário, endereço ou departamento |

A ordenação dos "projetos com maior número de empregados" fica na consulta, e não dentro da view, porque o MySQL não garante a ordem de uma view usada dentro de outra consulta.

## Parte 1: permissões

Em `sql/company/04_permissoes.sql`. Usei **roles** do MySQL 8: as permissões ficam no papel, e o usuário só recebe o papel.

- `company_gerencia` → usuário `gerente`: lê todas as views, inclusive departamentos e gerentes;
- `company_funcionario` → usuário `funcionario`: lê só o diretório de colegas e a alocação em projetos. Não enxerga departamentos nem gerentes, como pede o enunciado.

Nenhum dos dois acessa as tabelas diretamente, só as views. As senhas no script são de exemplo, para estudo.

## Parte 2: gatilhos

Em `sql/ecommerce/02_gatilhos.sql`:

**`BEFORE DELETE` em `cliente`.** Quando alguém exclui a conta, os dados vão para `cliente_excluido`, junto com quantos pedidos a pessoa fez, quanto gastou, quando e por qual usuário do banco a exclusão foi feita. Os pedidos continuam no banco, com o cliente em `NULL`, porque nota fiscal e contabilidade não podem sumir com a conta.

**`BEFORE INSERT` em `colaborador`.** Novo colaborador sem salário informado entra com o piso do cargo. Se o salário vier abaixo do piso, a inserção é recusada. Um `AFTER INSERT` registra a admissão no histórico.

**`BEFORE UPDATE` em `colaborador`.** Toda mudança de salário base ou de cargo passa por aqui. Redução de salário é recusada; promoção para um cargo de piso maior leva o salário até o piso; e cada mudança vai para `historico_salario` com o valor antigo, o novo e o motivo (`reajuste` ou `troca_de_cargo`). Alterar só o nome não gera histórico.

`sql/ecommerce/03_exemplos.sql` mostra os gatilhos em ação: admissões, um reajuste de 8%, uma promoção e uma conta excluída.

## Rodando

```bash
MYSQL_ROOT_PWD=suasenha ./testar.sh -h 127.0.0.1
```

Os argumentos são as opções de conexão do cliente `mysql` (sem usuário). O script recria os bancos, aplica views, permissões e gatilhos, roda `tests/verificacoes.sql` (respostas das views e comportamento dos gatilhos) e, por fim, faz login como `gerente` e como `funcionario` para conferir o que cada um consegue ou não ler. O GitHub Actions faz tudo isso num MySQL 8 a cada push.

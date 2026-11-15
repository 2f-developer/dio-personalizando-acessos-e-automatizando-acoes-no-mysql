#!/usr/bin/env bash
# Recria os bancos, views, permissões e gatilhos, roda as verificações e testa o
# acesso de cada usuário fazendo login com ele.
# Argumentos: opções de conexão do cliente mysql, sem usuário (ex.: -h 127.0.0.1).
# A senha do root vem de MYSQL_ROOT_PWD (vazia se não definida).
set -euo pipefail
cd "$(dirname "$0")"

como() {  # como USUARIO SENHA [args do mysql...]
  local usuario=$1 senha=$2; shift 2
  MYSQL_PWD=$senha mysql --default-character-set=utf8mb4 -u "$usuario" "$@"
}
CONEXAO=("$@")

for arquivo in sql/company/0*.sql sql/ecommerce/0*.sql tests/verificacoes.sql; do
  echo "== $arquivo"
  if ! saida=$(como root "${MYSQL_ROOT_PWD:-}" "${CONEXAO[@]}" < "$arquivo" 2>&1); then
    echo "$saida"; exit 1
  fi
  grep -E '^ok|passaram' <<< "$saida" || true
done

echo "== permissões (login com cada usuário)"
pode() {
  if como "$1" "$2" "${CONEXAO[@]}" company -e "SELECT 1 FROM $3 LIMIT 1" >/dev/null 2>&1; then
    echo "ok  $1 lê $3"
  else
    echo "FALHOU: $1 deveria ler $3"; exit 1
  fi
}
nao_pode() {
  if como "$1" "$2" "${CONEXAO[@]}" company -e "SELECT 1 FROM $3 LIMIT 1" >/dev/null 2>&1; then
    echo "FALHOU: $1 não deveria ler $3"; exit 1
  else
    echo "ok  $1 não lê $3"
  fi
}
pode gerente 'Gerente#2026' vw_departamentos_gerentes
pode gerente 'Gerente#2026' vw_empregados_por_depto_local
nao_pode gerente 'Gerente#2026' employee
pode funcionario 'Funcionario#2026' vw_diretorio_empregados
nao_pode funcionario 'Funcionario#2026' vw_departamentos_gerentes
nao_pode funcionario 'Funcionario#2026' vw_projetos_departamentos_gerentes
nao_pode funcionario 'Funcionario#2026' employee
echo "permissões conferidas"

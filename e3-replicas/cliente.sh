#!/bin/sh
# Escreve o nome de uma replica que respondeu ou INDISPONIVEL.
# O tempo total das tentativas deve permanecer abaixo de 5 segundos.

for entrada in \
  "10.0.20.21:replica1" \
  "10.0.20.22:replica2" \
  "10.0.20.23:replica3"
do
  ip=${entrada%%:*}
  nome=${entrada#*:}

  resposta=$(curl -fsS --max-time 1 "http://$ip:8080/" 2>/dev/null) || resposta=""

  if [ "$resposta" = "$nome" ]; then
    printf '%s\n' "$nome"
    exit 0
  fi
done

printf '%s\n' "INDISPONIVEL"
exit 1

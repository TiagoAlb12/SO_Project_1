#!/bin/bash

#Criar variaveis para definir as opcoes default
reverse=false
alphabetical=false

#Analise de todas opcoes que podemos passar na linha de comando (opcoes de ordenacao)
while getopts ":ra" option; do
  case "${option}" in
    r)
      reverse=true
      ;;
    a)
      alphabetical=true
      ;;
    \?)
      echo "Opção inválida: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "A opção -$OPTARG requer um argumento." >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

#Verificar se passamos dois ficheiros nos argumentos
if [ "$#" -ne 2 ]; then
    echo "Por favor, forneça dois ficheiros para comparar."
    exit 1
fi

file1="$1"
file2="$2"

#Verificar se os ficheiros passados existem
if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
    echo "Os ficheiros especificados não existem."
    exit 1
fi

#Ler o conteudo dos ficheiros e armazenar em arrays
mapfile -t file1_array < <(grep -v '^$' "$file1" | tail -n +3)
mapfile -t file2_array < <(grep -v '^$' "$file2" | tail -n +3)

declare -A size_mapping

#Iterar sobre as linhas dos arrays file1_array e file2_array
for line in "${file1_array[@]}" "${file2_array[@]}"; do
    size=$(echo "$line" | awk '{print $1}')
    filename=$(echo "$line" | cut -f2- -d$'\t')
    size_mapping["$filename"]+="$size "
done

#Comparar os arrays
for line in "${!size_mapping[@]}"; do
    sizes=(${size_mapping["$line"]})
    size1="${sizes[0]}"
    size2="${sizes[1]}"

    #Calcular a diferenca de tamanhos (entre os diferentes ficheiros)
    size_diff=$((size2 - size1))

    #Se nao temos correspondencia no primeiro arquivo, entao ha uma adicao de um diretorio
    if [ -z "$size1" ]; then
        echo -e "$size_diff\t$line\tNEW"
    #Se nao temos correspondencia no segundo arquivo, entao ha uma remocao de um diretorio
    elif [ -z "$size2" ]; then
        echo -e "$size_diff\t$line\tREMOVED"
    else
        #Imprimir a diferenca dos tamanhos
        echo -e "$size_diff\t$line"
    fi
done | (sort -k1,1nr) | ($alphabetical && sort -k2 || cat) | ($reverse && tac || cat)

#!/bin/bash

# Definir as opções padrão
reverse=false
alphabetical=false

# Processar as opções de linha de comando
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

# Verificar se são passados dois arquivos como argumentos
if [ "$#" -ne 2 ]; then
    echo "Por favor, forneça dois arquivos para comparar."
    exit 1
fi

file1="$1"
file2="$2"

# Verificar se os arquivos existem
if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
    echo "Os arquivos especificados não existem."
    exit 1
fi

# Ler o conteúdo dos arquivos e armazenar em arrays
mapfile -t file1_array < <(grep -v '^$' "$file1" | tail -n +3)
mapfile -t file2_array < <(grep -v '^$' "$file2" | tail -n +3)

declare -A size_mapping

# Criar um mapeamento do tamanho do arquivo para o seu nome
for line in "${file1_array[@]}" "${file2_array[@]}"; do
    size=$(echo "$line" | awk '{print $1}')
    filename=$(echo "$line" | cut -f2- -d$'\t')
    size_mapping["$filename"]+="$size "
done

# Comparar os arrays e imprimir conforme o formato desejado
for line in "${!size_mapping[@]}"; do
    sizes=(${size_mapping["$line"]})
    size1="${sizes[0]}"
    size2="${sizes[1]}"

    # Se não há correspondência no primeiro arquivo, então é uma adição
    if [ -z "$size1" ]; then
        echo -e "0\t$line\tNEW"
    # Se não há correspondência no segundo arquivo, então é uma remoção
    elif [ -z "$size2" ]; then
        echo -e "0\t$line\tREMOVED"
    else
        # Calcular a diferença real de tamanhos
        size_diff=$((size2 - size1))

        # Imprimir a diferença real de tamanho
        echo -e "$size_diff\t$line"
    fi
done | (sort -k1,1nr) | ($alphabetical && sort -k2 || cat) | ($reverse && tac || cat)
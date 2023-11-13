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
    echo "Por favor, forneça dois ficheiros para comparar."
    exit 1
fi

file_new="$1"
file_old="$2"

# Verificar se os arquivos existem
if [ ! -f "$file_new" ] || [ ! -f "$file_old" ]; then
    echo "Os ficheiros especificados não existem."
    exit 1
fi

# Ler o conteúdo dos arquivos e armazenar em arrays
mapfile -t file_new_array < <(grep -v '^$' "$file_new" | tail -n +3)
mapfile -t file_old_array < <(grep -v '^$' "$file_old" | tail -n +3)

declare -A size_new_mapping
declare -A size_old_mapping
declare -A dirs

# Criar um mapeamento do tamanho do arquivo para o seu nome
for line in "${file_new_array[@]}"; do
    size=$(echo "$line" | awk '{print $1}')
    dirname=$(echo "$line" | cut -f2- -d$'\t')
    size_new_mapping["$dirname"]="$size"
done


for line in "${file_old_array[@]}"; do
    size=$(echo "$line" | awk '{print $1}')
    dirname=$(echo "$line" | cut -f2- -d$'\t')
    size_old_mapping["$dirname"]="$size"
done

for dir in "${!size_new_mapping[@]}" "${!size_old_mapping[@]}"; do
    dirs["$dir"]=0
done

# Comparar os arrays e imprimir conforme o formato desejado
for dir in "${!dirs[@]}"; do
    size_new="${size_new_mapping["$dir"]}"
    size_old="${size_old_mapping["$dir"]}"

    # Se não há correspondência no primeiro arquivo, então é uma adição
    if [ -z "$size_old" ]; then
        echo -e "$size_new\t$dir\tNEW"
    # Se não há correspondência no segundo arquivo, então é uma remoção
    elif [ -z "$size_new" ]; then
        echo -e "-$size_old\t$dir\tREMOVED"
    else
        # Calcular a diferença real de tamanhos
        size_diff=$((size_old - size_new))

        # Imprimir a diferença real de tamanho
        echo -e "$size_diff\t$dir"
    fi
done | (sort -k1,1nr) | ($alphabetical && sort -k2 || cat) | ($reverse && tac || cat)

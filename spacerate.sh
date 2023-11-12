#!/bin/bash

#opções padrão por causa do -a e do -r
reverse=false
alphabetical=false

#opções na linha do comando
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
      echo "A opção -$OPTARG requer um argumento" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

#verificação se são passados dois arquivos para comparar
if [ "$#" -ne 2 ]; then
    echo "Por favor forneça dois arquivos para comparar"
    exit 1
fi

file1="$1" #isto é o ficheiro 1
file2="$2" #isto é o ficheiro 2

#verificação se os arquivos existem
if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
    echo "Os arquivos não existem"
    exit 1
fi

#ler o conteudo dos ficheiros e armazenar em arrays
mapfile -t file1_array < <(grep -v '^$' "$file1" | tail -n +3)
mapfile -t file2_array < <(grep -v '^$' "$file2" | tail -n +3)

declare -A size_mapping

#mapeamento do tamanho do arquivo para o seu nome
for line in "${file1_array[@]}" "${file2_array[@]}"; do
    size=$(echo "$line" | awk '{print $1}')
    filename=$(echo "$line" | cut -f2- -d$'\t')
    size_mapping["$filename"]+="$size "
done

#comparar os arrays e imprimir 
for line in "${!size_mapping[@]}"; do
    sizes=(${size_mapping["$line"]})
    size1="${sizes[0]}"
    size2="${sizes[1]}"

    #diferença real de tamanhos
    size_diff=$((size2 - size1))

    #não havendo correspondência no primeiro arquivo ha uma adição do ficheiro
    if [ -z "$size1" ]; then
        echo -e "$size_diff\t$line\tNEW"
    #não havendo correspondência no segundo arquivo ha uma remoção do ficheiro
    elif [ -z "$size2" ]; then
        echo -e "$size_diff\t$line\tREMOVED"
    else
        #imprimir a diferença dos tamanhos
        echo -e "$size_diff\t$line"
    fi
done | (sort -k1,1nr) | ($alphabetical && sort -k2 || cat) | ($reverse && tac || cat)
#!/bin/bash

# Verificar se são passados dois arquivos como argumentos
if [ "$#" -ne 2 ]; then
    echo "Por favor, forneça dois arquivos para comparar."
    exit 1
fi

# Armazenar os nomes dos arquivos passados como argumentos
file1="$1"
file2="$2"

# Verificar se os arquivos existem
if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
    echo "Os arquivos especificados não existem."
    exit 1
fi

# Imprimir o cabeçalho
echo "SIZE NAME"

# Ler o conteúdo dos arquivos, ignorando a primeira linha, e armazenar em arrays
mapfile -t file1_array < <(tail -n +2 "$file1")
mapfile -t file2_array < <(tail -n +2 "$file2")

declare -A size_mapping

# Criar um mapeamento do tamanho do arquivo para o seu nome
for line in "${file1_array[@]}" "${file2_array[@]}"; do
    size=$(echo "$line" | awk '{print $1}')
    filename=$(echo "$line" | awk '{$1=""; print $0}')
    size_mapping["$filename"]="$size"
done

# Comparar os arrays e imprimir conforme o formato desejado
for line in "${!size_mapping[@]}"; do
    if [[ -z ${size_mapping[$line]} ]]; then
        # Verifica se o diretório não existe no segundo arquivo, então é uma remoção ou está corrompido
        if [ ! -e "$line" ]; then
            echo "0 $line REMOVED"
        else
            echo "0 $line"
        fi
    elif [[ -z ${size_mapping[$line]} ]]; then
        # Se não há correspondência no primeiro arquivo, então é uma adição
        if [ ! -e "$line" ]; then
            echo "0 $line NEW"
        fi
    else
        # Se houver correspondência em ambos os arquivos, verificar a diferença de tamanho
        size1=${size_mapping[$line]}
        size2=${size_mapping[$line]}

        size_diff=$((size2 - size1))
        
        # Imprimir de acordo com o tamanho para identificar alterações ou arquivos inalterados
        if [ "$size_diff" -eq 0 ]; then
            echo "$size1 $line"
        else
            echo "$size_diff $line"
        fi
    fi
done

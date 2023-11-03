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

# Realizar a comparação entre os arquivos e mostrar a evolução do espaço ocupado
echo "SIZE NAME"

# Comparar os diretórios presentes em ambos os arquivos e mostrar a diferença no espaço ocupado
diff <(grep -v '^-0' "$file1" | sed 's/NEW//g' | sort -k2) <(grep -v '^0' "$file2" | sed 's/REMOVED//g' | sort -k2) | grep '^> ' | sed 's/^> //'

# Verificar diretórios que estão apenas em um dos arquivos e mostrá-los como "NEW" ou "REMOVED"
comm -3 <(grep -v '^0' "$file1" | sort -k2) <(grep -v '^0' "$file2" | sort -k2) | sed 's/\t/ /'
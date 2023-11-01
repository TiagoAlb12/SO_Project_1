#!/bin/bash

#Mensagem de erro caso use uma opçao que nao esta considerada
function erro {
  echo "ERRO! Opção inválida. Tente novamente!"
  exit 1
}

#Variaveis com as opçoes default
regex=".*"  #A expressão regular começa vazia (abrange todos os ficheiros)
data="0"  #-d
size_min="0" #Tamanho minimo estipulado como default
sort_option="-k1,1nr"  #Inicialmente, a ordenaçao e feita do maior para o menor (em termos de armazenamento)
limit_lines="0" #Inicializar com zero

#Todos os argumentos que passamos na linha de comandos
all_args="$@"

#Filtrar os argumentos que correspondem a diretórios
correct_dir=()   #Array para armazenar os argumentos que correspondem a diretorios
for arg in "$@"; do   #Iterar sobre todos os argumentos passados  
  if [ -d "$arg" ]; then  #Verificar se e um diretorio valido
    correct_dir+=("$arg")  #Se for um diretorio valido, o argumento e adicionado ao array correct_dir
  fi
done

#Todas as opçoes que podemos passar na linha de comando
reverse_sort="false"  #Variavel que criei para controlar o reverse (-r)
while getopts ":n:d:s:l:ra" option; do
  case "$option" in
    n) 
      regex="$OPTARG" ;;
    d) 
      #Verificar se o formato da data que passamos como argumento tem o formato correto (Ex: "Sep 10 10:00")
      if date -d "$OPTARG" >/dev/null 2>&1; then
        data="$OPTARG"
      else
        echo "ERRO: Formato incorreto da data."
        exit 1
      fi
      ;;
    s) 
      size_min="$OPTARG" ;;
    r) 
      sort_option="-k1,1n" 
      reverse_sort="true" ;;
    a) 
      sort_option="-k2,2" ;;
    l) 
      limit_lines="$OPTARG" ;;
    ?) 
      erro ;;
  esac
done

#Funçao que lista os diretorios que contem arquivos que correspondem as expressoes regulares que escolhermos
function diretoriosPretendidos {
  #$1" -> diretorio
  if [ "$data" != "0" ]; then   #Opçao default que tenho para a data (data="0")
    #Se a opçao -d foi fornecida, usamos o -not -newermt para filtrar consoante a data de modificaçao do arquivo, conforme e pedido
    find "$1" -type f -not -newermt "$data" -exec dirname {} \; | sort -u   # -> poderia usar tambem o -grep
  else
    #Se a opçao -d nao foi fornecida, nao a podemos considerar para nao perdermos diretórios
    find "$1" -type f -exec dirname {} \; | sort -u
  fi
}

#Funçao para calcular o espaço ocupado por ficheiro do tipo da expressao regular que passo como argumento (em bytes)
function calcularEspacoArquivos {
  local counter=0

  #Iterar pelos diretorios obtidos da funçao diretoriosPretendidos
  diretoriosPretendidos "$1" | while read -r sub_dir; do
    #Quando mudo de diretorio, defino a variavel total_size em zero
    total_size=0
    has_files=false  #Usar para verificar se o subdiretorio contem arquivos que correspondem a expressao regular

    #Iterar pelos arquivos no subdiretorio que correspondem a expressao regular
    for file in "$sub_dir"/*; do
      if [ -f "$file" ] && [[ "$file" =~ $regex ]]; then    #Verificar se e um arquivo valido e se corresponde a expressao regular
        du_result=$(du -b "$file")  #Usar du -b para obter o tamanho em bytes
        file_size=$(echo "$du_result" | awk '{print $1}')
        total_size=$((total_size + file_size))  #Adicionar o tamanho do arquivo ao total_size
        has_files=true
      fi
    done

    #Verificar se o subdiretorio contem arquivos que correspondem a expressao regular
    if [ "$has_files" = false ]; then
      total_size=0
    fi

    #Verificar se o diretorio pode ser acessado (por motivos de permissao, por exemplo)
    if [ -x "$sub_dir" ]; then
      #Se o tamanho total for maior ou igual a size_min, imprimo o tamanho total
      if [ "$total_size" -ge "$size_min" ]; then
        echo -e "$total_size\t$sub_dir"
        counter=$((counter+1))
      else
        echo -e "0\t$sub_dir"
      fi
      
    else    #Caso o diretorio nao possa ser acessado
      echo -e "NA\t$sub_dir"
    fi

    if [ "$limit_lines" -gt 0 ] && [ "$counter" -ge "$limit_lines" ]; then
      break  #Se o contador atingir o limite, sair do loop
    fi
  done
}

#Loop pelos diretorios validos contidos no array correct_dir
for dir in "${correct_dir[@]}"; do
  echo -e "\nEstamos no diretório -> $dir\n"
  echo -e "SIZE\tNAME\t$(date +%Y%m%d)    $all_args" #Cabeçalho

  #Para controlar quando usamos o -r -a -n; se usarmos o -r:"$reverse_sort" == "true" e se usarmos o -a:"$sort_option" == "-k2,2"
  if [ "$reverse_sort" == "true" ] && [ "$sort_option" == "-k2,2" ]; then
    #Se a opção -r foi usada em conjunto com -a -n, reverta a ordem de classificaçao
    calcularEspacoArquivos "$dir" | sort -t$'\t' $sort_option -r
  else  #Caso contrario, ou seja, quando nao usamos o -r -a -n
    calcularEspacoArquivos "$dir" | sort -t$'\t' $sort_option
  fi
  echo "======"
done

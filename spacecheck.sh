#!/bin/bash

#Mensagem de erro caso usemos uma opçao que nao esta considerada no getops
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

# Filtrar os argumentos que correspondem a diretórios
correct_dir=()   # Array para armazenar os argumentos que correspondem a diretorios
for arg in "$@"; do   # Iterar sobre todos os argumentos passados  
  if [ -d "$arg" ]; then  # Verificar se é um diretório válido
    correct_dir+=("$arg")  # Se for um diretório válido, o argumento é adicionado ao array correct_dir
  fi
done

#Analise de todas opçoes que podemos passar na linha de comando
reverse_sort="false"  #Variavel que criei para controlar o reverse (-r)
while getopts ":n:d:s:l:ra" option; do
  case "$option" in
    n) 
      regex="$OPTARG" ;;
    d) #Verificar se o formato da data que passamos como argumento tem o formato correto (Ex: "Sep 10 10:00")
      if [[ "$OPTARG" =~ ^[A-Z][a-z]{2}\ [0-9]{1,2}\ [0-9]{2}:[0-9]{2}$ ]]; then
        data="$OPTARG"
      else
        echo "ERRO: Formato incorreto da data. Exemplo: 'Sep 10 10:00'."
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
    l) #Validar o argumento da opçao -l, se e um numero inteiro positivo
      if [[ "$OPTARG" =~ ^[1-9][0-9]*$ ]]; then
        limit_lines="$OPTARG"
      else
        echo "ERRO: O argumento da opção -l deve ser um número inteiro positivo."
        exit 1
      fi
      ;;
    ?) 
      erro ;;
  esac
done

#Funçao que lista os diretorios que contem arquivos que correspondem as expressoes regulares que escolhermos
function diretoriosPretendidos {
  if [ "$data" != "0" ]; then   #Opçao default que tenho para a data (data="0")
    #Se a opçao -d foi fornecida, usamos o -not -newermt para filtrar consoante a data de modificaçao do arquivo, conforme e pedido
    find "$1" -type d -not -newermt "$data" 2>/dev/null | sort -u
  else
    #Se a opçao -d nao foi fornecida, nao a podemos considerar para nao perdermos diretórios
    find "$1" -type d 2>/dev/null | sort -u
  fi
}

#Funçao para calcular o espaço ocupado por ficheiro do tipo da expressao regular que passo como argumento (em bytes)
function calcularEspacoArquivos {
  local counter=0

  #Iterar pelos diretorios obtidos da funçao diretoriosPretendidos
  diretoriosPretendidos "$1" | while read -r sub_dir; do
    #Quando mudo de diretorio, defino a variavel total_size em zero
    total_size=0

    if [ ! -r "$sub_dir" ] || [ ! -x "$sub_dir" ]; then
    total_size="NA"
    else
      #Iterar pelos arquivos no subdiretorio que correspondem a expressao regular
      for file in "$sub_dir"/*; do
        if [ -f "$file" ] && [[ "$file" =~ $regex ]]; then    #Verificar se e um arquivo valido e se corresponde a expressao regular
          du_result=$(du -b "$file")  #du -b para obter o tamanho em bytes
          file_size=$(echo "$du_result" | awk '{print $1}')
          if [ "$?" -ne 0 ]; then
            total_size="NA"
            break #Se houver algum erro, sair do loop, o resultado sera NA
          elif [ "$file_size" -ge "$size_min" ]; then
            total_size=$((total_size + file_size))  #Adicionar o tamanho do arquivo ao total_size
          fi
        fi
      done
    fi
    
    #Se o tamanho total for maior ou igual a size_min, imprimo o tamanho total
    echo -e "$total_size\t$sub_dir"
    counter=$((counter+1))

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
done

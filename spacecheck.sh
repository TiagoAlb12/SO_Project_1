#!/bin/bash

# Função que mostra o uso correto do script
function erro() {
  echo "ERRO! Opcao invalida. Tente novamente!"
  exit 1
}

# Variáveis com as opções default
regex=".*"  # Inicialmente, a expressão regular está vazia
data="0"  #-d
sizeM="0" #Tamanho minimo estipulado com default
sort_option="-k1,1nr"  # Inicialmente, ordenação do maior para o menor (em termos do armazenamento)
limit_lines="0" #Inicializar com zero

# Todos os argumentos que passo na linha de comandos
argumentos="$@"

# Retirar os argumentos que não correspondem a diretórios
direct_args=()   # array para armazenar os argumentos que correspondem a diretórios
for arg in "$@"; do   # Itera sobre todos os argumentos passados  
  if [ -d "$arg" ]; then  # Verificar se é um diretório válido
    direct_args+=("$arg")  # Se for um diretório válido, o argumento é adicionado ao array direct_args
  fi
done

# Avaliar todas as opções que passamos na linha de comando
reverse_sort="false"  # Variável para controlar a ordenação reversa
while getopts ":n:d:s:l:ra" option; do
  case "$option" in
    n) 
      regex="$OPTARG" ;;
    d) 
      #Verificar o formato da data que passamos como Verifica se a data tem o formato correto (Mês Dia Hora:Minuto)
      if date -d "$OPTARG" >/dev/null 2>&1; then  #Ex: "Sep 10 10:00"
        data="$OPTARG"
      else
        echo "ERRO: Formato de data incorreto."
        exit 1
      fi
      ;;
    s) 
      sizeM="$OPTARG" ;;
    r) 
      sort_option="-k1,1n" 
      reverse_sort="true" ;;
    a) 
      sort_option="-k2,2" ;;
    l) 
      limit_lines="$OPTARG" ;;
    ?) #Caso insira uma opção inválida
      erro ;;
  esac
done

#NOTA: usei este if na funçao abaixo porque perdia um diretorio quando nao usava o -d mas tinha '-not -newermt "$data"' no find
# Função para listar diretórios que contêm arquivos que correspondem à expressão regular que escolhermos
function diretoriosPretendidos {
  if [ "$data" != "0" ]; then   #opçao default que tenho para a data
    #Se a opção -d foi fornecida, use o -not -newermt para filtrar consoante data de modificação, conforme é pedido
    find "$1" -type f -regex "$regex" -not -newermt "$data" -exec dirname {} \; | sort -u #->poderia usar tambem o -grep
  else
    #Se a opção -d não foi fornecida, não a podemos considerar para nao perdermos diretorios
    find "$1" -type f -regex "$regex" -exec dirname {} \; | sort -u
  fi
}

# Função para calcular o espaço ocupado por diretórios em bytes
function calcularEspacoDiretorios {
  local counter=0
  while read -r dir; do
    du_result=$(du -s "$dir") 
    size=$(echo "$du_result" | awk '{print $1}')

    # Verificar se o tamanho do diretório, calculado acima, é maior que o passado como argumento
    if [ "$size" -ge "$sizeM" ]; then   #Caso nao use a opçao -s com os argumentos, o sizeM é zero
      echo -e "$size\t$dir"
      counter=$((counter+1))  # Incrementar o contador
    else
      echo -e "0\t$dir"
    fi

    if [ "$limit_lines" -gt 0 ] && [ "$counter" -ge "$limit_lines" ]; then
      break  # Se o contador atingir o limite, sair do loop
    fi
  done
}

# Loop pelos diretórios válidos contidos no array direct_args
for dir in "${direct_args[@]}"; do
  echo -e "\nEstamos no diretório -> $dir\n"
  echo -e "SIZE\tNAME\t$(date +%Y%m%d)    $argumentos" # Cabeçalho

  #Para controlar quando usamos o -r -a -n; se usarmos o -r:"$reverse_sort" == "true" e se usarmos o -a:"$sort_option" == "-k2,2"
  if [ "$reverse_sort" == "true" ] && [ "$sort_option" == "-k2,2" ]; then
    # Se a opção -r foi usada em conjunto com -a -n, reverta a ordem de classificação
    diretoriosPretendidos "$dir" | calcularEspacoDiretorios | sort -t$'\t' $sort_option -r
  else  #caso contrario, ou seja, quando nao usamos o -r -a -n
    diretoriosPretendidos "$dir" | calcularEspacoDiretorios | sort -t$'\t' $sort_option
  fi
  echo "======"
done

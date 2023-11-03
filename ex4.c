#include <stdio.h>
#include <math.h>

int main() {
    int n;

    // Solicitar ao usuário o número de linhas da tabela
    printf("Digite o número de linhas da tabela: ");
    scanf("%d", &n);

    // Imprimir o cabeçalho da tabela
    printf("Número | Quadrado | Raiz Quadrada\n");
    printf("-------|----------|--------------\n");

    // Gerar a tabela
    for (int i = 1; i <= n; i++) {
        double raiz = sqrt(i);
        printf("%6d | %8d | %12.4f\n", i, i * i, raiz);
    }

    return 0;
}

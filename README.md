# Minha pequena internet

Laboratório do trabalho semestral de **Redes e Sistemas Distribuídos** —
Prof. Me. Luiz Ricardo Mantovani da Silva.

Uma topologia só, que cresce ao longo do semestre: começa com duas redes que
não se falam e termina com um serviço replicado, roteamento que se refaz
sozinho e a demonstração de por que uma senha não deve viajar sem proteção.

Tudo roda no **Google Cloud Shell**, que é gratuito, não pede cartão de crédito
e dá a cada aluno uma máquina Linux com root só dela.

---

## Começando

Construa a imagem do laboratório — uma vez por sessão do Cloud Shell:

```bash
make base
```

Suba a topologia da primeira entrega:

```bash
make up E=1
```

Rode as provas:

```bash
make verificar E=1
```

`make verificar` **começa vermelho de propósito**. O laboratório vem
incompleto: o roteiro de verificação é o enunciado de verdade, e o trabalho é
levá-lo ao verde.

Enunciado de cada entrega em [`entregas/`](entregas/).

---

## As cinco entregas

| # | Semana | Tema | Vale |
|---|---|---|---|
| [E1](entregas/E1.md) | 6 | Dois segmentos e um serviço | 0,8 |
| [E2](entregas/E2.md) | 9 | O roteador e o encapsulamento | 1,4 |
| [E3](entregas/E3.md) | 11 | O serviço não pode cair | 1,2 |
| [E4](entregas/E4.md) | 12 | A rota se refaz sozinha | 1,2 |
| — | 14 | Apresentação | 1,4 |
| [E5](entregas/E5.md) | 13 | O pacote entrega o segredo · **Cartilha** | **2,0 (Extensão)** |

E1–E4 e a apresentação compõem os 6,0 de avaliação prática. E5 é a atividade
de extensão, com nota escalonada em 1,2 / 1,7 / 2,0.

---

## Regras do jogo

**A entrega é o repositório, nunca o ambiente.** A correção é feita clonando o
repositório do grupo numa Cloud Shell limpa e rodando `make up` e
`make verificar`. Se não subir lá, não entregou.

**Evidência é obrigatória.** `make evidencias E=<n>` grava a saída da
verificação; os `.pcap` das entregas 2 e 5 vão junto. Isso é versionado — nunca
apaguem a pasta `evidencias/`.

**Imagem pequena.** A máquina do Cloud Shell é efêmera e recicla o cache de
imagens: só a pasta pessoal (5 GB) sobrevive. Por isso a base é Alpine.

**Nada de varredura de rede.** Os termos de uso do Cloud Shell proíbem
explicitamente varredura, e a conta que descumprir é desligada. Todo o trabalho
aqui é captura passiva dentro da rede virtual do próprio grupo — o que é outra
coisa, e é permitido.

---

## Para o professor

Antes de liberar para a turma, uma vez, numa Cloud Shell limpa:

```bash
make autoteste
```

Confere as quatro coisas de que o laboratório depende e que documentação
nenhuma garante: criação de bridge com sub-rede própria, `tcpdump` com
`NET_RAW` efetivo, `net.ipv4.ip_forward` por contêiner, e o pacote `bird` no
Alpine (só a E4 depende dele).

### Botão "Abrir no Cloud Shell"

Para cada entrega, na página do trabalho:

```
https://shell.cloud.google.com/cloudshell/editor
  ?cloudshell_git_repo=https://github.com/LuizRMSilva1973/redes-lab
  &cloudshell_tutorial=entregas/E1.md
  &show=ide%2Cterminal
```

O aluno cai no terminal com o repositório clonado e o enunciado aberto como
roteiro guiado ao lado. Trocar `E1.md` pela entrega da vez.

O repositório precisa estar em **GitHub ou Bitbucket**, público.

### Correção

```bash
git clone <repo-do-grupo> && cd <repo> && make up E=2 && make verificar E=2
```

Os roteiros imprimem o valor observado em cada ponto, não só passou/falhou —
dá para corrigir lendo a saída.

---

## Entrega 1 — Plano de endereçamento

**Sub-redes usadas:**

| Segmento | Sub-rede | Máscara | Endereços totais | Hosts utilizáveis |
|---|---|---|---|---|
| A | `10.0.10.0/24` | 255.255.255.0 | 256 | 254 |
| B | `10.0.20.0/24` | 255.255.255.0 | 256 | 254 |

Uma `/24` reserva 8 bits para hosts (2⁸ = 256 endereços), mas **dois** desses
256 nunca podem ser atribuídos a uma máquina: o primeiro (`.0`) é o *endereço
de rede*, que identifica a sub-rede como um todo nas tabelas de roteamento —
não uma máquina dentro dela; o último (`.255`) é o *endereço de broadcast*,
usado para mandar um pacote a todos os hosts da sub-rede de uma vez, não a um
host específico. Por isso sobram 254 endereços utilizáveis por sub-rede
(256 − 2).

**Atribuição de endereços:**

| Máquina | Segmento | Endereço |
|---|---|---|
| `host-a1` | A | `10.0.10.10` |
| `host-a2` | A | `10.0.10.11` |
| `srv-a`   | A | `10.0.10.20` |
| `host-b1` | B | `10.0.20.10` |
| `host-b2` | B | `10.0.20.11` |

## Por que A não alcança B

Cada segmento é uma rede *bridge* própria e isolada do Docker
(`seg-a` e `seg-b`), e cada contêiner só tem uma interface de rede, conectada
a **um** desses dois segmentos — nunca aos dois ao mesmo tempo. Além disso, a
rota padrão de cada contêiner foi removida de propósito
(`ip route del default`).

Isso significa que, do ponto de vista de um host em A, simplesmente **não
existe rota** na tabela de roteamento para `10.0.20.0/24` — não é um
firewall bloqueando, é a ausência real de um caminho de camada 3 entre as
duas sub-redes. Por isso o erro que aparece é `Network is unreachable`: o
próprio kernel do host de origem já sabe, antes de mandar qualquer pacote,
que não tem como chegar lá.

Isso também explica por que o teste teria que provar as duas metades: se os
segmentos estivessem desligados ou os contêineres fora do ar, o ping também
falharia — só o par (funciona dentro do segmento **e** falha entre segmentos)
comprova que o isolamento é real, e não um efeito colateral de algo quebrado.

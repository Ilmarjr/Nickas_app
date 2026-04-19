<div align="center">
  <img src="https://raw.githubusercontent.com/tandpfun/skill-icons/main/icons/Flutter-Dark.svg" width="80" height="80" alt="Flutter icon" />
  <h1>Nickas App</h1>
  <p><b>Seu assistente inteligente de listas de compras e gestão financeira pessoal.</b></p>
</div>

<br/>

## 🎯 Sobre o Projeto

O **Nickas** é uma aplicação mobile focada em simplificar e otimizar a forma como você gerencia suas listas de supermercado e despesas. Muito mais do que um simples bloco de notas, o Nickas evolui para oferecer uma visão abrangente sobre seus hábitos de consumo financeiros — calculando totais de compras, agrupando históricos por data e ajudando você a economizar no fim do mês.

Construído sob uma arquitetura **offline-first**, o app garante que você possa criar, editar e visualizar seus dados de mercado mesmo sem internet (durante as compras), realizando a sincronização de forma transparente com o servidor quando houver conexão disponível.

---

## 🚀 Principais Funcionalidades

- **Listas Inteligentes:** Criação e gestão de listas de compras com adição rápida de itens.
- **Controle Financeiro:** Cálculo dinâmico e exato dos totais baseando-se nos valores das compras.
- **Modo Offline-First:** Tudo funciona localmente e sincroniza seus dados com a nuvem de forma assíncrona.
- **Histórico e Relatórios:** Comparativo de gastos recorrentes em diferentes datas.
- **Autenticação Segura:** Sistema de login com segurança baseada em token (JWT).
- **Suporte Regional:** Estruturado e bem configurado em Português local do Brasil.

---

## 🛠 Tecnologias Utilizadas

Este projeto adota boas práticas de desenvolvimento mobile, utilizando uma stack moderna e dividida:

**Frontend (Mobile)**
- **[Flutter](https://flutter.dev/):** Utilizado para entregar uma experiência fluida, reativa e de desempenho nativo.
- **Dart:** Linguagem base da interface mobile da aplicação.
- **Provider:** Usado para o eficiente gerenciamento de estado do ciclo de vida das listas e finanças.
- **Sqflite:** Banco de dados SQLite local, viabilizando todo o ecossistema e operações offline.

**Backend (API & Dados)**
- **[FastAPI](https://fastapi.tiangolo.com/):** Framework web escalável e rápida para construção da API em Python 3+.
- **SQLAlchemy:** Utilizado para as operações de persistência e validação no banco de dados do servidor.
- **PyJWT:** Gerenciamento da segurança e autenticação baseada em JSON Web Tokens para rotas privadas.

---

## ⚙️ Como Rodar e Testar Localmente

Para rodar o projeto em um ambiente de desenvolvimento local, siga o passo a passo abaixo.

### Pré-requisitos
- Pelo menos o **Flutter SDK** devidamente instalado na máquina.
- **Python 3.9+** caso planeje rodar e testar o repositório de backend na mesma máquina.
- Um emulador ativo (Android/iOS) ou um dispositivo físico conectado via porta USB e com modo de depuração ativado.

### 1. Clonando o Repositório

```bash
git clone https://github.com/SEU_USUARIO/Nickas_app.git
```

### 2. Configurando o Backend (API)

Caso deseje testar a integração do aplicativo mobile com todos os recursos habilitados:

```bash
cd Nickas_app/nickas_backend

# Utilize o virtualenv ambiente de execução padrão para o Python:
python -m venv venv

# Ative o VENV (Windows)
venv\Scripts\activate
# ou ative (Mac/Linux)
# source venv/bin/activate

# Instale os requisitos e levante os serviços:
pip install -r requirements.txt
uvicorn main:app --reload
```
A sua API agora deverá estar ouvindo por trás de interações no Host na porta 8000.

### 3. Rodando o Frontend (Aplicativo Mobile)

Deixe o servidor do Backend rodando no terminal anterior e abra uma nova tela/janela de terminal:

```bash
# Navegue a partir do root original:
cd Nickas_app/nickas_frontend

# Baixe as dependências com o gestor de código Pub
flutter pub get

# Inicie o projeto e rode na maquina local
flutter run
```

_**Dica:** É normal o primeiro carregamento da aplicação nativa demorar mais do que o comum no `flutter run`, pois ele precisará compilar usando o Gradle/Xcode; após isso, a experiência de código torna-se instantânea usando a técnica de Hot Reload._

---

## 🤝 Contribuindo

Fique à vontade para reportar pequenos bugs, abrir *Issues* relatando melhorias no uso de interface ou mesmo sugerir *Pull Requests* de impacto positivo no repositório inteiro!

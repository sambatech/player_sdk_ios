#SambaPlayer SDK para iOS

##Introdução
O SambaPlayer SDK facilita diversas etapas do desenvolvimento de aplicativos que trabalham com vídeo em iOS.

##Features
- Integração com serviços da Samba Tech (http://sambatech.com/): Samba Videos e STTM
- Vídeo em HLS e PROGRESSIVE
- VOD e Live
- DFP (https://www.google.com/dfp)

##Como usar?
Para utilizar o SambaPlayer SDK é necessário instalar o [CocoaPods](http://cocoapods.org).

Caso ainda não exista, crie um arquivo na raíz do projeto Xcode chamado `Podfile` e adicione o seguinte:
```
pod "SambaTechPlayerSDK", "~> 0.1"
```
Com o Xcode **fechado**, execute o comando:
```
$ pod install
```
Em seguida, abra seu projeto através do arquivo `SeuProjeto.xcworkspace` recém criado pelo CocoaPods.

##Carthage

Caso seu projeto possua dependências em Swift ou bibliotecas estáticas, utilize o [Carthage](https://github.com/Carthage/Carthage). Este é um utilitário responsável por compilar projetos do Github gerando frameworks binários.

Para instalá-lo, pode ser usado o [Homebrew](http://brew.sh/) através do seguinte comando:

```bash
$ brew update
$ brew install carthage
```

Caso ainda não exista, crie um arquivo na raíz do seu projeto chamado `Cartfile` e inclua:

```ogdl
github "SambaPlayerSDK" ~> 0.1
```

Basta executar `carthage update` para compilar o `SambaPlayerSDK.framework`. Em seguida, inclua-o arrastando para seu projeto Xcode.

##Outros

Há um comportamento [conhecido](https://github.com/CocoaPods/CocoaPods/wiki/Generate-ASCII-format-xcodeproj) em que o CocoaPods modifica o arquivo do projeto (*.xcodeproj/project.pbxproj) ao baixar as dependências convertendo-o de PList para XML, que pode causar conflito neste arquivo inteiro ao mesclá-lo.

Para mitigar este comportamento, basta instalar o utilitário [xcproj](https://github.com/0xced/xcproj) e executar `xcproj touch` na pasta do projeto, que o arquivo de projeto será revertido para PList.

##Suporte
Quaisquer perguntas, sugestões ou notificação de bugs, basta criar uma nova issue que responderemos assim que possível.

##Requisitos
- iOS 8.0+

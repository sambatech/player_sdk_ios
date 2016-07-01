#SambaPlayer SDK para iOS

##Introdução
O SambaPlayer SDK facilita diversas etapas do desenvolvimento de aplicativos que trabalham com vídeo em iOS.

##Features
- Integração com serviços da Samba Tech (http://sambatech.com/): Samba Videos e STTM
- Vídeo em HLS e PROGRESSIVE
- VOD e Live
- DFP (https://www.google.com/dfp)

##Como usar?
Para utilizar o SambaPlayer SDK é necessário instalar o [Carthage](https://github.com/Carthage/Carthage).

Este é um utilitário responsável por compilar projetos do Github gerando frameworks binários.

A instalação pode ser feita através do [Homebrew](http://brew.sh/) através do seguinte comando:

```bash
$ brew update
$ brew install carthage
```

Caso ainda não exista, crie um arquivo na raíz do seu projeto chamado `Cartfile` e inclua:

```ogdl
github "sambatech/player_sdk_ios"
```

Basta executar `carthage update` para compilar o `SambaPlayer.framework`. Em seguida, inclua-o arrastando para seu projeto Xcode:

![readme1](https://cloud.githubusercontent.com/assets/484062/16528649/85e947ce-3f94-11e6-8806-6020775d8d02.gif)

##Suporte
Quaisquer perguntas, sugestões ou notificação de bugs, basta criar uma nova issue que responderemos assim que possível.

##Requisitos
- iOS 8.0+


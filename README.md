# SambaPlayer SDK para iOS

## Introdução
O SambaPlayer SDK facilita diversas etapas do desenvolvimento de aplicativos que trabalham com vídeo em iOS.

## Features
- Integração com serviços da Samba Tech (http://sambatech.com/): Samba Videos e STTM
- Vídeo e Áudio em HLS e PROGRESSIVE
- VOD e Live
- DFP (https://www.google.com/dfp)

## Como usar?
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

Basta executar `carthage update` para gerar o `SambaPlayer.framework` e as demais dependências.

Em seguida, arraste os frameworks da pasta de saída (Carthage/Build/iOS/) para seu projeto Xcode:

![readme1](https://cloud.githubusercontent.com/assets/484062/16528649/85e947ce-3f94-11e6-8806-6020775d8d02.gif)

Efetue as seguintes configurações em *Target -> Build Settings*:

- Para funcionar `import`:
<br>*Packaging -> Defines Module -> __Yes__*
- Para localizar o framework em *compile time*:
<br>*Search Paths -> Framework Search Paths -> __${PROJECT_DIR}/Carthage/Build/iOS__*
- Frameworks com código em Swift precisam ser informados:
<br>*Build Options -> Embedded Content Contains Swift Code -> __Yes__*
- O processo de assinatura de aplicativos [é raso e não inclui as dependências](http://stackoverflow.com/a/17396143/3688598):
<br>*Code Signing -> Other Code Signing Flags -> __--deep__*
- Sugestão: para localizar o framework em *runtime* pode-se configurar o aplicativo para buscá-lo na pasta de frameworks compartilhados:
<br>*Linking -> Runpath Search Paths -> __@executable_path/SharedFrameworks__*

Finalmente, garanta que o framework será copiado para o bundle do aplicativo:

- Em *Target -> __Build Phases__*
- Clique no botão "+" (na área superior) -> *__New Copy Files Phase__*
- Escolha o local de destino ou *Destination -> __Shared Frameworks__* (sugestão acima)
- Inclua o SambaPlayer.framework à __lista__ (área inferior)

## Suporte
Quaisquer perguntas, sugestões ou notificações de bugs, basta criar uma [nova issue](https://github.com/sambatech/player_sdk_ios/issues/new) que responderemos assim que possível.

## Requisitos
- iOS 8.0+

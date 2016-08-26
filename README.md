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
github "sambatech/player_sdk_ios" ~> 0.1.5
#github "sambatech/player_sdk_ios" // para utilizar a versão mais atualizada
```

Basta executar `carthage update` para gerar o `SambaPlayer.framework` e as demais dependências.

Em seguida, arraste os frameworks da pasta de saída (Carthage/Build/iOS/) para seu projeto Xcode:

![readme1](https://cloud.githubusercontent.com/assets/484062/16528649/85e947ce-3f94-11e6-8806-6020775d8d02.gif)

Efetue as seguintes configurações em *Target -> Build Settings*:

- Frameworks com código em Swift precisam ser informados
<br>*Build Options -> Embedded Content Contains Swift Code -> __Yes__*
- O processo de assinatura de aplicativos [é "raso" e não abrange as dependências](http://stackoverflow.com/a/17396143/3688598)
<br>*Code Signing -> Other Code Signing Flags -> __--deep__*

E finalmente, em *Target -> Build Phases*:

- Garanta que o framework será copiado junto ao aplicativo
 1. Clique no botão "+" (na área superior) -> *__New Copy Files Phase__*
 1. Escolha o local de destino ou *Destination -> __Frameworks__*
 1. Inclua o SambaPlayer.framework à __lista__ (área inferior)

Será necessário permitir acesso à internet para o aplicativo, o que pode ser feito desabilitando os requerimentos de segurança do iOS para comunicações em HTTP (ATS - App Transport Security). Para isto, adicione o seguinte ao `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
	<key>NSAllowsArbitraryLoads</key>
	<true/>
</dict>
```

## Suporte
Qualquer pergunta, sugestão ou notificação de bugs, basta criar uma [nova issue](https://github.com/sambatech/player_sdk_ios/issues/new) que responderemos assim que possível.

## Requisitos
- iOS 8.0+

# SambaPlayer SDK para iOS

## Introdução
O SambaPlayer SDK facilita diversas etapas do desenvolvimento de aplicativos que trabalham com vídeo em iOS.

## Features
- Integração com serviços da Samba Tech (http://sambatech.com/): Samba Videos e STTM
- Vídeo e Áudio em HLS e PROGRESSIVE
- VOD e Live
- DFP (https://www.google.com/dfp)
- DRM ([Irdeto](http://irdeto.com/))

## Como usar?
Para utilizar o SambaPlayer SDK é necessário instalar o [Carthage](https://github.com/Carthage/Carthage).

Este é um utilitário responsável por compilar projetos do Github gerando frameworks binários.

A instalação pode ser feita através do [Homebrew](http://brew.sh/) através do seguinte comando:

```bash
$ brew update
$ brew install carthage
```

Caso ainda não exista, crie um arquivo na raíz do seu projeto chamado `Cartfile` e inclua o código abaixo para utilizar a versão mais atualizada:

```ogdl
github "sambatech/player_sdk_ios"
```
Caso deseje utilizar uma versão específica, use o seguinte (substitua o `x.x.x` pelo número da [versão desejada](https://github.com/sambatech/player_sdk_ios/releases)):
```ogdl
github "sambatech/player_sdk_ios" ~> x.x.x
```

Basta executar `carthage update` para gerar o `SambaPlayer.framework` e as demais dependências.

Em seguida, arraste ou copie os frameworks da pasta de saída (Carthage/Build/iOS/) para seu projeto Xcode. Caso o "GoogleInteractiveMediaAds.framework" e "GoogleCast.framework" não estejam na pasta "Carthage/Build/iOS", copiar os mesmos da pasta "Carthage/Checkouts/player_sdk_ios/Frameworks/" e adicionar ao projeto. 

![readme1](https://cloud.githubusercontent.com/assets/484062/16528649/85e947ce-3f94-11e6-8806-6020775d8d02.gif)

Efetue as seguintes configurações em *Target -> Build Settings*:

- Frameworks com código em Swift precisam ser informados
<br>(Xcode 7+)
<br>*Build Options -> Embedded Content Contains Swift Code -> __Yes__*
<br>(Xcode 8+)
<br>*Build Options -> Always Embed Swift Standard Libraries -> __Yes__*
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
## Requisitos
- iOS 9+
- Xcode 8+
- Swift 3.0 / Objective-C

## Suporte
Qualquer pergunta, sugestão ou notificação de bugs, basta criar uma [nova issue](https://github.com/sambatech/player_sdk_ios/issues/new) que responderemos assim que possível.

Para maiores informações, favor consultar nossa página [Wiki](https://github.com/sambatech/player_sdk_ios/wiki).

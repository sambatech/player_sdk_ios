#SambaPlayer SDK para iOS

##Introdução
O SambaPlayer SDK facilita diversas etapas do desenvolvimento de aplicativos que lidam com vídeo em iOS.

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
Em seguida, abra seu projeto através do arquivo `.xcworkspace` recém criado pelo Cococapods.

##Suporte
Quaisquer perguntas, sugestões ou bugs, basta criar uma nova issue que responderemos assim que possível.

##Requisitos
- iOS 6.1+

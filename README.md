# Player SDK iOS

Para testar o "hello world" resolvi configurar, instalar e rodar o KVVideoPlayer ( Objetive-C ) https://github.com/viki-org/VKVideoPlayer.

Instruções:
Instalar o Xcode: se não conseguir instalar pela app store pegue o .dmg aqui https://developer.apple.com/downloads/?name=Xcode%207.2 ( versão 7.2 )

Instalação do Cocoapods ( requisitos mínimos: Ruby 2.2+ e Rails 4+ instalados ):
`sudo gem install cocoapods`

Rodar:
Abrir o xCode e clicar no botão "play". Dica: clique em Window -> Scale -> 50% no emulador.

Ps: no caso desse projeto adicione a propriedade no VKVideoPlayer-Info.plist
```xml
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

Criando seu próprio projeto:

Abra o Xcode
- New Xcode Project
- Selecionar Objective C

Configurar o CocoaPods ( gerenciador de dependências ):
- Abra o projeto via terminal
- Digite `pod init`
- Abra o arquivo Podfile
- remova o comentário sobre a versão do ios ( `platform :ios, '8.0'` )
- adicione a dependência dentro do "do" exemplo:

```
target 'TestePlayer' do
  pod "VKVideoPlayer", "~> 0.1.1"
end
```

- Digite `pod install` para instalar as dependências do Podfile

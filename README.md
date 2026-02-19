# Su xii

Projeto de jogo em Godot 4.

## Estrutura do projeto

```
SuxiiGodotGame/
├── project.godot          # Configuração do projeto
├── scenes/                # Cenas (.tscn)
│   └── main_menu.tscn     # Menu principal
├── scripts/               # Scripts GDScript (.gd)
│   └── main_menu.gd
└── assets/                # Recursos (imagens, áudio, etc.)
    ├── textures/          # Imagens e texturas
    └── icons/             # Ícones (ex.: ícone do projeto)
```

### Onde colocar ficheiros novos

- **Novas cenas** → `scenes/` (pode criar subpastas, ex.: `scenes/levels/`, `scenes/ui/`)
- **Novos scripts** → `scripts/` (mesma estrutura que as cenas, se quiser)
- **Imagens, sprites, texturas** → `assets/textures/`
- **Áudio (música, SFX)** → criar `assets/audio/` e usar quando precisar
- **Fontes** → criar `assets/fonts/` quando precisar

Ao abrir o projeto no Godot, a cena principal é `scenes/main_menu.tscn`.

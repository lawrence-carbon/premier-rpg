# Premier RPG

Petit jeu **3D** en monde ouvert, fait avec **Godot 4**, pour apprendre les bases.

## Ce que tu as déjà

- un **héros 3D** (chevalier KayKit, avec épée et animations)
- une **grande carte** (400×400)
- un **village** en bois (maisons, taverne, puits, forge, église…)
- des **forêts**, **collines**, **rochers** et **montagnes**
- un léger **brouillard** au loin

> **Note :** on ne peut pas utiliser Link (personnage Nintendo, protégé).
> On utilise des assets **gratuits** KayKit (licence CC0), dans un style fantasy cohérent.

## Lancer le jeu

1. Ouvre un terminal dans ce dossier
2. Tape :

```bash
godot .
```

3. Dans Godot, clique sur le bouton **Play** (▶) en haut à droite  
   (ou touche **F5**)

## Touches

| Touche | Action |
|--------|--------|
| **Souris** | Tourner le regard (caméra derrière toi) |
| **Z / Q / S / D** (ou WASD / flèches) | Marcher (par rapport à ton regard) |
| **Espace** | Sauter |
| **Échap** | Libérer / reprendre la souris |

## Fichiers importants

| Fichier | Rôle |
|---------|------|
| `scenes/world.tscn` | Le monde (sol + joueur) |
| `scripts/decorate_world.gd` | Place village, forêts, collines… |
| `scenes/player.tscn` | Le héros + la caméra |
| `scripts/player.gd` | Le code qui fait bouger le héros |
| `assets/characters/Knight.glb` | Modèle 3D du héros (KayKit) |
| `assets/environment/` | Arbres, maisons, collines (KayKit) |
| `assets/weapons/sword_1handed.gltf` | Épée |
| `project.godot` | Réglages du projet |

## Crédits assets

- Personnage et armes : [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) (CC0)
- Décor médiéval : [KayKit Medieval Hexagon Pack](https://kaylousberg.itch.io/kaykit-medieval-hexagon) (CC0)

## Prochaines idées (quand tu seras prêt)

1. Donner un **nom** au héros
2. Ajouter un **objet** à ramasser
3. Faire parler un **villageois**
4. Ajouter un chemin / une rivière
5. Essayer un autre héros du pack (Rogue, Mage, Barbarian)

## Godot

Godot **4.7.1** est installé. La commande `godot` doit marcher dans le terminal.
Si ce n’est pas le cas, relance le terminal ou utilise :

```bash
~/.local/bin/godot .
```

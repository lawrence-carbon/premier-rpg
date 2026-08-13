# Premier RPG

Petit jeu **3D** en monde ouvert, fait avec **Godot 4**, pour apprendre les bases.

## Ce que tu as déjà

- un **héros 3D** (chevalier KayKit, avec épée et animations)
- une **grande carte** (400×400)
- un **village** en bois (maisons, taverne, puits, forge, église…)
- on peut **entrer** dans les bâtiments (**E** devant la porte)
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
| **Souris** | Tourner le regard |
| **Z / Q / S / D** (ou WASD / flèches) | Marcher |
| **Espace** | Sauter |
| **E** | Parler / défier / ouvrir / entrer-sortir |
| **N** | Parler à **Narek** (quand il te suit) |
| **F** | Attaquer |
| **X** | Ouvrir / fermer la carte |
| **Échap** | Menu (sauvegarder / charger / nouvelle partie) |

## Histoire (chapitres 1 → 4)

1. Intro → parle à **Alden** à Boisclair
2. Va à l'est : **Forêt d'Émeraude**
3. Vaincs les **gobelins** (F), puis parle à **Narek**
4. Suis la piste vers le **camp de Grak** (encore plus à l'est)
5. Affronte **Grak** et récupère la **clé**
6. Ouvre la **Crypte oubliée** (pied de la colline, au nord du camp)
7. Touche le **cristal** → vision des Sept Cristaux
8. Sors (**E** au panneau Sortie) → retourne voir **Alden**
9. Parle à **Mira** devant l'église
10. Va à l'**ouest** : **Col de l'Aube** → rencontre le **Voilé**

## Fichiers importants

| Fichier | Rôle |
|---------|------|
| `scenes/world.tscn` | Le monde (sol + joueur) |
| `scripts/decorate_world.gd` | Place village, forêts, collines… |
| `scenes/player.tscn` | Le héros + la caméra |
| `scripts/story.gd` | État de l'histoire (autoload) |
| `scripts/story_ui.gd` | Intro + dialogues + objectif |
| `scripts/villager.gd` | Villageois Alden |
| `scenes/ui/map_ui.tscn` | Radar + carte complète |
| `scripts/map_view.gd` | Dessin de la carte |
| `scripts/world_map_data.gd` | Lieux (Boisclair, forêts…) |

## Crédits assets

- Personnage et armes : [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) (CC0)
- Décor médiéval : [KayKit Medieval Hexagon Pack](https://kaylousberg.itch.io/kaykit-medieval-hexagon) (CC0)

## Prochaines idées (quand tu seras prêt)

1. Quitter la Vallée d'Aube vers un autre royaume
2. Deuxième Cristal Ancien
3. Création du héros (nom, apparence)
4. Essayer un autre modèle (Mage, Barbarian)

## Godot

Godot **4.7.1** est installé. La commande `godot` doit marcher dans le terminal.
Si ce n’est pas le cas, relance le terminal ou utilise :

```bash
~/.local/bin/godot .
```

# Directives pour les messages de commit

Un bon message de commit doit être descriptif et fournir le contexte des modifications effectuées. Cela facilite la compréhension et la révision des changements à l'avenir.

Voici quelques directives pour rédiger des messages de commit descriptifs :

- Commencez par un court résumé des modifications apportées dans le commit.

- Utilisez l'impératif pour le résumé, comme si vous donniez un ordre. Par exemple, « Add feature » au lieu de « Added feature ».

- Fournissez des détails supplémentaires dans le corps du message si nécessaire. Cela peut inclure la raison du changement, son impact, ou toute dépendance introduite ou supprimée.

- Maintenez le message à moins de 72 caractères par ligne pour garantir une lecture facile dans la sortie de l'historique Git.

Exemples de bons messages de commit :

- "Add authentication feature for user login"
- "Fix bug causing application to crash on startup"
- "Update documentation for API endpoints"

N'oubliez pas que rédiger des messages de commit descriptifs peut faire gagner du temps et éviter des frustrations à l'avenir, tout en aidant les autres à comprendre les modifications apportées au code.

## Types de messages de commit

Voici une liste plus complète de types de commit que vous pouvez utiliser :

`feat` : Ajout d'une nouvelle fonctionnalité au projet

```markdown
feat: Add multi-image upload support
```

`fix` : Correction d'un bug ou d'un problème dans le projet

```markdown
fix: Fix bug causing application to crash on startup
```

`docs` : Mise à jour de la documentation du projet

```markdown
docs: Update documentation for API endpoints
```

`style` : Changements cosmétiques ou de style (comme changer les couleurs ou formater le code)

```markdown
style: Update colors and formatting
```

`refactor` : Changements de code n'affectant pas le comportement du projet, mais améliorant sa qualité ou sa maintenance

```markdown
refactor: Remove unused code
```

`test` : Ajout ou modification de tests pour le projet

```markdown
test: Add tests for new feature
```

`chore` : Changements ne rentrant dans aucune autre catégorie, comme la mise à jour des dépendances ou la configuration du système de build

```markdown
chore: Update dependencies
```

`perf` : Amélioration des performances du projet

```markdown
perf: Improve performance of image processing
```

`security` : Traitement des problèmes de sécurité dans le projet

```markdown
security: Update dependencies to address security issues
```

`merge` : Fusion de branches dans le projet

```markdown
merge: Merge branch 'feature/branch-name' into develop
```

`revert` : Annulation d'un commit précédent

```markdown
revert: Revert "Add feature"
```

`build` : Changements affectant le système de build ou les dépendances du projet

```markdown
build: Update dependencies
```

`ci` : Changements affectant le système d'intégration continue (CI) du projet

```markdown
ci: Update CI configuration
```

`config` : Changements des fichiers de configuration du projet

```markdown
config: Update configuration files
```

`deploy` : Changements du processus de déploiement du projet

```markdown
deploy: Update deployment scripts
```

`init` : Création ou initialisation d'un nouveau dépôt ou projet

```markdown
init: Initialize project
```

`move` : Déplacement de fichiers ou de répertoires au sein du projet

```markdown
move: Move files to new directory
```

`rename` : Renommage de fichiers ou de répertoires au sein du projet

```markdown
rename: Rename files
```

`remove` : Suppression de fichiers ou de répertoires du projet

```markdown
remove: Remove files
```

`update` : Mise à jour du code, des dépendances ou d'autres composants du projet

```markdown
update: Update code
```

Ce ne sont que des exemples, et vous pouvez également créer vos propres types de commit personnalisés. Cependant, il est important de les utiliser de manière cohérente et d'écrire des messages clairs pour permettre aux autres de comprendre facilement les changements effectués.

**Important :** Si vous prévoyez d'utiliser un type de message de commit personnalisé autre que ceux listés ci-dessus, assurez-vous de l'ajouter à cette liste afin que les autres puissent également le comprendre. Créez une "pull request" pour l'ajouter à ce fichier.
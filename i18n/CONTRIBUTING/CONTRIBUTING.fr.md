# Contribuer aux Projets Hyprland de KooL 

Merci de votre intérêt pour la contribution aux Projets Hyprland de KooL ! Nous accueillons toutes les contributions, y compris les corrections de bugs, les améliorations de fonctionnalités, les mises à jour de la documentation et autres améliorations générales.

## Commencer

1. Forkez le dépôt de la branche de développement sur votre compte GitHub. Cela créera une copie de ce dépôt sur votre compte. Vous pouvez apporter des modifications à cette copie sans affecter le dépôt original.
  - Pour forker ce dépôt, cliquez sur le bouton **Fork** dans le coin supérieur droit de cette page ou cliquez [ici](https://github.com/JaKooLit/Hyprland-Dots/fork).
  - Assurez-vous de décocher « Copy the `main` branch only ». Cela copiera la branche de développement ainsi que les autres branches (s'il y en a).
 
2. Clonez votre dépôt forké sur votre machine locale.

  - Utilisez la commande suivante pour cloner votre dépôt forké sur votre machine locale :
     ```bash
     git clone --depth=1 -b development https://github.com/JaKooLit/Hyprland-Dots.git
     ```

3. Créez une nouvelle branche pour vos modifications.

  - Par exemple, pour créer une nouvelle branche nommée `nom-de-votre-branche`, utilisez la commande suivante :

     ```bash
     git checkout -b nom-de-votre-branche
     ```

4. Appliquez vos modifications et committez-les avec un message de commit descriptif.

  - Par exemple, pour commit vos modifications, utilisez la commande suivante et assurez-vous de suivre les [directives pour les messages de commit](../COMMIT_MESSAGE_GUIDELINES/COMMIT_MESSAGE_GUIDELINES.fr.md) :

     ```bash
     git commit -m "feat: add a new feature"
     ```

5. Poussez (push) vos modifications vers votre dépôt forké.

  - Par exemple, pour pousser vos modifications vers votre dépôt forké, utilisez la commande suivante :

     ```bash
     git push origin nom-de-votre-branche
     ```

6. Soumettez une **"pull request"** vers le dépôt de la branche de développement.
   - Par exemple, pour créer une pull request, suivez ces étapes :
     1. Allez sur votre dépôt forké.
     2. Cliquez sur le bouton **Compare & pull request** à côté de votre branche `nom-de-votre-branche`.
     3. Ajoutez un titre et une description pour votre pull request.
     4. Cliquez sur **Create pull request** et n'oubliez pas d'ajouter les labels pertinents en utilisant le [modèle de pull request](../../.github/PULL_REQUEST_TEMPLATE.md).

## Directives

- Respectez le style de code du projet.
- Mettez à jour la **documentation** si nécessaire.
- Ajoutez des tests si cela est applicable.
- Assurez-vous que tous les tests passent ou que l'ensemble soit entièrement testé avant de soumettre vos modifications.
- Gardez votre pull request ciblée et évitez d'inclure des changements non liés.
- N'oubliez pas de consulter les fichiers suivants avant de soumettre vos modifications :
  - [bug.yml](https://github.com/JaKooLit/Hyprland-Dots/blob/main/.github/ISSUE_TEMPLATE/bug.yml) - Utilisez ce modèle pour créer un rapport afin de nous aider à nous améliorer.
  - [feature.yml](https://github.com/JaKooLit/Hyprland-Dots/blob/main/.github/ISSUE_TEMPLATE/feature.yml) - Utilisez ce modèle pour suggérer une fonctionnalité pour ce projet.
  - [documentation-update.yml](https://github.com/JaKooLit/Hyprland-Dots/blob/main/.github/ISSUE_TEMPLATE/documentation-update.yml) - Utilisez ce modèle pour proposer une modification de la documentation.
  - [PULL_REQUEST_TEMPLATE.md](https://github.com/JaKooLit/Hyprland-Dots/blob/main/.github/PULL_REQUEST_TEMPLATE.md) - Utilisez ce modèle pour soumettre une pull request.
  - [COMMIT_MESSAGE_GUIDELINES.md](https://github.com/JaKooLit/Hyprland-Dots/blob/main/COMMIT_MESSAGE_GUIDELINES.md) - Lisez ce fichier pour en savoir plus sur les directives des messages de commit.
  - [CONTRIBUTING.md](https://github.com/JaKooLit/Hyprland-Dots/blob/main/CONTRIBUTING.md) - Lisez ce fichier pour en savoir plus sur les directives de contribution.
  - [LICENSE](https://github.com/JaKooLit/Hyprland-Dots/blob/main/LICENSE.md) - Lisez ce fichier pour en savoir plus sur la licence.
  - [README.md](https://github.com/JaKooLit/Hyprland-Dots/blob/main/README.md) - Lisez ce fichier pour en savoir plus sur le projet.

## Contact

Si vous avez des questions, n'hésitez pas à me contacter via les [Discussions GitHub](https://github.com/JaKooLit/Hyprland-Dots/discussions) ou [via le serveur Discord](https://discord.gg/kool-tech-world).
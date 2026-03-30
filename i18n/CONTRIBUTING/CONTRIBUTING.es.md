# Guía para Contribuir a KooL Hyprland Projects

[Ver versión en inglés](./CONTRIBUTING.md)

¡Gracias por tu interés en contribuir a KooL Hyprland Projects! Aceptamos todo tipo de contribuciones: correcciones de errores, nuevas características, mejoras en documentación y otras mejoras generales.

## Primeros pasos

1. Haz un fork del repositorio de la rama `development` en tu cuenta de GitHub. Así tendrás una copia sobre la cual trabajar sin afectar el repositorio original.
   - Para hacer fork, pulsa el botón **Fork** en la esquina superior derecha de esta página o haz clic [aquí](https://github.com/JaKooLit/Hyprland-Dots/fork).
   - Asegúrate de desmarcar la opción de copiar solo la rama `main`. Así se copiarán la rama `development` y otras ramas (si existen).

2. Clona tu repositorio bifurcado en tu equipo.

   - Usa el siguiente comando para clonar tu fork:

     ```bash
     git clone --depth=1 -b development https://github.com/JaKooLit/Hyprland-Dots.git
     ```

3. Crea una rama nueva para tus cambios.

   - Por ejemplo, para crear una rama llamada `tu-rama`, ejecuta:

     ```bash
     git checkout -b tu-rama
     ```

4. Realiza tus cambios y haz commit con un mensaje descriptivo.

   - Por ejemplo, para hacer commit de tus cambios, ejecuta (siguiendo la [guía de mensajes de commit](./COMMIT_MESSAGE_GUIDELINES.md)):

     ```bash
     git commit -m "feat: add a new feature"
     ```

5. Empuja tu rama a tu fork.

   ```bash
   git push origin tu-rama
   ```

6. Abre un **pull request** contra el repositorio en la rama `development`.
   - Pasos sugeridos:
     1. Ve a tu fork en GitHub.
     2. Haz clic en **Compare & pull request** junto a tu rama.
     3. Añade un título y una descripción.
     4. Pulsa **Create pull request** y recuerda añadir las etiquetas correspondientes usando la [plantilla de PR](https://github.com/JaKooLit/Hyprland-Dots/blob/main/.github/PULL_REQUEST_TEMPLATE.md).

## Directrices

- Sigue el estilo de código del proyecto.
- Actualiza la **documentación** si es necesario.
- Añade tests cuando corresponda.
- Asegúrate de que todos los tests pasen o que los cambios estén probados antes de enviar.
- Mantén tu PR enfocado y evita incluir cambios no relacionados.
- Revisa estos archivos antes de enviar tus cambios:
  - [bug.yml](https://github.com/JaKooLit/Hyprland-Dots/blob/main/.github/ISSUE_TEMPLATE/bug.yml) – Reporte de errores.
  - [feature.yml](https://github.com/JaKooLit/Hyprland-Dots/blob/main/.github/ISSUE_TEMPLATE/feature.yml) – Sugerir características.
  - [documentation-update.yml](https://github.com/JaKooLit/Hyprland-Dots/blob/main/.github/ISSUE_TEMPLATE/documentation-update.yml) – Cambios de documentación.
  - [PULL_REQUEST_TEMPLATE.md](https://github.com/JaKooLit/Hyprland-Dots/blob/main/.github/PULL_REQUEST_TEMPLATE.md) – Plantilla de PR.
  - [COMMIT_MESSAGE_GUIDELINES.md](./COMMIT_MESSAGE_GUIDELINES.md) – Guía de mensajes de commit.
  - [CONTRIBUTING.md](./CONTRIBUTING.md) – Guía en inglés.
  - [LICENSE](https://github.com/JaKooLit/Hyprland-Dots/blob/main/LICENSE.md) – Licencia.
  - [README.md](https://github.com/JaKooLit/Hyprland-Dots/blob/main/README.md) – Proyecto.

## Contacto

Si tienes preguntas, utiliza [GitHub Discussions](https://github.com/JaKooLit/Hyprland-Dots/discussions) o el [Servidor de Discord](https://discord.gg/kool-tech-world).

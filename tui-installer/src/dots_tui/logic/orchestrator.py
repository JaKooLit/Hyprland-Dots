from __future__ import annotations

import os
import re
import shutil
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Callable

from dots_tui.logic.copy_ops import (
    copy_config_dir,
    copy_phase1_dir,
    copy_waybar_with_merge,
    install_file,
    restore_rofi_from_backup,
)
from dots_tui.logic.dedupe import cleanup_duplicate_userconfigs
from dots_tui.logic.backup import cleanup_backups
from dots_tui.logic.models import (
    EnvironmentInfo,
    InstallConfig,
    InstallerPaths,
    InstallerState,
    LogFn,
    PromptConfirmFn,
    PromptPasswordFn,
    PromptReplaceFn,
)
from dots_tui.logic.restore import (
    restore_hypr_assets,
    restore_hypr_files,
    restore_user_configs,
    restore_user_scripts,
)
from dots_tui.logic.system import (
    detect_distro,
    detect_chassis,
    detect_nixos,
    detect_nvidia,
    detect_vm,
    get_installed_dotfiles_version,
    MIN_EXPRESS_VERSION,
    version_gte,
    replace_kb_layout,
)
from dots_tui.utils import is_root, run_cmd, which

from dots_tui.logic.plan import PlanCollector
from dots_tui.logic.path_safety import assert_safe_path


# ============================================================================
# Path Constants - Centralized config file paths to reduce magic strings
# ============================================================================

# Hyprland config paths (relative to staging_config or target_config)
HYPR_CONFIGS_DIR = Path("hypr/configs")
HYPR_USERCONFIGS_DIR = Path("hypr/UserConfigs")
HYPR_SCRIPTS_DIR = Path("hypr/scripts")

# Specific config files
HYPR_ENV_VARS = HYPR_CONFIGS_DIR / "ENVariables.conf"
HYPR_SYSTEM_SETTINGS = HYPR_CONFIGS_DIR / "SystemSettings.conf"
HYPR_STARTUP_APPS = HYPR_CONFIGS_DIR / "Startup_Apps.conf"
HYPR_STARTUP_DISABLE = HYPR_CONFIGS_DIR / "Startup_Apps.disable"
HYPR_MONITORS = Path("hypr/monitors.conf")
HYPR_USER_DEFAULTS = HYPR_USERCONFIGS_DIR / "01-UserDefaults.conf"

# Phase 1 config directories (prompt for replacement)
PHASE1_CONFIGS = ["fastfetch", "kitty", "rofi", "swaync"]

# Phase 2 config directories (no prompt, backup + replace)
PHASE2_CONFIGS = [
    "btop",
    "cava",
    "hypr",
    "Kvantum",
    "qt5ct",
    "qt6ct",
    "swappy",
    "wallust",
    "wlogout",
]


class InstallerOrchestrator:
    def __init__(self) -> None:
        self.repo_root = self._detect_repo_root()
        self.last_state: InstallerState | None = None
        self._sudo_warned = False

    def _detect_repo_root(self) -> Path:
        start = Path.cwd().resolve()
        for candidate in (start, *start.parents):
            if (candidate / "config").is_dir() and (candidate / "scripts").is_dir():
                return candidate
        return start

    def _assert_repo_root(self) -> None:
        if not (self.repo_root / "config").is_dir():
            raise RuntimeError(f"Expected repo root with config/: {self.repo_root}")

    def _copy_logs_dir(self) -> Path:
        d = self.repo_root / "Copy-Logs"
        d.mkdir(parents=True, exist_ok=True)
        return d

    def _log_file_path(self, prefix: str) -> Path:
        ts = datetime.now().strftime("%Y-%m-%d_%H%M%S")
        if prefix == "update":
            return self._copy_logs_dir() / f"update-{ts}_git.log"
        return self._copy_logs_dir() / f"install-{ts}_dotfiles.log"

    def create_log_sink(self, *, prefix: str, ui_log: LogFn) -> tuple[LogFn, Path]:
        """Return a log function that writes to UI + file.

        This is the core "tee -a" parity hook: any line written to the UI log
        should also be appended to the file log.
        """

        log_file = self._log_file_path(prefix)
        log_file.parent.mkdir(parents=True, exist_ok=True)
        log_file.touch(exist_ok=True)

        def tee(message: str) -> None:
            ui_log(message)
            with log_file.open("a", encoding="utf-8") as lf:
                lf.write(message + "\n")

        return tee, log_file

    async def _run_sudo_cmd(
        self,
        argv: list[str],
        *,
        log: LogFn,
        prompt_password: PromptPasswordFn | None = None,
        description: str = "",
    ) -> bool:
        # 1. Try non-interactive sudo first
        full_cmd = ["sudo", "-n"] + argv
        result = await run_cmd(full_cmd, log=log)
        if result.returncode == 0:
            return True

        # Check if failure is due to missing password
        is_auth_fail = (
            "password is required" in result.output.lower() or result.returncode == 1
        )
        if not is_auth_fail:
            # Genuine failure not related to auth
            return False

        # 2. Try to get password if prompt function is provided
        if prompt_password is not None:
            # Only log warning once
            if not self._sudo_warned:
                log("[NOTE] Sudo authentication required for this step.")

            while True:
                pw = prompt_password("Enter sudo password to proceed (or Esc to skip):")
                if not pw:
                    break

                # 3. Authenticate session with sudo -v -S
                auth_cmd = ["sudo", "-v", "-S"]
                auth_res = await run_cmd(auth_cmd, input_text=pw + "\n", log=log)

                if auth_res.returncode == 0:
                    # Retry original command
                    retry_res = await run_cmd(full_cmd, log=log)
                    return retry_res.returncode == 0
                else:
                    log("[WARN] Authentication failed. Please try again.")

        # 4. Fallback: warn if not already warned
        if not self._sudo_warned:
            log(
                "[NOTE] Some system changes require passwordless sudo or a password."
                " Skipping this step."
            )
            self._sudo_warned = True

        if description:
            log(f"[NOTE] Skipped (auth failed): {description}")
        return False

    async def update_repo(
        self,
        *,
        log: LogFn,
        log_file: Path,
        set_step: Callable[[str, int | None], None],
    ) -> None:
        self._assert_repo_root()
        expected_name = "Hyprland-Dots"
        if self.repo_root.name != expected_name:
            raise RuntimeError(
                f"This helper must be run from the {expected_name} directory. Current: {self.repo_root}"
            )
        set_step("Starting repository update...", 5)
        log("[INFO] Starting repository update...")

        set_step("Checking git repo...", 10)
        if not which("git"):
            raise RuntimeError("git not found")

        head_before_res = await run_cmd(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=self.repo_root,
            log=log,
        )
        head_before = (
            head_before_res.output.strip()
            if head_before_res.returncode == 0
            else "unknown"
        )

        set_step("Checking working tree...", 15)
        log("[INFO] Checking working tree...")
        diff1 = await run_cmd(["git", "diff", "--quiet"], cwd=self.repo_root, log=log)
        diff2 = await run_cmd(
            ["git", "diff", "--cached", "--quiet"], cwd=self.repo_root, log=log
        )

        stash_msg = "No local changes; no stash created."
        if diff1.returncode == 0 and diff2.returncode == 0:
            log(f"[NOTE] {stash_msg}")
        else:
            set_step("Stashing local changes...", 25)
            log("[INFO] Stashing local changes (tracked + untracked)...")
            stash_res = await run_cmd(
                ["git", "stash", "push", "-u"], cwd=self.repo_root, log=log
            )
            if stash_res.returncode != 0:
                raise RuntimeError("git stash failed")
            first = (stash_res.output.splitlines() or [""])[0]
            stash_msg = f"Created stash: {first}" if first else "Created stash."
            log(f"[OK] {stash_msg}")

        set_step("Pulling latest changes...", 60)
        log("[INFO] Pulling latest changes...")
        res = await run_cmd(["git", "pull", "--ff-only"], cwd=self.repo_root, log=log)
        pull_status = res.returncode
        if pull_status == 0:
            log("[OK] Repository updated successfully.")
        else:
            log(f"[ERROR] git pull failed (exit {pull_status}).")

        head_after_res = await run_cmd(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=self.repo_root,
            log=log,
        )
        head_after = (
            head_after_res.output.strip()
            if head_after_res.returncode == 0
            else "unknown"
        )

        log("----------------------------------------")
        log("Summary:")
        log(f"  Repo        : {self.repo_root}")
        log(f"  Log file    : {log_file}")
        log(f"  HEAD before : {head_before}")
        log(f"  HEAD after  : {head_after}")
        log(f"  Stash       : {stash_msg}")
        log(f"  Pull status : {'success' if pull_status == 0 else 'failure'}")
        log("----------------------------------------")

        if pull_status != 0:
            raise RuntimeError(f"git pull failed (exit {pull_status})")

        installed_version = get_installed_dotfiles_version()
        if installed_version:
            log(
                f"[INFO] Checking for duplicate UserConfigs entries after repo update (detected v{installed_version})..."
            )
            cleanup_duplicate_userconfigs(installed_version, log)
        else:
            log(
                "[NOTE] Skipping UserConfigs duplicate cleanup; installed version could not be detected."
            )

        set_step("Update complete.", 100)

    async def run_install(
        self,
        config: InstallConfig,
        *,
        log: LogFn,
        log_file: Path,
        set_step: Callable[[str, int | None], None],
        prompt_replace: PromptReplaceFn | None = None,
        prompt_confirm: PromptConfirmFn | None = None,
        prompt_password: PromptPasswordFn | None = None,
    ) -> None:
        plan: PlanCollector | None = None
        if config.dry_run:
            plan = PlanCollector()

        if is_root():
            raise RuntimeError(
                "This script should NOT be executed as root!! Exiting......."
            )

        self._assert_repo_root()

        set_step("Preparing...", 5)
        if plan is None:
            res = await run_cmd(["xdg-user-dirs-update"], log=log)
            if res.returncode != 0:
                log(
                    f"[WARN] xdg-user-dirs-update failed (exit {res.returncode}); continuing"
                )
        else:
            plan.add(kind="cmd", detail="xdg-user-dirs-update")

        target_config_root = Path(
            os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))
        )

        distro_id, distro_like = detect_distro()
        chassis = detect_chassis()
        installed_version = get_installed_dotfiles_version(target_config_root)
        installed_version_at_start = installed_version

        with tempfile.TemporaryDirectory(prefix="hyprdots-stage-") as td:
            staging_root = Path(td)
            staging_config = staging_root / "config"
            staging_wallpapers = staging_root / "wallpapers"

            set_step("Staging files...", 10)
            if plan is None:
                shutil.copytree(
                    self.repo_root / "config", staging_config, symlinks=True
                )
                if (self.repo_root / "wallpapers").is_dir():
                    shutil.copytree(
                        self.repo_root / "wallpapers",
                        staging_wallpapers,
                        symlinks=True,
                    )
            else:
                plan.add(
                    kind="copytree",
                    detail="stage repo config",
                    src=self.repo_root / "config",
                    dst=staging_config,
                )
                if (self.repo_root / "wallpapers").is_dir():
                    plan.add(
                        kind="copytree",
                        detail="stage wallpapers",
                        src=self.repo_root / "wallpapers",
                        dst=staging_wallpapers,
                    )

            set_step("Applying system tweaks...", 20)
            is_nvidia = detect_nvidia()
            is_vm = detect_vm()
            is_nixos = detect_nixos()
            if is_nvidia:
                log("[INFO] Nvidia GPU detected; applying config tweaks")
                if plan is None:
                    self._apply_nvidia_tweaks(staging_config)
                else:
                    plan.add(
                        kind="edit", detail="apply nvidia tweaks", dst=staging_config
                    )
            if is_vm:
                log("[INFO] VM detected; applying config tweaks")
                if plan is None:
                    self._apply_vm_tweaks(staging_config)
                else:
                    plan.add(kind="edit", detail="apply vm tweaks", dst=staging_config)
            if is_nixos:
                log("[INFO] NixOS detected; applying config tweaks")
                if plan is None:
                    self._apply_nixos_tweaks(staging_config)
                else:
                    plan.add(
                        kind="edit", detail="apply nixos tweaks", dst=staging_config
                    )

            if (Path.home() / ".icons/Bibata-Modern-Ice/hyprcursors").is_dir():
                log(
                    "[INFO] Bibata-Hyprcursor directory detected. Activating Hyprcursor...."
                )
                if plan is None:
                    self._apply_hyprcursor_tweaks(staging_config)
                else:
                    plan.add(
                        kind="edit",
                        detail="apply hyprcursor tweaks",
                        dst=staging_config,
                    )

            self.last_state = InstallerState(
                run_mode=config.run_mode,
                selections=config,
                env=EnvironmentInfo(
                    distro_id=distro_id,
                    distro_like=distro_like,
                    chassis=chassis,
                    is_nvidia=is_nvidia,
                    is_vm=is_vm,
                    is_nixos=is_nixos,
                    installed_dotfiles_version=installed_version,
                ),
                paths=InstallerPaths(
                    repo_root=self.repo_root,
                    copy_logs_dir=self._copy_logs_dir(),
                    log_file=log_file,
                    target_config_root=target_config_root,
                    staging_root=staging_root,
                ),
            )

            if config.run_mode == "express":
                if installed_version is None or not version_gte(
                    installed_version, MIN_EXPRESS_VERSION
                ):
                    log(
                        f"[WARN] Express mode requires installed dotfiles v{MIN_EXPRESS_VERSION} or newer. Falling back to standard upgrade."
                    )
                    config = InstallConfig(
                        run_mode="upgrade",
                        resolution=config.resolution,
                        keyboard_layout=config.keyboard_layout,
                        clock_24h=config.clock_24h,
                        default_editor=config.default_editor,
                        download_wallpapers=config.download_wallpapers,
                        apply_sddm_wallpaper=config.apply_sddm_wallpaper,
                        enable_asus=config.enable_asus,
                        enable_blueman=config.enable_blueman,
                        enable_ags=config.enable_ags,
                        enable_quickshell=config.enable_quickshell,
                        dry_run=config.dry_run,
                    )

                    assert self.last_state is not None
                    self.last_state = InstallerState(
                        run_mode=config.run_mode,
                        selections=config,
                        env=self.last_state.env,
                        paths=self.last_state.paths,
                    )

            # Initial run-mode logging parity.
            log(f"Selected workflow: {config.run_mode}")
            if config.run_mode in {"upgrade", "express"}:
                log("Upgrade mode enabled.")
            if config.run_mode == "express":
                log("Express mode enabled. Optional restore prompts will be skipped.")

            set_step("Applying user configuration...", 30)
            if plan is None:
                self._apply_user_choices(config, staging_config, log)
            else:
                plan.add(kind="edit", detail="apply user choices", dst=staging_config)

            set_step("Copying configs (phase 1)...", 45)
            for name in PHASE1_CONFIGS:
                log(f"[INFO] Installing {name}")

                dst = target_config_root / name
                if dst.exists() and prompt_replace is not None:
                    if not prompt_replace(name, dst):
                        log(f"[NOTE] - Skipping {name}")
                        continue

                backup = None
                if plan is None:
                    backup = copy_phase1_dir(
                        name=name,
                        staging_config_root=staging_config,
                        target_config_root=target_config_root,
                        log=log,
                    )
                else:
                    plan.add(
                        kind="copytree",
                        detail=f"install {name} (phase 1)",
                        src=staging_config / name,
                        dst=target_config_root / name,
                    )
                if name == "rofi" and backup is not None:
                    restore_rofi_from_backup(
                        backup_dir=backup,
                        rofi_dir=target_config_root / "rofi",
                        log=log,
                    )

            set_step("Copying configs (waybar)...", 55)
            log("[INFO] Installing waybar")

            waybar_dst = target_config_root / "waybar"
            if waybar_dst.exists() and prompt_replace is not None:
                if not prompt_replace("waybar", waybar_dst):
                    log("[NOTE] - Skipping waybar config replacement.")
                else:
                    if plan is None:
                        copy_waybar_with_merge(
                            staging_config_root=staging_config,
                            target_config_root=target_config_root,
                            log=log,
                        )
                    else:
                        plan.add(
                            kind="copytree",
                            detail="install waybar (replace+merge)",
                            src=staging_config / "waybar",
                            dst=target_config_root / "waybar",
                        )
            else:
                if plan is None:
                    copy_waybar_with_merge(
                        staging_config_root=staging_config,
                        target_config_root=target_config_root,
                        log=log,
                    )
                else:
                    plan.add(
                        kind="copytree",
                        detail="install waybar",
                        src=staging_config / "waybar",
                        dst=target_config_root / "waybar",
                    )

            set_step("Copying configs (phase 2)...", 70)
            hypr_backup: Path | None = None
            for name in PHASE2_CONFIGS:
                log(f"[INFO] Installing {name}")
                backup = None
                if plan is None:
                    backup = copy_config_dir(
                        name=name,
                        staging_config_root=staging_config,
                        target_config_root=target_config_root,
                    )
                else:
                    plan.add(
                        kind="copytree",
                        detail=f"install {name} (phase 2)",
                        src=staging_config / name,
                        dst=target_config_root / name,
                    )
                if name == "hypr" and backup is not None:
                    hypr_backup = backup

            set_step("Installing terminal configs...", 78)
            ghostty_src = staging_config / "ghostty" / "ghostty.config"
            if plan is None:
                if ghostty_src.is_file():
                    install_file(
                        src=ghostty_src,
                        dst=target_config_root / "ghostty" / "config",
                        mode=0o644,
                    )
                    wallust_conf = target_config_root / "ghostty" / "wallust.conf"
                    if wallust_conf.is_file():
                        txt = wallust_conf.read_text(encoding="utf-8", errors="replace")
                        txt = re.sub(
                            r"^(\s*palette\s*=\s*)([0-9]{1,2}):",
                            r"\1\2=",
                            txt,
                            flags=re.MULTILINE,
                        )
                        wallust_conf.write_text(txt, encoding="utf-8")
            else:
                plan.add(
                    kind="copy",
                    detail="install ghostty config",
                    src=ghostty_src,
                    dst=target_config_root / "ghostty" / "config",
                )
            wez_src = staging_config / "wezterm" / "wezterm.lua"
            if plan is None:
                if wez_src.is_file():
                    install_file(
                        src=wez_src,
                        dst=target_config_root / "wezterm" / "wezterm.lua",
                        mode=0o644,
                    )
            else:
                plan.add(
                    kind="copy",
                    detail="install wezterm config",
                    src=wez_src,
                    dst=target_config_root / "wezterm" / "wezterm.lua",
                )

            # Optional post-copy app configs (AGS / Quickshell).
            set_step("Installing optional app configs...", 80)
            if plan is None:
                self._install_optional_app_configs(
                    config,
                    staging_config_root=staging_config,
                    target_config_root=target_config_root,
                    log=log,
                    prompt_confirm=prompt_confirm,
                )
            else:
                plan.add(kind="copytree", detail="install optional app configs")

            if config.run_mode in {"upgrade", "express"}:
                set_step("Restoring previous configs...", 82)
                if plan is None:
                    # If no backup was created this run, look for existing backups
                    # (including legacy copy.sh format backups)
                    if hypr_backup is None:
                        from dots_tui.logic.backup import find_most_recent_backup
                        
                        hypr_dir = target_config_root / "hypr"
                        hypr_backup = find_most_recent_backup(hypr_dir)
                        
                        if hypr_backup is not None:
                            log(
                                f"[NOTE] Found existing backup from previous installation: {hypr_backup.name}"
                            )
                        else:
                            log(
                                "[NOTE] No hypr backup found for this run; skipping restore."
                            )
                    
                    if hypr_backup is not None:
                        hypr_dir = target_config_root / "hypr"
                        express = config.run_mode == "express"
                        restore_hypr_assets(
                            backup_hypr_dir=hypr_backup,
                            hypr_dir=hypr_dir,
                            express=express,
                            log=log,
                        )
                        restore_user_configs(
                            backup_hypr_dir=hypr_backup,
                            hypr_dir=hypr_dir,
                            express=express,
                            prompt_confirm=prompt_confirm,
                            log=log,
                            old_version=installed_version_at_start,
                        )
                        restore_user_scripts(
                            backup_hypr_dir=hypr_backup,
                            hypr_dir=hypr_dir,
                            express=express,
                            prompt_confirm=prompt_confirm,
                            log=log,
                        )
                        restore_hypr_files(
                            backup_hypr_dir=hypr_backup,
                            hypr_dir=hypr_dir,
                            express=express,
                            prompt_confirm=prompt_confirm,
                            log=log,
                        )
                else:
                    plan.add(kind="restore", detail="restore previous configs")

            set_step("Installing wallpapers...", 85)
            if plan is None:
                await self._install_wallpapers(config, staging_wallpapers, log)
            else:
                plan.add(
                    kind="copytree", detail="install wallpapers", src=staging_wallpapers
                )

            set_step("Finalizing...", 92)
            if plan is None:
                await self._finalize_post_copy(
                    config,
                    target_config_root,
                    log,
                    prompt_confirm=prompt_confirm,
                    prompt_password=prompt_password,
                )
            else:
                plan.add(kind="finalize", detail="post-copy finalize")

                log("[PLAN] Dry-run mode: no changes were made.")
                for op in plan.ops:
                    loc = ""
                    if op.src is not None or op.dst is not None:
                        loc = f" src={op.src} dst={op.dst}"
                    log(f"[PLAN] {op.kind}: {op.detail}{loc}")
                return

        set_step("Complete.", 100)

    def _apply_nvidia_tweaks(self, staging_config: Path) -> None:
        env_file = staging_config / HYPR_ENV_VARS
        sys_file = staging_config / HYPR_SYSTEM_SETTINGS
        if env_file.is_file():
            text = env_file.read_text(encoding="utf-8", errors="replace").splitlines(
                True
            )
            rules = [
                "env = LIBVA_DRIVER_NAME,nvidia",
                "env = __GLX_VENDOR_LIBRARY_NAME,nvidia",
                "env = NVD_BACKEND,direct",
                "env = GSK_RENDERER,ngl",
            ]
            out: list[str] = []
            for line in text:
                stripped = line.lstrip("#")
                if any(r in stripped for r in rules):
                    out.append(stripped)
                else:
                    out.append(line)
            env_file.write_text("".join(out), encoding="utf-8")

        if sys_file.is_file():
            txt = sys_file.read_text(encoding="utf-8", errors="replace")
            txt = txt.replace("no_hardware_cursors = 2", "no_hardware_cursors = 1")
            sys_file.write_text(txt, encoding="utf-8")

    def _apply_vm_tweaks(self, staging_config: Path) -> None:
        env_file = staging_config / HYPR_ENV_VARS
        sys_file = staging_config / HYPR_SYSTEM_SETTINGS
        mon_file = staging_config / HYPR_MONITORS
        if sys_file.is_file():
            txt = sys_file.read_text(encoding="utf-8", errors="replace")
            txt = txt.replace("no_hardware_cursors = 2", "no_hardware_cursors = 1")
            sys_file.write_text(txt, encoding="utf-8")

        if env_file.is_file():
            txt = env_file.read_text(encoding="utf-8", errors="replace")
            txt = txt.replace(
                "#env = WLR_RENDERER_ALLOW_SOFTWARE,1",
                "env = WLR_RENDERER_ALLOW_SOFTWARE,1",
            )
            env_file.write_text(txt, encoding="utf-8")

        if mon_file.is_file():
            txt = mon_file.read_text(encoding="utf-8", errors="replace")
            txt = txt.replace(
                "#monitor = Virtual-1, 1920x1080@60,auto,1",
                "monitor = Virtual-1, 1920x1080@60,auto,1",
            )
            mon_file.write_text(txt, encoding="utf-8")

    def _apply_nixos_tweaks(self, staging_config: Path) -> None:
        overlay = staging_config / HYPR_STARTUP_APPS
        disable = staging_config / HYPR_STARTUP_DISABLE
        overlay.parent.mkdir(parents=True, exist_ok=True)
        overlay.touch(exist_ok=True)
        disable.touch(exist_ok=True)

        line = "exec-once = $scriptsDir/Polkit-NixOS.sh\n"
        if line not in overlay.read_text(encoding="utf-8", errors="replace"):
            overlay.open("a", encoding="utf-8").write(line)

        dline = "$scriptsDir/Polkit.sh\n"
        if dline not in disable.read_text(encoding="utf-8", errors="replace"):
            disable.open("a", encoding="utf-8").write(dline)

    def _apply_hyprcursor_tweaks(self, staging_config: Path) -> None:
        env_file = staging_config / HYPR_ENV_VARS
        if not env_file.is_file():
            return
        txt = env_file.read_text(encoding="utf-8", errors="replace")
        txt = txt.replace(
            "#env = HYPRCURSOR_THEME,Bibata-Modern-Ice",
            "env = HYPRCURSOR_THEME,Bibata-Modern-Ice",
        )
        txt = txt.replace("#env = HYPRCURSOR_SIZE,24", "env = HYPRCURSOR_SIZE,24")
        env_file.write_text(txt, encoding="utf-8")

    def _apply_user_choices(
        self, cfg: InstallConfig, staging_config: Path, log: LogFn
    ) -> None:
        sys_settings = staging_config / HYPR_SYSTEM_SETTINGS
        if sys_settings.is_file():
            replace_kb_layout(sys_settings, cfg.keyboard_layout)
            log(f"[NOTE] kb_layout {cfg.keyboard_layout} configured in settings.")

        if cfg.default_editor:
            defaults = staging_config / HYPR_USER_DEFAULTS
            if defaults.is_file():
                lines = defaults.read_text(
                    encoding="utf-8", errors="replace"
                ).splitlines(True)
                defaults_out: list[str] = []
                replaced = False
                for line in lines:
                    if re.match(r"^\s*#?\s*env\s*=\s*EDITOR,", line):
                        defaults_out.append(
                            f"env = EDITOR,{cfg.default_editor} #default editor\n"
                        )
                        replaced = True
                    else:
                        defaults_out.append(line)
                if not replaced:
                    defaults_out.insert(
                        0, f"env = EDITOR,{cfg.default_editor} #default editor\n"
                    )
                defaults.write_text("".join(defaults_out), encoding="utf-8")
                log(f"[OK] Default editor set to {cfg.default_editor}.")
            else:
                log(
                    "[WARN] Default editor template not found; skipping editor configuration"
                )

        if cfg.resolution == "lt_1440p":
            kitty_conf = staging_config / "kitty" / "kitty.conf"
            if kitty_conf.is_file():
                txt = kitty_conf.read_text(encoding="utf-8", errors="replace")
                txt = txt.replace("font_size 16.0", "font_size 14.0")
                kitty_conf.write_text(txt, encoding="utf-8")

            rofi_fonts = staging_config / "rofi" / "0-shared-fonts.rasi"
            if rofi_fonts.is_file():
                txt = rofi_fonts.read_text(encoding="utf-8", errors="replace")
                txt = txt.replace(
                    'font: "JetBrainsMono Nerd Font SemiBold 13";',
                    'font: "JetBrainsMono Nerd Font SemiBold 11";',
                )
                txt = txt.replace(
                    'font: "JetBrainsMono Nerd Font SemiBold 15";',
                    'font: "JetBrainsMono Nerd Font SemiBold 13";',
                )
                rofi_fonts.write_text(txt, encoding="utf-8")

            hypr_dir = staging_config / "hypr"
            hyprlock = hypr_dir / "hyprlock.conf"
            hyprlock_2k = hypr_dir / "hyprlock-2k.conf"
            hyprlock_1080 = hypr_dir / "hyprlock-1080p.conf"
            if hyprlock.exists():
                hyprlock.rename(hyprlock_2k)
            if hyprlock_1080.exists():
                hyprlock_1080.rename(hyprlock)

        if not cfg.clock_24h:
            modules = staging_config / "waybar" / "Modules"
            if modules.is_file():
                lines = modules.read_text(
                    encoding="utf-8", errors="replace"
                ).splitlines(True)

                def uncomment(line: str) -> str:
                    return re.sub(r"^(\s*)//\s*", r"\1", line)

                def comment(line: str) -> str:
                    if re.match(r"^\s*//", line):
                        return line
                    return re.sub(r"^(\s*)", r"\1//", line)

                enable_12h = [
                    "{:%I:%M %p}",
                    "{:%I:%M %p - %d/%b}",
                    "{:%B | %a %d, %Y | %I:%M %p}",
                    "{:%A, %I:%M %P}",
                ]
                disable_24h = [
                    "{:%H:%M:%S}",
                    "{:%H:%M}",
                    "{:%H:%M - %d/%b}",
                    "{:%B | %a %d, %Y | %H:%M}",
                    "{:%a %d | %H:%M}",
                ]

                modules_out: list[str] = []
                for line in lines:
                    if any(pat in line for pat in enable_12h):
                        modules_out.append(uncomment(line))
                    elif any(pat in line for pat in disable_24h):
                        modules_out.append(comment(line))
                    else:
                        modules_out.append(line)

                modules.write_text("".join(modules_out), encoding="utf-8")

            hypr_dir = staging_config / "hypr"
            hyprlock_file = hypr_dir / "hyprlock.conf"
            if (
                not hyprlock_file.is_file()
                and (hypr_dir / "hyprlock-1080p.conf").is_file()
            ):
                hyprlock_file = hypr_dir / "hyprlock-1080p.conf"
            if hyprlock_file.is_file():
                txt = hyprlock_file.read_text(encoding="utf-8", errors="replace")
                lines = txt.splitlines(True)

                def ensure_commented(line: str) -> str:
                    stripped = line.lstrip()
                    indent = line[: len(line) - len(stripped)]
                    if stripped.startswith("#"):
                        return line
                    return indent + "# " + stripped

                def ensure_uncommented(line: str) -> str:
                    stripped = line.lstrip()
                    indent = line[: len(line) - len(stripped)]
                    if not stripped.startswith("#"):
                        return line
                    stripped = re.sub(r"^#+\s*", "", stripped)
                    return indent + stripped

                out: list[str] = []
                for line in lines:
                    raw = line.lstrip()
                    candidate = re.sub(r"^#+\s*", "", raw)
                    if (
                        "text = cmd[update:1000]" in candidate
                        and 'date +"%H' in candidate
                    ):
                        out.append(ensure_commented(line))
                    elif (
                        "text = cmd[update:1000]" in candidate
                        and 'date +"%I' in candidate
                        and "%p" in candidate
                    ):
                        out.append(ensure_uncommented(line))
                    elif (
                        "text = cmd[update:1000]" in candidate
                        and 'date +"%S' in candidate
                        and "%p" not in candidate
                    ):
                        out.append(ensure_commented(line))
                    elif (
                        "text = cmd[update:1000]" in candidate
                        and 'date +"%S %p' in candidate
                    ):
                        out.append(ensure_uncommented(line))
                    else:
                        out.append(line)

                txt = "".join(out)
                hyprlock_file.write_text(txt, encoding="utf-8")

        if (
            cfg.enable_asus
            or cfg.enable_blueman
            or cfg.enable_ags
            or cfg.enable_quickshell
        ):
            overlay = staging_config / "hypr" / "configs" / "Startup_Apps.conf"
            overlay.parent.mkdir(parents=True, exist_ok=True)
            overlay.touch(exist_ok=True)
            existing = overlay.read_text(encoding="utf-8", errors="replace")

            def add(line: str) -> None:
                nonlocal existing
                if line not in existing:
                    overlay.open("a", encoding="utf-8").write(line)
                    existing += line

            if cfg.enable_asus and which("asusctl"):
                add("exec-once = rog-control-center\n")

            if cfg.enable_blueman and which("blueman-applet"):
                add("exec-once = blueman-applet\n")

            if cfg.enable_ags and which("ags"):
                add("exec-once = ags\n")
                # Also uncomment ags lines in Refresh scripts
                for script in ["RefreshNoWaybar.sh", "Refresh.sh"]:
                    script_path = staging_config / "hypr" / "scripts" / script
                    if script_path.exists():
                        txt = script_path.read_text(encoding="utf-8", errors="replace")
                        txt = re.sub(r"#ags -q && ags &", "ags -q && ags &", txt)
                        script_path.write_text(txt, encoding="utf-8")

            if cfg.enable_quickshell and which("qs"):
                add("exec-once = qs\n")
                # Also uncomment quickshell lines in Refresh scripts
                for script in ["RefreshNoWaybar.sh", "Refresh.sh"]:
                    script_path = staging_config / "hypr" / "scripts" / script
                    if script_path.exists():
                        txt = script_path.read_text(encoding="utf-8", errors="replace")
                        txt = re.sub(r"#pkill qs && qs &", "pkill qs && qs &", txt)
                        script_path.write_text(txt, encoding="utf-8")

            add("exec-once = $scriptsDir/KeybindsLayoutInit.sh\n")

    async def _install_wallpapers(
        self, cfg: InstallConfig, staging_wallpapers: Path, log: LogFn
    ) -> None:
        pictures_dir = await self._detect_pictures_dir(log)
        target = pictures_dir / "wallpapers"
        assert_safe_path(target)
        target.mkdir(parents=True, exist_ok=True)

        if staging_wallpapers.is_dir():
            for item in staging_wallpapers.iterdir():
                dst = target / item.name
                if item.is_dir():
                    if dst.exists():
                        assert_safe_path(dst)
                        shutil.rmtree(dst)
                    shutil.copytree(item, dst, symlinks=True)
                else:
                    shutil.copy2(item, dst)
            log("[OK] Wallpapers copied.")

        if cfg.run_mode == "express":
            if cfg.download_wallpapers:
                log("[NOTE] Express mode: skipping additional wallpapers download.")
            return

        if cfg.download_wallpapers:
            log(
                "[NOTE] Disclaimer: additional wallpapers are AI generated and may contain artifacts."
            )
            log("[NOTE] Download size is ~1GB.")
            if not which("git"):
                log("[WARN] git not found; cannot download Wallpaper-Bank")
                return

            with tempfile.TemporaryDirectory(prefix="hyprdots-walls-") as td:
                tmp = Path(td)
                res = await run_cmd(
                    ["git", "clone", "https://github.com/JaKooLit/Wallpaper-Bank.git"],
                    cwd=tmp,
                    log=log,
                )
                if res.returncode != 0:
                    log("[ERROR] Wallpaper-Bank clone failed")
                    return

                bank = tmp / "Wallpaper-Bank" / "wallpapers"
                if bank.is_dir():
                    for item in bank.iterdir():
                        dst = target / item.name
                        if item.is_dir():
                            if dst.exists():
                                assert_safe_path(dst)
                                shutil.rmtree(dst)
                            shutil.copytree(item, dst, symlinks=True)
                        else:
                            shutil.copy2(item, dst)
                    log("[OK] Additional wallpapers copied.")

    async def _detect_pictures_dir(self, log: LogFn) -> Path:
        if which("xdg-user-dir"):
            res = await run_cmd(["xdg-user-dir", "PICTURES"], log=log)
            if res.returncode == 0:
                raw = (res.output or "").strip().splitlines()[-1].strip()
                if raw:
                    p = Path(raw).expanduser()
                    if p.is_absolute():
                        return p

        return Path(os.environ.get("XDG_PICTURES_DIR", str(Path.home() / "Pictures")))

    def _install_optional_app_configs(
        self,
        cfg: InstallConfig,
        *,
        staging_config_root: Path,
        target_config_root: Path,
        log: LogFn,
        prompt_confirm: Callable[[str, str, str, bool], bool] | None,
    ) -> None:
        def copytree(src: Path, dst: Path) -> None:
            assert_safe_path(dst)
            if dst.exists() and not dst.is_symlink():
                shutil.rmtree(dst)
            elif dst.is_symlink():
                dst.unlink(missing_ok=True)
            shutil.copytree(src, dst, symlinks=True)

        # AGS config copy/overwrite.
        if cfg.enable_ags and which("ags"):
            src = staging_config_root / "ags"
            dst = target_config_root / "ags"
            if not src.is_dir():
                log("[ERROR] Missing source config/ags; skipping.")
            elif not dst.exists():
                copytree(src, dst)
                log("[OK] - Installed ags config")
            else:
                msg = "Do you want to overwrite your existing ags config?"
                ok = False
                if prompt_confirm is not None:
                    ok = prompt_confirm(msg, "Overwrite", "Skip", False)
                if ok:
                    backup = copy_config_dir(
                        name="ags",
                        staging_config_root=staging_config_root,
                        target_config_root=target_config_root,
                    )
                    if backup is None:
                        if not dst.is_dir():
                            raise RuntimeError("Failed to install ags config")
                    log("[OK] - Overwrote ags config")
                else:
                    log("[NOTE] - Skipped overwriting ags config")

        # Quickshell config copy/overwrite + overview fixups.
        if cfg.enable_quickshell and which("qs"):
            src = staging_config_root / "quickshell"
            dst = target_config_root / "quickshell"
            if not src.is_dir():
                log("[ERROR] Missing source config/quickshell; skipping.")
                return

            if dst.exists() and (dst / "shell.qml").exists():
                try:
                    assert_safe_path(dst / "shell.qml")
                    (dst / "shell.qml").unlink(missing_ok=True)
                    log("[NOTE] Removed legacy quickshell shell.qml")
                except Exception:
                    pass

            if not dst.exists():
                copytree(src, dst)
                (dst / "shell.qml").unlink(missing_ok=True)
                log("[OK] - Installed quickshell config")
            else:
                msg = "Do you want to overwrite your existing quickshell config?"
                ok = False
                if prompt_confirm is not None:
                    ok = prompt_confirm(msg, "Overwrite", "Skip", True)
                if ok:
                    # Backup existing then replace.
                    backup = copy_config_dir(
                        name="quickshell",
                        staging_config_root=staging_config_root,
                        target_config_root=target_config_root,
                    )
                    _ = backup
                    (dst / "shell.qml").unlink(missing_ok=True)
                    if not dst.is_dir():
                        raise RuntimeError("Failed to install quickshell config")
                    log("[OK] - Overwrote quickshell config")
                else:
                    log("[NOTE] - Skipped overwriting quickshell config")

            # Ensure overview exists.
            overview_dst = dst / "overview"
            overview_src = src / "overview"
            if not overview_dst.exists() and overview_src.is_dir():
                try:
                    copytree(overview_src, overview_dst)
                    log("[OK] - Installed quickshell overview")
                except Exception:
                    pass

            # Rewrite legacy qs startup lines.
            startup = target_config_root / "hypr" / "configs" / "Startup_Apps.conf"
            if startup.is_file():
                txt = startup.read_text(encoding="utf-8", errors="replace").splitlines(
                    True
                )
                out: list[str] = []
                changed = False
                for line in txt:
                    if re.match(r"^\s*exec-once\s*=\s*qs(?:\s*&)?\s*$", line.strip()):
                        out.append(
                            "exec-once = qs -c overview  # Quickshell Overview\n"
                        )
                        changed = True
                    else:
                        out.append(line)
                if changed:
                    startup.write_text("".join(out), encoding="utf-8")
                    log("[OK] - Updated Startup_Apps for Quickshell Overview")

    async def _finalize_post_copy(
        self,
        cfg: InstallConfig,
        target_config_root: Path,
        log: LogFn,
        *,
        prompt_confirm: PromptConfirmFn | None,
        prompt_password: PromptPasswordFn | None = None,
    ) -> None:
        hypr_dir = target_config_root / "hypr"
        if hypr_dir.is_dir():
            scripts_dir = hypr_dir / "scripts"
            userscripts_dir = hypr_dir / "UserScripts"
            for p in [scripts_dir, userscripts_dir]:
                if p.is_dir():
                    for child in p.iterdir():
                        try:
                            mode = child.stat().st_mode
                            child.chmod(mode | 0o111)
                        except Exception:
                            pass

            init_boot = hypr_dir / "initial-boot.sh"
            if init_boot.is_file():
                try:
                    init_boot.chmod(init_boot.stat().st_mode | 0o111)
                except Exception:
                    pass

        # Rofi themes local-share symlink logic.
        rofi_dir = target_config_root / "rofi"
        rofi_themes = rofi_dir / "themes"
        data_home = Path(
            os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))
        )
        rofi_share = data_home / "rofi" / "themes"
        try:
            rofi_share.mkdir(parents=True, exist_ok=True)
        except Exception:
            pass

        dummy = rofi_themes / "dummy.rasi"
        created_dummy = False
        if rofi_themes.is_dir() and rofi_share.is_dir():
            try:
                if not any(rofi_themes.iterdir()):
                    dummy.write_text("/* Dummy Rofi theme */\n", encoding="utf-8")
                    created_dummy = True
                for item in rofi_themes.iterdir():
                    dst = rofi_share / item.name
                    try:
                        if dst.exists() or dst.is_symlink():
                            dst.unlink(missing_ok=True)
                        dst.symlink_to(item)
                    except Exception:
                        pass
            finally:
                if created_dummy:
                    try:
                        dummy.unlink(missing_ok=True)
                    except Exception:
                        pass

        waybar_dir = target_config_root / "waybar"
        chassis = detect_chassis()
        if waybar_dir.is_dir():
            config_target = (
                waybar_dir
                / "configs"
                / ("[TOP] Default" if chassis == "desktop" else "[TOP] Default Laptop")
            )
            style_target = waybar_dir / "style" / "[Extra] Neon Circuit.css"
            if config_target.exists():
                cfg_link = waybar_dir / "config"
                if not cfg_link.exists() or cfg_link.is_symlink():
                    try:
                        if cfg_link.exists() or cfg_link.is_symlink():
                            cfg_link.unlink(missing_ok=True)
                        cfg_link.symlink_to(config_target)
                    except Exception:
                        pass

            if style_target.exists():
                css_link = waybar_dir / "style.css"
                if not css_link.exists() or css_link.is_symlink():
                    try:
                        if css_link.exists() or css_link.is_symlink():
                            css_link.unlink(missing_ok=True)
                        css_link.symlink_to(style_target)
                    except Exception:
                        pass

            # Remove inappropriate waybar configs (shell behavior).
            config_remove = " Laptop" if chassis == "desktop" else ""
            to_remove = [
                f"[TOP] Default{config_remove}",
                f"[BOT] Default{config_remove}",
                f"[TOP] Default{config_remove} (old v1)",
                f"[TOP] Default{config_remove} (old v2)",
                f"[TOP] Default{config_remove} (old v3)",
                f"[TOP] Default{config_remove} (old v4)",
            ]
            for name in to_remove:
                p = waybar_dir / "configs" / name
                try:
                    if p.is_dir() and not p.is_symlink():
                        assert_safe_path(p)
                        shutil.rmtree(p)
                    else:
                        p.unlink(missing_ok=True)
                except Exception:
                    pass

        # SDDM wallpaper
        sddm_theme = Path("/usr/share/sddm/themes/simple_sddm_2")
        if sddm_theme.is_dir():
            if cfg.run_mode == "express":
                log("[NOTE] Express mode: skipping SDDM wallpaper prompt.")
            elif not cfg.apply_sddm_wallpaper:
                log("[NOTE] SDDM wallpaper step disabled; skipping.")
            else:
                wallpaper_src = hypr_dir / "wallpaper_effects" / ".wallpaper_current"
                dest = sddm_theme / "Backgrounds" / "default"
                if wallpaper_src.exists():
                    success = await self._run_sudo_cmd(
                        ["cp", "-r", str(wallpaper_src), str(dest)],
                        log=log,
                        description="apply wallpaper as SDDM background",
                        prompt_password=prompt_password,
                    )
                    if success:
                        log(
                            "[NOTE] Current wallpaper applied as default SDDM background"
                        )
                else:
                    log("[WARN] SDDM wallpaper source not found; skipping")

        # SDDM clock format edits
        if not cfg.clock_24h:
            for theme_name in ["simple_sddm_2", "simple-sddm"]:
                theme_conf = Path(f"/usr/share/sddm/themes/{theme_name}/theme.conf")
                if not theme_conf.is_file():
                    continue
                await self._run_sudo_cmd(
                    [
                        "sed",
                        "-i",
                        's|^## HourFormat="hh:mm AP"|HourFormat="hh:mm AP"|',
                        str(theme_conf),
                    ],
                    log=log,
                    description=f"update 12h clock format in {theme_name}",
                    prompt_password=prompt_password,
                )
                await self._run_sudo_cmd(
                    [
                        "sed",
                        "-i",
                        's|^HourFormat="HH:mm"|## HourFormat="HH:mm"|',
                        str(theme_conf),
                    ],
                    log=log,
                    description=f"disable 24h clock format in {theme_name}",
                    prompt_password=prompt_password,
                )

            # sequoia_2
            theme_conf = Path("/usr/share/sddm/themes/sequoia_2/theme.conf")
            if theme_conf.is_file():
                await self._run_sudo_cmd(
                    [
                        "sed",
                        "-i",
                        's|^clockFormat="HH:mm"|## clockFormat="HH:mm"|',
                        str(theme_conf),
                    ],
                    log=log,
                    description="disable 24h clock format in sequoia_2",
                    prompt_password=prompt_password,
                )
                # Ensure the 12h clock format line exists; avoid shell usage.
                has_12h = await run_cmd(
                    [
                        "sudo",
                        "-n",
                        "grep",
                        "-q",
                        'clockFormat="hh:mm AP"',
                        str(theme_conf),
                    ],
                    log=log,
                )
                if has_12h.returncode != 0:
                    await self._run_sudo_cmd(
                        [
                            "sed",
                            "-i",
                            '/^## clockFormat="HH:mm"/a clockFormat="hh:mm AP"',
                            str(theme_conf),
                        ],
                        log=log,
                        description="add 12h clock format in sequoia_2",
                        prompt_password=prompt_password,
                    )

        # Backup cleanup (express auto, otherwise prompt).
        cleanup_backups(
            mode=("auto" if cfg.run_mode == "express" else "prompt"),
            log=log,
            prompt_confirm=prompt_confirm,
        )

        # Initialize wallust to avoid config error on hyprland.
        wallpaper_src = hypr_dir / "wallpaper_effects" / ".wallpaper_current"
        if which("wallust") and wallpaper_src.exists():
            _ = await run_cmd(["wallust", "run", "-s", str(wallpaper_src)], log=log)

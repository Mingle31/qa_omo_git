# Windows VS Code 적용 메모

## 현재 방향

하네스 원본을 Windows용으로 크게 포크하기보다, Windows VS Code에서 설치와 검증이 재현 가능하도록 래퍼 스크립트를 제공합니다.

이유는 Codex Light 하네스에 이미 Windows 대응 코드가 들어 있기 때문입니다. 실제로 원본에는 다음 처리가 있습니다.

- Windows에서 Git Bash 탐지
- Git Bash가 없을 때 `winget install --id Git.Git -e --source winget` 시도
- Windows에서 symlink 대신 `.cmd` command shim 생성
- Hook 실행을 `node ".../cli.js"` 형태로 구성
- Windows shell 명령을 Git Bash MCP로 우회하도록 안내

## Linux 전용이거나 Windows와 안 맞을 수 있는 부분

### 1. Codex 설정 위치

Linux/WSL과 Windows는 Codex home이 다릅니다.

```text
Linux/WSL: /home/<user>/.codex
Windows:   C:\Users\<user>\.codex
```

Ubuntu에서 설치한 하네스는 Windows VS Code Codex에 자동 적용되지 않습니다. Windows PowerShell에서 설치해야 합니다.

### 2. 기본 bin 경로

원본 installer의 기본 로컬 bin 경로는 Unix 스타일의 `~/.local/bin` 개념을 사용합니다. Windows에서도 `%USERPROFILE%\.local\bin`으로 만들 수는 있지만, PowerShell PATH에 기본 포함되어 있지 않은 경우가 많습니다.

이 저장소의 `install-windows.ps1 -AddToUserPath`는 해당 경로를 사용자 PATH에 추가합니다.

### 3. Shell 실행 방식

Linux에서는 `/bin/sh`, `bash`, symlink 기반 실행이 자연스럽습니다. Windows에서는 PowerShell/cmd와 Bash 문법이 다릅니다.

원본 하네스는 Windows에서 `git_bash` MCP를 제공하고, shell 명령은 Git Bash를 우선 사용하도록 hook context를 주입합니다. 그래서 Git for Windows의 `bash.exe`가 중요합니다.

### 4. Symlink

Linux에서는 CLI 링크를 symlink로 만듭니다. Windows에서는 권한과 정책 때문에 symlink가 불안정할 수 있습니다.

원본 installer는 Windows에서 `.cmd` shim을 생성하도록 되어 있어 이 부분은 이미 대응되어 있습니다.

### 5. VS Code 터미널 환경

Windows 환경 변수 변경은 이미 열려 있는 VS Code 터미널에 바로 반영되지 않습니다. 설치 후 새 터미널을 열거나 VS Code를 재시작해야 합니다.

### 6. Build/test 도구

원본 저장소의 전체 테스트와 빌드는 Bun에 강하게 의존합니다. Windows에서 소스 자체를 빌드하려면 Bun 설치와 Git Bash 환경이 필요할 수 있습니다.

일반 사용자는 원본을 직접 빌드하지 말고 `npx lazycodex-ai install` 설치 흐름을 사용하는 것이 안정적입니다.

## Windows 설치 검증 항목

`scripts/verify-windows.ps1`은 다음을 확인합니다.

- `node`, `npm`, `npx`, `codex` 명령 존재
- `%USERPROFILE%\.codex\config.toml` 존재
- `[marketplaces.sisyphuslabs]` 설정 존재
- `[plugins."omo@sisyphuslabs"]` 설정 존재
- `features.plugins = true`
- `features.plugin_hooks = true`
- OMO plugin cache 존재
- Git Bash 존재
- `omo*.cmd` command shim 존재

## Windows에서 실행할 명령

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\install-windows.ps1 -AddToUserPath
.\scripts\verify-windows.ps1
```

권한을 보수적으로 유지하려면:

```powershell
.\scripts\install-windows.ps1 -NoAutonomous -AddToUserPath
```

Git Bash 자동 설치를 원하지 않으면:

```powershell
.\scripts\install-windows.ps1 -SkipGitBashInstall -AddToUserPath
```

Git Bash 경로를 직접 지정하려면:

```powershell
.\scripts\install-windows.ps1 -GitBashPath "C:\Program Files\Git\bin\bash.exe" -AddToUserPath
```

## 실패 시 우선 확인

```powershell
codex --version
node --version
npm --version
where bash
Get-Content $HOME\.codex\config.toml
```

`where bash`가 Git for Windows의 `bash.exe`를 찾지 못하면 Git for Windows를 설치하거나 `OMO_CODEX_GIT_BASH_PATH`를 지정하세요.

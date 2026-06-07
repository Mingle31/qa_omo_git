# QA OMO Windows Harness

Windows VS Code에서 OpenAI Codex CLI에 OMO/LazyCodex 하네스를 적용하기 위한 설치/검증 저장소입니다.

이 저장소의 목적은 Ubuntu에서 분석한 하네스를 Windows 로컬 VS Code 환경에 재현 가능하게 설치하는 것입니다. 실제 하네스는 `npx lazycodex-ai install`로 설치되고, 이 저장소는 Windows에서 필요한 사전 점검과 검증을 자동화합니다.

## 사용 순서

Windows VS Code의 PowerShell 터미널에서 실행하세요. WSL 터미널이 아니라 Windows 네이티브 PowerShell이어야 합니다.

```powershell
git clone https://github.com/Mingle31/qa_omo_git.git
cd qa_omo_git
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\install-windows.ps1 -AddToUserPath
.\scripts\verify-windows.ps1
```

설치 후 VS Code 터미널을 새로 열어 주세요. `-AddToUserPath`를 사용하면 OMO 명령 shim 경로가 사용자 PATH에 추가됩니다.

## 설치되는 것

- Codex 플러그인 캐시: `%USERPROFILE%\.codex\plugins\cache\sisyphuslabs\omo\`
- Codex 설정 수정: `%USERPROFILE%\.codex\config.toml`
- Windows 명령 shim: 기본값 `%USERPROFILE%\.local\bin\*.cmd`
- Git Bash 경로 환경 변수: `OMO_CODEX_GIT_BASH_PATH`
- Codex 로컬 bin 환경 변수: `CODEX_LOCAL_BIN_DIR`

기본 설치는 autonomous 모드입니다.

```toml
approval_policy = "never"
sandbox_mode = "danger-full-access"
network_access = "enabled"
```

보수적인 권한으로 설치하려면 다음처럼 실행하세요.

```powershell
.\scripts\install-windows.ps1 -NoAutonomous
```

## 필수 조건

- Windows 네이티브 VS Code
- Node.js LTS
- npm/npx
- OpenAI Codex CLI
- Git for Windows, Git Bash 포함

Git Bash가 없으면 설치 스크립트가 `winget install --id Git.Git -e --source winget`을 시도합니다. Git을 다른 경로에 설치했다면 먼저 설정하세요.

```powershell
setx OMO_CODEX_GIT_BASH_PATH "C:\your\path\to\bash.exe"
```

## WSL 주의

Ubuntu/WSL의 Codex 설정과 Windows의 Codex 설정은 서로 다릅니다.

- Ubuntu/WSL: `/home/<user>/.codex`
- Windows: `C:\Users\<user>\.codex`

Windows VS Code에서 Codex를 쓰려면 이 저장소의 PowerShell 스크립트를 Windows PowerShell에서 실행해야 합니다. WSL에서 설치하면 Windows VS Code의 Codex에는 적용되지 않습니다.

## 제거

```powershell
.\scripts\uninstall-windows.ps1
```

## 상세 문서

Windows와 Linux가 맞지 않는 부분, 현재 하네스의 Windows 지원 상태, 실패 시 점검 방법은 [docs/windows-vscode.md](docs/windows-vscode.md)를 참고하세요.

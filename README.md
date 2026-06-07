# QA OMO Windows Harness

Windows VS Code에서 OpenAI Codex CLI에 OMO/LazyCodex 하네스를 적용하기 위한 설치/검증 저장소입니다.

## 빠른 시작

Windows VS Code의 PowerShell 터미널에서 실행하세요. WSL 터미널이 아니라 Windows 네이티브 PowerShell이어야 합니다.

```powershell
git clone https://github.com/Mingle31/qa_omo_git.git
cd qa_omo_git
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\install-windows.ps1 -AddToUserPath
.\scripts\verify-windows.ps1
```

설치 후 VS Code 터미널을 새로 열어 주세요.

## 무엇을 설치하나

- OMO/LazyCodex Codex Light plugin
- `%USERPROFILE%\.codex\config.toml` 플러그인 설정
- `%USERPROFILE%\.codex\plugins\cache\sisyphuslabs\omo\` 플러그인 캐시
- `%USERPROFILE%\.local\bin\*.cmd` Windows command shim
- Git Bash 기반 Windows shell 보조 설정

기본 설치는 autonomous 모드입니다.

```toml
approval_policy = "never"
sandbox_mode = "danger-full-access"
network_access = "enabled"
```

보수적인 권한으로 설치하려면:

```powershell
.\scripts\install-windows.ps1 -NoAutonomous
```

## 자세한 문서

- [README.ko.md](README.ko.md)
- [docs/windows-vscode.md](docs/windows-vscode.md)

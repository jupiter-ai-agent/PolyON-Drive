# PolyON Drive

**Customized Nextcloud 33 for PolyON Platform**

AD DC 네이티브 LDAP 인증 + RustFS(S3) 오브젝트 스토리지 통합.

## 아키텍처

```
┌─────────────┐     LDAP(389)     ┌──────────────┐
│  Nextcloud   │ ◄──────────────► │  Samba AD DC  │
│  (Drive)     │                  │  (polyon-dc)  │
│              │     S3(9000)     ├──────────────┤
│              │ ◄──────────────► │   RustFS      │
│              │                  │ (polyon-rustfs)│
│              │     PG(5432)     ├──────────────┤
│              │ ◄──────────────► │  PostgreSQL   │
│              │                  │  (polyon-db)  │
└─────────────┘                  └──────────────┘
```

## PolyON 커스텀 사항

### 1. AD DC 네이티브 LDAP 인증 (Pattern A)
- Keycloak 경유 없이 AD DC에 직접 LDAP bind
- Stalwart Mail과 동일한 인증 패턴
- `user_ldap` 앱 자동 설정 (entrypoint)
- 사용자 필터: Active Directory 사용자만 (컴퓨터/비활성 계정 제외)
- 로그인: `sAMAccountName`, `mail`, `userPrincipalName` 모두 지원
- 속성 매핑: `displayName`, `mail`, `sAMAccountName`

### 2. Keycloak SSO (선택적)
- `user_oidc` 앱 활성화 (LDAP과 공존)
- Keycloak `polyon` realm, 클라이언트 `nextcloud`
- LDAP으로 사용자 프로비저닝 + OIDC로 SSO 로그인

### 3. RustFS S3 오브젝트 스토리지 (제7원칙)
- 모든 파일 데이터는 RustFS(S3)에 저장
- PVC는 앱 코드/config 전용 (5Gi)
- 환경변수 `OBJECTSTORE_S3_*`로 자동 구성
- 버킷: `nextcloud` (설치 시 자동 생성)

### 4. 리버스 프록시 설정
- `overwritehost`, `overwriteprotocol` 자동 설정
- `trusted_proxies`: K8s 내부 네트워크 대역
- `trusted_domains`: 와일드카드 (`*`)

### 5. TLS 자체서명 인증서 신뢰
- Traefik TLS 인증서를 시스템 CA에 자동 등록
- Keycloak OIDC discovery 등 HTTPS 내부 통신 지원

## 환경변수

| 변수 | 설명 | 예시 |
|------|------|------|
| `POSTGRES_HOST` | PostgreSQL 호스트 | `polyon-db` |
| `POSTGRES_DB` | 데이터베이스명 | `nextcloud` |
| `POSTGRES_USER` | DB 사용자 | `nextcloud` |
| `POSTGRES_PASSWORD` | DB 비밀번호 | (Secret) |
| `NEXTCLOUD_ADMIN_USER` | 관리자 ID | `admin` |
| `NEXTCLOUD_ADMIN_PASSWORD` | 관리자 비밀번호 | (Secret) |
| `NEXTCLOUD_TRUSTED_DOMAINS` | 허용 도메인 | `*` |
| `OBJECTSTORE_S3_HOST` | RustFS 호스트 | `polyon-rustfs` |
| `OBJECTSTORE_S3_PORT` | RustFS 포트 | `9000` |
| `OBJECTSTORE_S3_BUCKET` | S3 버킷명 | `nextcloud` |
| `OBJECTSTORE_S3_KEY` | S3 Access Key | (Secret) |
| `OBJECTSTORE_S3_SECRET` | S3 Secret Key | (Secret) |
| `OBJECTSTORE_S3_SSL` | S3 SSL 사용 | `false` |
| `OBJECTSTORE_S3_USEPATH_STYLE` | Path-style URL | `true` |
| `OBJECTSTORE_S3_AUTOCREATE` | 버킷 자동 생성 | `true` |
| `LDAP_HOST` | AD DC 호스트 | `polyon-dc` |
| `LDAP_PORT` | AD DC 포트 | `389` |
| `LDAP_BASE_DN` | LDAP Base DN | `DC=cmars,DC=com` |
| `LDAP_ADMIN_DN` | LDAP Admin DN | `CN=Administrator,CN=Users,DC=cmars,DC=com` |
| `LDAP_ADMIN_PASSWORD` | LDAP Admin 비밀번호 | (Secret) |
| `DRIVE_DOMAIN` | 서비스 도메인 | `drive.cmars.com` |
| `OIDC_ENABLED` | OIDC SSO 활성화 | `true` / `false` |
| `OIDC_DISCOVERY_URI` | OIDC Discovery URL | `https://auth.cmars.com/realms/polyon/.well-known/openid-configuration` |
| `OIDC_CLIENT_ID` | OIDC 클라이언트 ID | `nextcloud` |
| `OIDC_CLIENT_SECRET` | OIDC 클라이언트 시크릿 | (Secret) |
| `TLS_CERT_SECRET` | K8s TLS Secret 이름 | `polyon-tls` |

## 빌드

```bash
# arm64 + amd64 멀티플랫폼
docker buildx build --platform linux/amd64,linux/arm64 \
  -t jupitertriangles/polyon-drive:v1.0.0 \
  --push .
```

## 파일 구조

```
polyon-drive/
├── Dockerfile              # Nextcloud 33-apache 기반 커스텀 이미지
├── entrypoint.sh           # LDAP/OIDC/S3/프록시 자동 설정
├── config/
│   └── autoconfig.php      # Nextcloud 자동 설정
├── scripts/
│   ├── configure-ldap.sh   # LDAP 설정 스크립트
│   ├── configure-oidc.sh   # OIDC 설정 스크립트 (선택)
│   └── configure-s3.sh     # RustFS S3 설정 스크립트
└── README.md
```

## 관련 리소스

- **PolyON Core:** `gitlab.triangles.co.kr/cmars/polyon.git`
- **PolyON Chat:** `gitlab.triangles.co.kr/cmars/polyon-chat.git`
- **Nextcloud 공식:** `github.com/nextcloud/server`
- **Docker Hub:** `jupitertriangles/polyon-drive`

## 라이선스

Nextcloud: AGPL-3.0 | PolyON 커스텀: Proprietary (Triangle.s)

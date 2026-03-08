#!/bin/bash
# ── PolyON Drive: Keycloak OIDC SSO 설정 (선택적) ──
# LDAP과 공존: LDAP = 사용자 프로비저닝, OIDC = SSO 로그인
# OIDC_ENABLED=true 일 때만 실행

set -e

OCC="su -s /bin/bash www-data -c"

echo "[polyon-drive:oidc] Configuring Keycloak OIDC SSO..."

# user_oidc 앱 설치 및 활성화
$OCC "php occ app:install user_oidc" 2>/dev/null || true
$OCC "php occ app:enable user_oidc" 2>/dev/null || true

# 다중 백엔드 허용 (LDAP + OIDC 공존)
$OCC "php occ config:app:set user_oidc allow_multiple_user_backends --value=1"

# OIDC Provider 등록
$OCC "php occ user_oidc:provider 'PolyON SSO' \
    --clientid='${OIDC_CLIENT_ID}' \
    --clientsecret='${OIDC_CLIENT_SECRET}' \
    --discoveryuri='${OIDC_DISCOVERY_URI}' \
    --mapping-uid='preferred_username' \
    --mapping-display-name='name' \
    --mapping-email='email' \
    --unique-uid=0 \
    --check-bearer=1 \
    --send-id-token-hint=1"

echo "[polyon-drive:oidc] ✅ OIDC SSO configured (provider: PolyON SSO)"

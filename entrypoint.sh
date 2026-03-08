#!/bin/bash
set -e

# ── PolyON Drive Entrypoint ──
# Nextcloud 공식 entrypoint 실행 후 커스텀 설정 적용

echo "[polyon-drive] Starting PolyON Drive..."

# 1. TLS 자체서명 인증서 신뢰 (K8s Secret → 시스템 CA)
if [ -f /polyon-tls/tls.crt ]; then
    cp /polyon-tls/tls.crt /usr/local/share/ca-certificates/polyon-tls.crt
    update-ca-certificates --fresh > /dev/null 2>&1
    echo "[polyon-drive] TLS certificate trusted"
fi

# 2. Nextcloud 공식 entrypoint 실행 (DB 초기화, 앱 설치 등)
/entrypoint.sh "$@" &
NC_PID=$!

# 3. Nextcloud 준비 대기
echo "[polyon-drive] Waiting for Nextcloud to be ready..."
MAX_WAIT=120
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    if su -s /bin/bash www-data -c "php occ status" 2>/dev/null | grep -q "installed: true"; then
        echo "[polyon-drive] Nextcloud is ready (${ELAPSED}s)"
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo "[polyon-drive] WARNING: Nextcloud not ready after ${MAX_WAIT}s, proceeding anyway"
fi

# 4. 리버스 프록시 설정
if [ -n "$DRIVE_DOMAIN" ]; then
    su -s /bin/bash www-data -c "php occ config:system:set overwritehost --value='${DRIVE_DOMAIN}'"
    su -s /bin/bash www-data -c "php occ config:system:set overwriteprotocol --value='https'"
    su -s /bin/bash www-data -c "php occ config:system:set overwrite.cli.url --value='https://${DRIVE_DOMAIN}'"
    su -s /bin/bash www-data -c "php occ config:system:set trusted_proxies 0 --value='10.0.0.0/8'"
    su -s /bin/bash www-data -c "php occ config:system:set trusted_proxies 1 --value='172.16.0.0/12'"
    echo "[polyon-drive] Reverse proxy configured for ${DRIVE_DOMAIN}"
fi

# 5. LDAP 설정 (AD DC 직접 연결)
if [ -n "$LDAP_HOST" ]; then
    /polyon-scripts/configure-ldap.sh
fi

# 6. OIDC SSO 설정 (선택적)
if [ "${OIDC_ENABLED}" = "true" ] && [ -n "$OIDC_DISCOVERY_URI" ]; then
    /polyon-scripts/configure-oidc.sh
fi

echo "[polyon-drive] PolyON Drive setup complete"

# Nextcloud 프로세스 대기
wait $NC_PID

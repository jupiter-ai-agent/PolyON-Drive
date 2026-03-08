#!/bin/bash
# ── PolyON Drive: RustFS S3 오브젝트 스토리지 설정 ──
# 제7원칙: 모든 모듈의 파일/오브젝트는 RustFS(S3) 사용
# Nextcloud의 OBJECTSTORE_S3_* 환경변수로 자동 구성됨 (이 스크립트는 검증용)

set -e

echo "[polyon-drive:s3] Verifying RustFS S3 configuration..."

OCC="su -s /bin/bash www-data -c"

# objectstore 설정 확인
S3_HOST=$($OCC "php occ config:system:get objectstore arguments hostname" 2>/dev/null || echo "")

if [ -n "$S3_HOST" ]; then
    echo "[polyon-drive:s3] ✅ S3 objectstore configured:"
    echo "  Host: $S3_HOST"
    echo "  Port: $($OCC "php occ config:system:get objectstore arguments port" 2>/dev/null)"
    echo "  Bucket: $($OCC "php occ config:system:get objectstore arguments bucket" 2>/dev/null)"
    echo "  SSL: $($OCC "php occ config:system:get objectstore arguments use_ssl" 2>/dev/null)"
else
    echo "[polyon-drive:s3] ⚠️ S3 objectstore not detected"
    echo "[polyon-drive:s3] Nextcloud will use OBJECTSTORE_S3_* env vars on first install"
fi

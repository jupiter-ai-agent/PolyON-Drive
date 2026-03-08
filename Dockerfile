FROM nextcloud:30-apache

LABEL maintainer="Triangle.s <cmars@triangles.co.kr>"
LABEL description="PolyON Drive — Nextcloud 30 with AD DC LDAP + RustFS S3"

# 필수 패키지 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    ldap-utils \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 커스텀 스크립트 복사
COPY scripts/ /polyon-scripts/
COPY entrypoint.sh /polyon-entrypoint.sh
RUN chmod +x /polyon-entrypoint.sh /polyon-scripts/*.sh

# Nextcloud 자동 설정
COPY config/autoconfig.php /usr/src/nextcloud/config/autoconfig.php

ENTRYPOINT ["/polyon-entrypoint.sh"]
CMD ["apache2-foreground"]

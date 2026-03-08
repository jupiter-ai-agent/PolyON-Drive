#!/bin/bash
# ── PolyON Drive: AD DC LDAP 설정 ──
# Pattern A: Keycloak 경유 없이 AD DC 직접 LDAP bind
# Stalwart Mail과 동일한 인증 패턴

set -e

OCC="su -s /bin/bash www-data -c"

echo "[polyon-drive:ldap] Configuring AD DC LDAP..."

# user_ldap 앱 활성화
$OCC "php occ app:enable user_ldap" 2>/dev/null || true

# 기존 LDAP 설정 확인
EXISTING=$($OCC "php occ ldap:show-config s01" 2>/dev/null || echo "")
if [ -z "$EXISTING" ]; then
    $OCC "php occ ldap:create-empty-config"
    echo "[polyon-drive:ldap] Created new LDAP config s01"
fi

# ── 연결 설정 ──
LDAP_HOST="${LDAP_HOST:-polyon-dc}"
LDAP_PORT="${LDAP_PORT:-389}"
LDAP_BASE_DN="${LDAP_BASE_DN:-DC=cmars,DC=com}"
LDAP_ADMIN_DN="${LDAP_ADMIN_DN:-CN=Administrator,CN=Users,DC=cmars,DC=com}"

$OCC "php occ ldap:set-config s01 ldapHost '${LDAP_HOST}'"
$OCC "php occ ldap:set-config s01 ldapPort '${LDAP_PORT}'"
$OCC "php occ ldap:set-config s01 ldapBase '${LDAP_BASE_DN}'"
$OCC "php occ ldap:set-config s01 ldapAgentName '${LDAP_ADMIN_DN}'"
$OCC "php occ ldap:set-config s01 ldapAgentPassword '${LDAP_ADMIN_PASSWORD}'"
$OCC "php occ ldap:set-config s01 ldapTLS '0'"

# ── 사용자 필터 ──
# Active Directory 사용자만 (컴퓨터 계정 제외, 비활성화된 계정 제외)
USER_FILTER='(&(objectClass=user)(!(objectClass=computer))(!(userAccountControl:1.2.840.113556.1.4.803:=2)))'
$OCC "php occ ldap:set-config s01 ldapUserFilter '${USER_FILTER}'"
$OCC "php occ ldap:set-config s01 ldapUserFilterObjectclass 'user'"

# ── 로그인 필터 ──
# sAMAccountName, mail, userPrincipalName 모두 지원
LOGIN_FILTER='(&(objectClass=user)(|(sAMAccountName=%uid)(mail=%uid)(userPrincipalName=%uid)))'
$OCC "php occ ldap:set-config s01 ldapLoginFilter '${LOGIN_FILTER}'"
$OCC "php occ ldap:set-config s01 ldapLoginFilterUsername '1'"
$OCC "php occ ldap:set-config s01 ldapLoginFilterEmail '1'"

# ── 속성 매핑 ──
$OCC "php occ ldap:set-config s01 ldapUserDisplayName 'displayName'"
$OCC "php occ ldap:set-config s01 ldapEmailAttribute 'mail'"
$OCC "php occ ldap:set-config s01 ldapExpertUsernameAttr 'sAMAccountName'"

# ── 그룹 필터 ──
$OCC "php occ ldap:set-config s01 ldapGroupFilter '(&(objectClass=group))'"
$OCC "php occ ldap:set-config s01 ldapGroupFilterObjectclass 'group'"
$OCC "php occ ldap:set-config s01 ldapGroupDisplayName 'cn'"
$OCC "php occ ldap:set-config s01 ldapGroupMemberAssocAttr 'member'"

# ── 기타 설정 ──
$OCC "php occ ldap:set-config s01 turnOnPasswordChange '0'"
$OCC "php occ ldap:set-config s01 ldapConfigurationActive '1'"
$OCC "php occ ldap:set-config s01 ldapExperiencedAdmin '1'"

# ── 연결 테스트 ──
RESULT=$($OCC "php occ ldap:test-config s01" 2>&1)
if echo "$RESULT" | grep -q "could be established"; then
    echo "[polyon-drive:ldap] ✅ LDAP connection successful"
else
    echo "[polyon-drive:ldap] ❌ LDAP connection failed: $RESULT"
    exit 1
fi

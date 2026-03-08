<?php
/**
 * PolyON Drive — Nextcloud Auto Configuration
 * 
 * 이 파일은 Nextcloud 첫 설치 시 자동으로 적용됩니다.
 * 환경변수에서 DB/S3 설정을 가져옵니다.
 */
$AUTOCONFIG = array(
    'dbtype'        => 'pgsql',
    'dbname'        => getenv('POSTGRES_DB') ?: 'nextcloud',
    'dbuser'        => getenv('POSTGRES_USER') ?: 'nextcloud',
    'dbpass'        => getenv('POSTGRES_PASSWORD') ?: '',
    'dbhost'        => getenv('POSTGRES_HOST') ?: 'polyon-db',
    'dbtableprefix' => 'oc_',
    'adminlogin'    => getenv('NEXTCLOUD_ADMIN_USER') ?: 'admin',
    'adminpass'     => getenv('NEXTCLOUD_ADMIN_PASSWORD') ?: '',
    'directory'     => '/var/www/html/data',
);

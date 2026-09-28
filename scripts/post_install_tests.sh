#!/usr/bin/env bash
#
# Petits tests de non-régression après déploiement.
# Rien de sophistiqué : juste de quoi vérifier rapidement que
# les trois services répondent avant de considérer le déploiement réussi.
#
# Usage : ./post_install_tests.sh

set -euo pipefail

APP_DOMAIN="${APP_DOMAIN:-lab-app.local}"
FAILED=0

check() {
    local description="$1"
    local command="$2"

    echo -n "→ ${description}... "
    if eval "${command}" > /dev/null 2>&1; then
        echo "OK"
    else
        echo "ÉCHEC"
        FAILED=1
    fi
}

echo "=== Tests post-déploiement — ${APP_DOMAIN} ==="

check "PostgreSQL écoute sur le port 5432" \
    "sudo -u postgres pg_isready -h 127.0.0.1 -p 5432"

check "Nginx est actif" \
    "systemctl is-active --quiet nginx"

check "Redirection HTTP -> HTTPS" \
    "curl -s -o /dev/null -w '%{http_code}' http://${APP_DOMAIN} | grep -q 301"

check "Le certificat TLS est présent et lisible" \
    "sudo test -r /etc/ssl/certs/${APP_DOMAIN}.crt"

check "Le certificat n'expire pas dans moins de 30 jours" \
    "openssl x509 -checkend 2592000 -noout -in /etc/ssl/certs/${APP_DOMAIN}.crt"

echo "================================================"
if [ "${FAILED}" -eq 0 ]; then
    echo "Tous les tests sont passés."
else
    echo "Au moins un test a échoué, voir le détail ci-dessus."
    exit 1
fi

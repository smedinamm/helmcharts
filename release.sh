#!/usr/bin/env bash
set -euo pipefail

# --- Configuración ---
BRANCH="main"         # ajusta si usas master u otra rama
CHART="base-chart"    # nombre del directorio del chart
CHANGELOG="CHANGELOG.md"

# --- Funciones ---
function usage() {
  echo "Uso: $0 <patch|minor|major> \"mensaje de cambios\""
  echo "Ejemplo: $0 patch \"fix: corregido service.yaml\""
  exit 1
}

# --- Validaciones ---
if [ $# -lt 2 ]; then
  usage
fi

BUMP_TYPE=$1
shift
MESSAGE="$*"

# --- Obtener versión actual desde Chart.yaml ---
CURRENT_VERSION=$(grep '^version:' ${CHART}/Chart.yaml | awk '{print $2}')
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

case $BUMP_TYPE in
  patch)
    PATCH=$((PATCH + 1))
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  *)
    usage
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
TAG="${CHART}-${NEW_VERSION}"
DATE=$(date +"%Y-%m-%d")

echo "🚀 Preparando release ${CHART} v${NEW_VERSION} (${DATE})"
echo "📌 Cambios: ${MESSAGE}"

# --- Asegurar que estamos en la rama correcta ---
git checkout ${BRANCH}

# --- Actualizar repo ---
echo "📥 Actualizando repo..."
git pull origin ${BRANCH} --rebase

# --- Actualizar versión en Chart.yaml ---
echo "📝 Actualizando Chart.yaml (de ${CURRENT_VERSION} a ${NEW_VERSION})..."
sed -i.bak "s/^version:.*/version: ${NEW_VERSION}/" ${CHART}/Chart.yaml
rm -f ${CHART}/Chart.yaml.bak

# --- Actualizar CHANGELOG.md ---
echo "📝 Actualizando CHANGELOG.md..."
if [ ! -f "$CHANGELOG" ]; then
  echo -e "# Changelog \n\nTodas las versiones notables de este proyecto se documentarán en este archivo.\n\nEl formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),y este proyecto sigue el [Versionamiento Semántico](https://semver.org/lang/es/).\n" > $CHANGELOG
  echo "" >> $CHANGELOG
fi

TMP_FILE=$(mktemp)
{
  cat $CHANGELOG
  echo "## [${NEW_VERSION}] - ${DATE}"
  echo -e "\n### ${MESSAGE}" | cut -d':' -f1
  echo "\n- $(echo -e "$MESSAGE" | cut -d':' -f2- | xargs)" 
  echo ""
} > $TMP_FILE
mv $TMP_FILE $CHANGELOG

# --- Commit de cambios ---
git add ${CHART}/Chart.yaml ${CHANGELOG}
git commit -m "chore: release ${CHART} v${NEW_VERSION}" || echo "⚠️ No había cambios para commitear"

# --- Push cambios ---
echo "⬆️ Subiendo cambios a GitHub..."
git push origin ${BRANCH}

# --- Crear tag ---
echo "🏷️ Creando tag ${TAG}..."
git tag ${TAG}
git push origin ${TAG}

echo "✅ Release ${TAG} creado y subido con éxito."
echo "📦 GitHub Actions ahora empaquetará y publicará el chart."

#!/bin/bash
set -e

LANGUAGE="${LANGUAGE,,}"  # Lowercase
BUILD_CMD="${BUILD_COMMAND}"
SONAR_TOKEN="${SONAR_TOKEN}"
PROJECT_KEY="${PROJECT_KEY}"
HOST_URL="${HOST_URL:-https://sonarcloud.io}"
ORGANIZATION="${ORGANIZATION}"

echo "Detected language: $LANGUAGE"
echo "Operating System: $(uname -s)"

PLATFORM="$(uname -s)"
IS_WINDOWS=false
IS_MAC=false
IS_LINUX=false

case "$PLATFORM" in
  Linux*)   IS_LINUX=true ;;
  Darwin*)  IS_MAC=true ;;
  MINGW*|MSYS*|CYGWIN*) IS_WINDOWS=true ;;
esac

# Set PATH for .NET tools if on Windows
if $IS_WINDOWS; then
  export PATH="$PATH:/c/Users/runneradmin/.dotnet/tools"
else
  export PATH="$PATH:/github/home/.dotnet/tools"
fi

if [[ "$LANGUAGE" == "dotnet" ]]; then
    echo "Running .NET scanner"
    dotnet tool install --global dotnet-sonarscanner
    dotnet-sonarscanner begin /k:"$PROJECT_KEY" /d:sonar.token="$SONAR_TOKEN" /d:sonar.host.url="$HOST_URL" ${ORGANIZATION:+/o:$ORGANIZATION}
    ${BUILD_CMD:-dotnet build}
    dotnet-sonarscanner end /d:sonar.token="$SONAR_TOKEN"

elif [[ "$LANGUAGE" == "java-maven" ]]; then
    echo "Running Java/Maven scanner"
    mvn verify sonar:sonar -Dsonar.projectKey="$PROJECT_KEY" -Dsonar.host.url="$HOST_URL" -Dsonar.token="$SONAR_TOKEN" ${ORGANIZATION:+-Dsonar.organization=$ORGANIZATION}

elif [[ "$LANGUAGE" == "java-gradle" ]]; then
    echo "Running Java/Gradle scanner"
    ./gradlew sonarqube -Dsonar.projectKey="$PROJECT_KEY" -Dsonar.host.url="$HOST_URL" -Dsonar.token="$SONAR_TOKEN" ${ORGANIZATION:+-Dsonar.organization=$ORGANIZATION}

else
    echo "Running generic scan using sonar-scanner CLI"
    npm install -g sonarqube-scanner
    sonar-scanner \
      -Dsonar.projectKey="$PROJECT_KEY" \
      -Dsonar.host.url="$HOST_URL" \
      -Dsonar.token="$SONAR_TOKEN" \
      ${ORGANIZATION:+-Dsonar.organization=$ORGANIZATION}
fi

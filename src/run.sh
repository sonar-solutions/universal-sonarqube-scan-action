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
echo "Working directory: $(pwd)"

PLATFORM="$(uname -s)"
IS_WINDOWS=false
IS_MAC=false
IS_LINUX=false

case "$PLATFORM" in
  Linux*)   IS_LINUX=true ;;
  Darwin*)  IS_MAC=true ;;
  MINGW*|MSYS*|CYGWIN*) IS_WINDOWS=true ;;
esac

# Configure .NET tools path based on the environment
if $IS_WINDOWS; then
  DOTNET_TOOLS_PATH="/c/Users/runneradmin/.dotnet/tools"
  export PATH="$PATH:$DOTNET_TOOLS_PATH"
elif $IS_MAC; then
  DOTNET_TOOLS_PATH="$HOME/.dotnet/tools"
  export PATH="$PATH:$DOTNET_TOOLS_PATH"
else # Linux
  DOTNET_TOOLS_PATH="/github/home/.dotnet/tools"
  export PATH="$PATH:$DOTNET_TOOLS_PATH"
fi

echo "Added to PATH: $DOTNET_TOOLS_PATH"
echo "Current PATH: $PATH"

# Verify dotnet is available
if ! command -v dotnet &> /dev/null; then
  echo "Error: dotnet command not found. Please make sure .NET SDK is installed."
  exit 1
fi

if [[ "$LANGUAGE" == "dotnet" ]]; then
    echo "Running .NET scanner"
    
    # Install the SonarScanner for .NET
    echo "Installing dotnet-sonarscanner..."
    dotnet tool install --global dotnet-sonarscanner || {
      echo "Failed to install dotnet-sonarscanner. Trying to update if already installed..."
      dotnet tool update --global dotnet-sonarscanner
    }
    
    # Verify installation
    if ! command -v dotnet-sonarscanner &> /dev/null && ! ls $DOTNET_TOOLS_PATH/dotnet-sonarscanner* &> /dev/null; then
      echo "Error: dotnet-sonarscanner not found after installation. Check .NET tools path."
      exit 1
    fi
    
    # Begin analysis
    echo "Beginning SonarQube analysis..."
    dotnet sonarscanner begin /k:"$PROJECT_KEY" /d:sonar.token="$SONAR_TOKEN" /d:sonar.host.url="$HOST_URL" ${ORGANIZATION:+/o:$ORGANIZATION} || {
      echo "Failed to begin SonarQube analysis. Trying alternative command format..."
      dotnet-sonarscanner begin /k:"$PROJECT_KEY" /d:sonar.token="$SONAR_TOKEN" /d:sonar.host.url="$HOST_URL" ${ORGANIZATION:+/o:$ORGANIZATION}
    }
    
    # Build the project
    echo "Building .NET project with command: ${BUILD_CMD:-dotnet build}"
    eval ${BUILD_CMD:-dotnet build} || {
      echo "Build failed. Please check your project structure and build command."
      exit 1
    }
    
    # End analysis
    echo "Ending SonarQube analysis..."
    dotnet sonarscanner end /d:sonar.token="$SONAR_TOKEN" || {
      echo "Failed to end SonarQube analysis. Trying alternative command format..."
      dotnet-sonarscanner end /d:sonar.token="$SONAR_TOKEN"
    }

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

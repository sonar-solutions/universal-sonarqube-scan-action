# Universal SonarQube Scanner

This GitHub Action provides a universal interface for scanning different types of projects with SonarQube or SonarCloud.

## Supported Languages

- ✅ Generic / C-family / JS / TS (uses SonarSource action internally)
- ✅ Java with Maven
- ✅ Java with Gradle
- ✅ .NET (C#)

## Usage

```yaml
jobs:
  sonar:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Run Universal Scanner
        uses: sonar-solutions/universal-sonarqube-scan-action@v1
        with:
          sonar_token: ${{ secrets.SONAR_TOKEN }}
          project_key: "your_project_key"
          organization: "your_org"  # Optional for SonarCloud
          host_url: "https://sonarcloud.io"
          language: "dotnet"  # or java-maven, java-gradle, generic
          build_command: "dotnet build"  # Optional
```

## Inputs

| Name           | Required | Description |
|----------------|----------|-------------|
| `sonar_token`  | ✅       | Token for authenticating to SonarCloud/SonarQube |
| `project_key`  | ✅       | Sonar project key |
| `organization` | ❌       | Only needed for SonarCloud |
| `host_url`     | ❌       | Defaults to `https://sonarcloud.io` |
| `language`     | ✅       | Language (`dotnet`, `java-maven`, `java-gradle`, or `generic`) |
| `build_command`| ❌       | Optional custom build command |

## License

MIT

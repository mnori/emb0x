FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /app

# Copy the shared library
COPY SharedLibrary ./SharedLibrary

# Copy the taskrunner-daemon project
COPY taskrunner-daemon ./TaskRunnerDaemon

# Restore and build
WORKDIR /app/TaskRunnerDaemon
RUN dotnet restore TaskRunnerDaemon.csproj
RUN dotnet publish TaskRunnerDaemon.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "TaskRunnerDaemon.dll"]

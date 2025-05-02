FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy the shared library
COPY SharedLibrary ./SharedLibrary

# Copy the import-manager project
COPY import-manager ./ImportManager

# Restore and build
WORKDIR /app/ImportManager
RUN dotnet restore ImportManager.csproj
RUN dotnet publish ImportManager.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "ImportManager.dll"]

# Stage 1: Build application.
#
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

COPY SharedLibrary ./SharedLibrary
COPY import-manager ./import-manager

# Restore dependencies
WORKDIR /app/import-manager
RUN dotnet restore ImportManager.csproj

# Build and publish the application
RUN dotnet publish ImportManager.csproj -c Release -o /app/publish

FROM build AS publish
RUN dotnet publish import-manager/ImportManager.csproj -c Release -o /app/publish

# Stage 2: Create runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

# Set the entry point for the container
ENTRYPOINT ["dotnet", "ImportManager.dll"]
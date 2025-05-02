# Stage 1: Build application.
#
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

COPY SharedLibrary ./SharedLibrary

COPY import-manager /app/import-manager
RUN dotnet restore import-manager/ImportManager.csproj
RUN dotnet build import-manager/ImportManager.csproj -c Release -o /app/build

FROM build AS publish
RUN dotnet publish import-manager/ImportManager.csproj -c Release -o /app/publish

# Stage 2: Create runtime image.
#
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app/webapp

# Set the connection string as an environment variable
ENV ConnectionStrings__Emb0xDatabaseContext=$DB_CONNECTION_STRING

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "import-manager.dll"]


# # Stage 1: Build the application
# FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
# WORKDIR /app

# # Copy the project files
# COPY import-manager/*.csproj ./
# COPY SharedLibrary/*.csproj ./
# RUN dotnet restore

# # Copy the rest of the application files and build
# COPY import-manager/. ./
# RUN dotnet publish -c Release -o /app/publish

# # Stage 2: Run the application
# FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
# WORKDIR /app
# COPY --from=build /app/publish .

# # Set the entry point for the container
# ENTRYPOINT ["dotnet", "import-manager.dll"]

# FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
# WORKDIR /app

# # Copy the shared library
# COPY SharedLibrary ./SharedLibrary

# # Copy the import-manager project
# COPY import-manager ./ImportManager

# # Restore and build
# WORKDIR /app/ImportManager
# RUN dotnet restore ImportManager.csproj
# RUN dotnet publish ImportManager.csproj -c Release -o /app/publish

# FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
# WORKDIR /app
# COPY --from=build /app/publish .
# ENTRYPOINT ["dotnet", "ImportManager.dll"]

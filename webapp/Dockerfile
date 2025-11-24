FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy project files first
COPY SharedLibrary/SharedLibrary.csproj SharedLibrary/
COPY webapp/webapp.csproj webapp/

RUN --mount=type=cache,target=/root/.nuget/packages \
    dotnet restore webapp/webapp.csproj --verbosity minimal

# Copy source
COPY SharedLibrary/ SharedLibrary/
COPY webapp/ webapp/

# Build (produces bin/Release)
RUN dotnet build webapp/webapp.csproj -c Release --no-restore

# Publish (use built output)
RUN dotnet publish webapp/webapp.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app/webapp
ENV ASPNETCORE_URLS=http://0.0.0.0:5000
EXPOSE 5000
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet","webapp.dll"]

##################################

# FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
# WORKDIR /app

# # Copy csproj files for restore caching
# COPY SharedLibrary/SharedLibrary.csproj SharedLibrary/
# COPY webapp/webapp.csproj webapp/

# # Restore dependencies
# RUN --mount=type=cache,target=/root/.nuget/packages \
#     dotnet restore webapp/webapp.csproj --verbosity minimal

# # Copy source
# COPY SharedLibrary/ SharedLibrary/
# COPY webapp/ webapp/

# # (Optional safety restore if project refs changed)
# RUN dotnet restore webapp/webapp.csproj --verbosity minimal

# # Build (produces bin/Release/net8.0 outputs)
# RUN dotnet build webapp/webapp.csproj -c Release --no-restore

# # Publish (uses build output; no rebuild)
# RUN dotnet publish webapp/webapp.csproj -c Release -o /app/publish --no-restore

# FROM mcr.microsoft.com/dotnet/aspnet:8.0
# WORKDIR /app/webapp
# ENV ASPNETCORE_URLS=http://0.0.0.0:5000
# EXPOSE 5000
# COPY --from=build /app/publish .
# ENTRYPOINT ["dotnet","webapp.dll"]

########################################################

# FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
# WORKDIR /app

# # Copy only project files first
# COPY webapp/webapp.csproj webapp/
# COPY SharedLibrary/SharedLibrary.csproj SharedLibrary/

# # Initial restore (cached)
# RUN --mount=type=cache,target=/root/.nuget/packages \
#     dotnet restore webapp/webapp.csproj --verbosity minimal

# # Copy the rest of source
# COPY SharedLibrary/ SharedLibrary/
# COPY webapp/ webapp/

# # Safety re-restore in case dependencies changed
# RUN dotnet restore webapp/webapp.csproj --verbosity minimal

# RUN dotnet build webapp/webapp.csproj -c Release -o /app/build --no-restore
# RUN dotnet publish webapp/webapp.csproj -c Release -o /app/publish --no-build

# FROM mcr.microsoft.com/dotnet/aspnet:8.0
# WORKDIR /app/webapp
# ENV ASPNETCORE_URLS=http://0.0.0.0:5000
# EXPOSE 5000
# COPY --from=build /app/publish .
# ENTRYPOINT ["dotnet","webapp.dll"]

#######################################################

# # Stage 1: build
# FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
# WORKDIR /app

# # Copy project files first for restore caching
# COPY webapp/webapp.csproj webapp/
# COPY SharedLibrary/SharedLibrary.csproj SharedLibrary/

# # Optional: enable BuildKit NuGet cache (set DOCKER_BUILDKIT=1 when building)
# RUN --mount=type=cache,target=/root/.nuget/packages \
#     dotnet restore webapp/webapp.csproj --verbosity minimal

# # Copy the remaining source
# COPY SharedLibrary/ SharedLibrary/
# COPY webapp/ webapp/

# # Build and publish
# RUN dotnet build webapp/webapp.csproj -c Release -o /app/build --no-restore
# RUN dotnet publish webapp/webapp.csproj -c Release -o /app/publish --no-build

# # Stage 2: runtime
# FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
# WORKDIR /app/webapp

# # Expose Kestrel on 0.0.0.0:5000; map host port (e.g. 80) via compose
# ENV ASPNETCORE_URLS=http://0.0.0.0:5000
# EXPOSE 5000

# # Copy published output
# COPY --from=build /app/publish .

# # No DB/password envs here; provided at runtime by docker compose
# ENTRYPOINT ["dotnet","webapp.dll"]

#######################################################

# # Stage 1: Build application.
# FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
# WORKDIR /app

# COPY SharedLibrary ./SharedLibrary

# COPY webapp /app/webapp
# RUN dotnet restore webapp/webapp.csproj
# RUN dotnet build webapp/webapp.csproj -c Release -o /app/build

# FROM build AS publish
# RUN dotnet publish webapp/webapp.csproj -c Release -o /app/publish

# # Stage 2: Create runtime image.
# FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
# WORKDIR /app/webapp

# # # Set the connection string as an environment variable
# # ENV ConnectionStrings__Emb0xDatabaseContext=$DB_CONNECTION_STRING
# ENV MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD

# COPY --from=publish /app/publish .
# ENTRYPOINT ["dotnet", "webapp.dll"]
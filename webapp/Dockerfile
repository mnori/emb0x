# Stage 1: Build application.
#
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

COPY SharedLibrary ./SharedLibrary

COPY webapp /app/webapp
RUN dotnet restore webapp/webapp.csproj
RUN dotnet build webapp/webapp.csproj -c Release -o /app/build

FROM build AS publish
RUN dotnet publish webapp/webapp.csproj -c Release -o /app/publish

# Stage 2: Create runtime image.
#
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app/webapp

# Set the connection string as an environment variable
ENV ConnectionStrings__Emb0xDatabaseContext=$DB_CONNECTION_STRING

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "webapp.dll"]
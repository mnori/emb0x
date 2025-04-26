# Stage 1: Build application.
#
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /app
COPY . /app
RUN dotnet restore webapp.csproj
RUN dotnet build webapp.csproj -c Release -o /app/build

FROM build AS publish
RUN dotnet publish webapp.csproj -c Release -o /app/publish

# Stage 2: Create runtime image.
#
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app/webapp

# Set the connection string as an environment variable
ENV ConnectionStrings__MvcMovieContext=$DB_CONNECTION_STRING

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "webapp.dll"]
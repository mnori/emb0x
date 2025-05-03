# Stage 1: Build application.
#
FROM mcr.microsoft.com/dotnet/sdk:latest AS build
WORKDIR /app
COPY . /app
RUN dotnet restore docker-mysql.csproj
RUN dotnet build docker-mysql.csproj -c Release -o /app/build

FROM build AS publish
RUN dotnet publish docker-mysql.csproj -c Release -o /app/publish

# Stage 2: Create runtime image.
FROM mcr.microsoft.com/dotnet/runtime:latest AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "docker-mysql.dll"]
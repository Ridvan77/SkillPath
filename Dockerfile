FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["SkillPath.WebAPI/SkillPath.WebAPI.csproj", "SkillPath.WebAPI/"]
COPY ["SkillPath.Services/SkillPath.Services.csproj", "SkillPath.Services/"]
COPY ["SkillPath.Model/SkillPath.Model.csproj", "SkillPath.Model/"]
RUN dotnet restore "SkillPath.WebAPI/SkillPath.WebAPI.csproj"

COPY SkillPath.WebAPI/ SkillPath.WebAPI/
COPY SkillPath.Services/ SkillPath.Services/
COPY SkillPath.Model/ SkillPath.Model/

WORKDIR "/src/SkillPath.WebAPI"
RUN dotnet build "SkillPath.WebAPI.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "SkillPath.WebAPI.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .
COPY --from=build /src/SkillPath.WebAPI/firebase-service-account.json ./firebase-service-account.json
COPY --from=build /src/SkillPath.WebAPI/wwwroot ./wwwroot
RUN mkdir -p /app/logs
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/swagger/index.html || exit 1
ENTRYPOINT ["dotnet", "SkillPath.WebAPI.dll"]

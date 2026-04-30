FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["SkillPath.Worker/SkillPath.Worker.csproj", "SkillPath.Worker/"]
COPY ["SkillPath.Services/SkillPath.Services.csproj", "SkillPath.Services/"]
COPY ["SkillPath.Model/SkillPath.Model.csproj", "SkillPath.Model/"]
RUN dotnet restore "SkillPath.Worker/SkillPath.Worker.csproj"

COPY SkillPath.Worker/ SkillPath.Worker/
COPY SkillPath.Services/ SkillPath.Services/
COPY SkillPath.Model/ SkillPath.Model/

RUN dotnet publish "SkillPath.Worker/SkillPath.Worker.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
RUN mkdir -p /app/logs
ENTRYPOINT ["dotnet", "SkillPath.Worker.dll"]

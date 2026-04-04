# ─── Build stage ───────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY *.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

# ─── Runtime stage ─────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# Kopiuj opublikowaną aplikację
COPY --from=build /app/publish .

# Model zostanie zamontowany przez Azure ML pod /mnt/models/model.onnx
# Nie kopiujemy go do obrazu — pobieramy przez zmienną środowiskową Onnx__ModelPath

# Upewnij się że port 8080 jest dostępny (wymagany przez Azure ML BYOC)
EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "OnnxInferenceApi.dll"]

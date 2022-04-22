start:
	@ConnectionString="Server=tcp:tour-of-heroes.database.windows.net,1433;Initial Catalog=heroes;Persist Security Info=False;User ID=gis;Password=Str0ngPassw0rd;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" func start --dotnet-isolated-debug --csharp
publish:
	@func azure functionapp publish tour-of-heroes-functions
using Dapr.Client;
using Microsoft.EntityFrameworkCore;
using tour_of_heroes_api.Models;

const string SECRET_STORE_NAME = "heroessecretstore";

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddDaprClient();

using var daprClient = new DaprClientBuilder().Build();

// builder.Services.AddDbContext<HeroContext>(
//     opt => opt.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"))
// );

await daprClient.WaitForSidecarAsync();
var connectionString = await daprClient.GetSecretAsync(SECRET_STORE_NAME, "ConnectionString");

builder.Services.AddDbContext<HeroContext>(opt => opt.UseSqlServer(connectionString.First().Value));

builder.Services.AddControllers();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();

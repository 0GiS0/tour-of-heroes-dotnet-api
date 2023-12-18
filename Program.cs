using Microsoft.EntityFrameworkCore;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using tour_of_heroes_api.Models;
using Microsoft.AspNetCore.HttpLogging;
using OpenTelemetry.Logs;
using OpenTelemetry.Instrumentation.AspNetCore;


var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddScoped<IHeroRepository, HeroRepository>();
builder.Services.AddControllers(); builder.Services.AddDbContext<HeroContext>(opt => opt.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "tour_of_heroes_api", Version = "v1" });
});


/************************************************************************************************
********************************** Open Telemetry configuration *********************************
*********** https://grafana.com/grafana/dashboards/17706-asp-net-otel-metrics/ ******************
************************************************************************************************/

builder.Logging.AddOpenTelemetry(options =>
{
    options.IncludeScopes = true;
    options.IncludeFormattedMessage = true;

    var resourceBuilder = ResourceBuilder.CreateDefault();
    resourceBuilder.AddService(builder.Configuration["OTEL_SERVICE_NAME"]);
    options.SetResourceBuilder(resourceBuilder);

    // options.AddConsoleExporter();
    options.AddOtlpExporter(); //This will, by default, send traces using gRPC to http://localhost:4317

});

builder.Services.AddHttpLogging(o => o.LoggingFields = HttpLoggingFields.All);

builder.Services.AddOpenTelemetry()
// .UseAzureMonitor() //https://learn.microsoft.com/es-es/azure/azure-monitor/app/opentelemetry-configuration?tabs=aspnetcore
.ConfigureResource(resource => resource.AddService(builder.Configuration["OTEL_SERVICE_NAME"]))
.WithTracing(tracing =>
{
    tracing.AddAspNetCoreInstrumentation();
    tracing.AddHttpClientInstrumentation();
    // tracing.AddSqlClientInstrumentation();
    tracing.AddEntityFrameworkCoreInstrumentation();
    
    tracing.AddOtlpExporter();

    // tracing.AddConsoleExporter();

})
.WithMetrics(metrics =>
{
    metrics.AddAspNetCoreInstrumentation();
    metrics.AddHttpClientInstrumentation();
    metrics.AddProcessInstrumentation();
    metrics.AddRuntimeInstrumentation();
    // metrics.AddConsoleExporter();
    
    // https://opentelemetry.io/docs/instrumentation/net/exporters/#prometheus-experimental
    metrics.AddPrometheusExporter();

    metrics.AddOtlpExporter();

});

builder.Services.Configure<AspNetCoreInstrumentationOptions>(options =>
{
    // Filter out instrumentation of the Prometheus scraping endpoint.
    options.Filter = ctx => ctx.Request.Path != "/metrics";
});


/************************************************************************************************/

// Add CORS policy
builder.Services.AddCors(options =>
{
    options.AddPolicy("CorsPolicy",
        builder => builder.AllowAnyOrigin()
        .AllowAnyMethod()
        .AllowAnyHeader());
});

var app = builder.Build();

app.UseCors("CorsPolicy");

app.UseOpenTelemetryPrometheusScrapingEndpoint();

app.UseSwagger();
app.UseSwaggerUI();

app.MapControllers();

// Configure the Prometheus scraping endpoint
app.MapPrometheusScrapingEndpoint();
app.UseHttpLogging();
app.UseDeveloperExceptionPage();

app.Run();


using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using tour_of_heroes_api.Models;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;

namespace tour_of_heroes_api
{
    public class GetHeroes
    {
        private readonly HeroContext _context;

        public GetHeroes(HeroContext context)
        {
            _context = context;
        }


        [Function("GetHeroes")]
        public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req, FunctionContext executionContext)
        {
            var logger = executionContext.GetLogger("GetHeroes");

            var heroes = _context.Heroes.ToList();

            logger.LogInformation($"Returning {heroes.Count.ToString()} heroes");

            var response = req.CreateResponse(HttpStatusCode.OK);

            await response.WriteAsJsonAsync(heroes);

            return response;
        }
    }
}
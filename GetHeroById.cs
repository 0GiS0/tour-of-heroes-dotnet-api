using System.Collections.Generic;
using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using tour_of_heroes_api.Models;
using System.Web;

namespace tour_of_heroes_api
{
    public class GetHeroById
    {
        private readonly HeroContext _context;

        public GetHeroById(HeroContext context)
        {
            _context = context;

        }

        [Function("GetHeroById")]
        public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequestData req, FunctionContext executionContext)
        {
            var logger = executionContext.GetLogger("GetHeroById");

            var id = int.Parse(HttpUtility.ParseQueryString(req.Url.Query).Get("id"));

            logger.LogInformation($"Get hero by id {id}");

            var hero = await _context.Heroes.FindAsync(id);

            var response = req.CreateResponse(HttpStatusCode.OK);

            await response.WriteAsJsonAsync(hero);

            return response;
        }
    }
}

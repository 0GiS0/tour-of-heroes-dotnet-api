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
    public class DeleteHero
    {
        private readonly HeroContext _context;

        public DeleteHero(HeroContext context)
        {
            _context = context;
        }

        [Function("DeleteHero")]
        public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Anonymous, "delete")] HttpRequestData req,
            FunctionContext executionContext)
        {
            var logger = executionContext.GetLogger("DeleteHero");
            var id = int.Parse(HttpUtility.ParseQueryString(req.Url.Query).Get("id"));

            logger.LogInformation($"Delete hero with id {id}");

            var hero = await _context.Heroes.FindAsync(id);

            if (hero == null)
            {
                return req.CreateResponse(HttpStatusCode.NotFound);
            }

            _context.Heroes.Remove(hero);
            await _context.SaveChangesAsync();

            return req.CreateResponse(HttpStatusCode.NoContent);
        }

    }
}
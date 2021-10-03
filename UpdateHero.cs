using System.Collections.Generic;
using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using tour_of_heroes_api.Models;
using System.Web;
using Microsoft.EntityFrameworkCore;


namespace tour_of_heroes_api
{
    public class UpdateHero
    {
        private readonly HeroContext _context;

        public UpdateHero(HeroContext context)
        {
            _context = context;
        }

        [Function("UpdateHero")]
        public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Anonymous, "put")] HttpRequestData req,
            FunctionContext executionContext)
        {
            var logger = executionContext.GetLogger("UpdateHero");

            var id = int.Parse(HttpUtility.ParseQueryString(req.Url.Query).Get("id"));
            var hero = req.ReadFromJsonAsync<Hero>().Result;

            if (id != hero.Id)
            {
                return req.CreateResponse(HttpStatusCode.BadRequest);
            }

            _context.Entry(hero).State = EntityState.Modified;

            _context.SaveChanges();

            var response = req.CreateResponse(HttpStatusCode.OK);

            await response.WriteAsJsonAsync(hero);

            return response;
        }
    }
}
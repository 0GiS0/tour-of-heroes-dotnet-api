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
    public class AddHero
    {
        private readonly HeroContext _context;

        public AddHero(HeroContext context)
        {
            _context = context;
        }


        [Function(nameof(AddHero))]
        public HttpResponseData Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequestData req, FunctionContext executionContext)
        {
            var logger = executionContext.GetLogger("AddHero");

            var heroes = _context.Heroes.ToList();

            var response = req.CreateResponse(HttpStatusCode.OK);

            return response;
        }
    }
}
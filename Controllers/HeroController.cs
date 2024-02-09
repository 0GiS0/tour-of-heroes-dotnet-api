using Microsoft.AspNetCore.Mvc;
using tour_of_heroes_api.Models;
using Azure.Storage.Blobs;


namespace tour_of_heroes_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HeroController(IHeroRepository heroRepository,IConfiguration configuration) : ControllerBase
    {
        private readonly IHeroRepository _heroRepository = heroRepository;
        private readonly IConfiguration _configuration = configuration;

        // GET: api/Hero
        [HttpGet]
        public ActionResult<IEnumerable<Hero>> GetHeroes()
        {
            var heroes = _heroRepository.GetAll();
            return Ok(heroes);
        }

        // GET: api/Hero/5
        [HttpGet("{id}")]
        public ActionResult<Hero> GetHero(int id)
        {
            var hero = _heroRepository.GetById(id);

            if (hero == null)
            {
                return NotFound();
            }

            return Ok(hero);
        }

        // PUT: api/Hero/5
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPut("{id}")]
        public ActionResult PutHero(int id, Hero hero)
        {

            var heroToUpdate = _heroRepository.GetById(id);

            if (heroToUpdate == null)
            {
                return NotFound();
            }

            heroToUpdate.Name = hero.Name;
            heroToUpdate.AlterEgo = hero.AlterEgo;
            heroToUpdate.Description = hero.Description;

            _heroRepository.Update(heroToUpdate);

            return NoContent();

        }

        // POST: api/Hero
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPost]
        public ActionResult<Hero> PostHero(Hero hero)
        {

            _heroRepository.Add(hero);

            return Ok(hero);

        }

        // DELETE: api/Hero/5
        [HttpDelete("{id}")]
        public IActionResult DeleteHero(int id)
        {
            _heroRepository.Delete(id);

            return NoContent();
        }

        // GET: api/hero/alteregopic/5
        [HttpGet("alteregopic/{id}")]
        public async Task<ActionResult<Hero>> GetAlterEgoPic(int id)
        {
            var hero = _heroRepository.GetById(id);

            if (hero == null)
            {
                return NotFound();
            }

            //Get image from Azure Storage
            string connectionString = _configuration.GetConnectionString("AzureStorage");
            
            // Create a BlobServiceClient object which will be used to create a container client
            var blobServiceClient = new BlobServiceClient(connectionString);

            //Get container client
            var containerClient = blobServiceClient.GetBlobContainerClient("alteregos");

            //Get blob client
            var blob = containerClient.GetBlobClient($"{hero.AlterEgo.ToLower().Replace(' ', '-')}.png");

            //Get image from blob
            var image = await blob.DownloadStreamingAsync();

            //return image
            return File(image.Value.Content, "image/png");
        }
    }
}
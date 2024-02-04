using Microsoft.AspNetCore.Mvc;

namespace tour_of_heroes_api.Controllers{
    
    [Route("api/[controller]")]
    [ApiController]
    public class HealthController : ControllerBase
    {
        // GET: api/Health
        [HttpGet]
        public IActionResult Get()
        {
            return Ok("Healthy");
        }
    }
}
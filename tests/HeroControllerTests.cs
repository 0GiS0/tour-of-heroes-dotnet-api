using Moq;
using tour_of_heroes_api.Controllers;
using tour_of_heroes_api.Models;
using Microsoft.AspNetCore.Mvc;

public class HeroControllerTests
{
    /// <summary>
    /// Mock repository for the IHeroRepository interface used for testing purposes.
    /// </summary>
    private readonly Mock<IHeroRepository> _mockHeroRepository;
    private readonly HeroController _controller;

    public HeroControllerTests()
    {
        _mockHeroRepository = new Mock<IHeroRepository>();
        _controller = new HeroController(_mockHeroRepository.Object);
    }

    [Fact]
    public void GetHeroes_ReturnsOkResult_WithListOfHeroes()
    {
        // Arrange
        var heroes = new List<Hero>
        {
            new Hero("Superman", "Clark Kent"),
            new Hero("Batman", "Bruce Wayne")
        };
        _mockHeroRepository.Setup(repo => repo.GetAll()).Returns(heroes);

        // Act
        var result = _controller.GetHeroes();

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var returnHeroes = Assert.IsType<List<Hero>>(okResult.Value);
        Assert.Equal(2, returnHeroes.Count);
    }

    [Fact]
    public void GetHero_ReturnsOkResult_WithHero()
    {
        // Arrange
        var hero = new Hero("Superman", "Clark Kent");
        _mockHeroRepository.Setup(repo => repo.GetById(1)).Returns(hero);

        // Act
        var result = _controller.GetHero(1);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var returnHero = Assert.IsType<Hero>(okResult.Value);
        Assert.Equal("Superman", returnHero.Name);
    }

    [Fact]
    public void GetHero_ReturnsNotFoundResult_WhenHeroNotFound()
    {
        // Arrange
        _mockHeroRepository.Setup(repo => repo.GetById(1)).Returns((Hero)null);

        // Act
        var result = _controller.GetHero(1);

        // Assert
        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public void PostHero_ReturnsOkResult_WithCreatedHero()
    {
        // Arrange
        var hero = new Hero("Superman", "Clark Kent");

        // Act
        var result = _controller.PostHero(hero);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var returnHero = Assert.IsType<Hero>(okResult.Value);
        Assert.Equal("Superman", returnHero.Name);
    }

    [Fact]
    public void PutHero_ReturnsNoContentResult_WhenHeroUpdated()
    {
        // Arrange
        var hero = new Hero("Superman", "Clark Kent");
        _mockHeroRepository.Setup(repo => repo.GetById(1)).Returns(hero);

        // Act
        var result = _controller.PutHero(1, new Hero("Batman", "Bruce Wayne"));

        // Assert
        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public void PutHero_ReturnsNotFoundResult_WhenHeroNotFound()
    {
        // Arrange
        _mockHeroRepository.Setup(repo => repo.GetById(1)).Returns((Hero)null);

        // Act
        var result = _controller.PutHero(1, new Hero("Batman", "Bruce Wayne"));

        // Assert
        Assert.IsType<NotFoundResult>(result);
    }   
}
